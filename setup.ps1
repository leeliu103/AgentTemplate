#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host $msg -ForegroundColor Red }

Write-Success "======================================"
Write-Success "Agent Template Setup Script"
Write-Success "======================================"
Write-Host ""

# Check if AMD_LLM_API_KEY is set
if (-not $env:AMD_LLM_API_KEY) {
    Write-Err "ERROR: AMD_LLM_API_KEY environment variable is not set!"
    Write-Host "Please set your AMD LLM Gateway API key first:"
    Write-Host '  $env:AMD_LLM_API_KEY = "<Your Key>"'
    exit 1
}

Write-Success "✓ AMD_LLM_API_KEY detected"
Write-Host ""

# Check if Node.js is installed, install via winget if missing
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Warn "Node.js is not installed. Installing via winget..."
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Err "ERROR: Neither Node.js nor winget found. Please install Node.js manually from https://nodejs.org/"
        exit 1
    }
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    # Refresh PATH so node is available in the current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Err "ERROR: Node.js installation completed but 'node' is still not found."
        Write-Host "Please close and reopen PowerShell, then run this script again."
        exit 1
    }
}
$nodeVersion = node -v
Write-Success "✓ Node.js $nodeVersion detected"
Write-Host ""

# Install claude-code
Write-Warn "Installing claude-code..."
npm install -g @anthropic-ai/claude-code
Write-Success "✓ claude-code installed"
Write-Host ""

# Install codex
Write-Warn "Installing @openai/codex..."
npm install -g @openai/codex
Write-Success "✓ @openai/codex installed"
Write-Host ""

# Copy codex.config to ~/.codex/config.toml
Write-Warn "Setting up codex configuration..."
$codexDir = Join-Path $env:USERPROFILE ".codex"
if (-not (Test-Path $codexDir)) {
    New-Item -ItemType Directory -Path $codexDir -Force | Out-Null
}
Copy-Item -Path (Join-Path $PSScriptRoot "codex.config") -Destination (Join-Path $codexDir "config.toml") -Force
Write-Success "✓ Copied codex.config to $codexDir\config.toml"
Write-Host ""

# Log in to codex with API key
Write-Warn "Logging in to codex..."
$env:AMD_LLM_API_KEY | codex login --with-api-key
Write-Success "✓ codex login complete"
Write-Host ""

# Copy CLAUDE.md to ~/.claude/
Write-Warn "Setting up Claude code configuration..."
$claudeDir = Join-Path $env:USERPROFILE ".claude"
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}
Copy-Item -Path (Join-Path $PSScriptRoot "CLAUDE.md") -Destination $claudeDir -Force
Write-Success "✓ Copied CLAUDE.md to $claudeDir"
Write-Host ""

# Set up environment variables (persistent User-level)
Write-Warn "Setting up environment variables..."

# Export CA certificates to a PEM bundle for Node.js (corporate proxy support)
$caBundlePath = Join-Path $env:USERPROFILE "ca-bundle.crt"
Write-Warn "Exporting CA certificates to $caBundlePath..."
$allCerts = @{}

# Collect from all relevant Windows certificate stores
foreach ($store in @("Cert:\LocalMachine\Root", "Cert:\LocalMachine\CA", "Cert:\CurrentUser\Root", "Cert:\CurrentUser\CA")) {
    foreach ($cert in (Get-ChildItem $store -ErrorAction SilentlyContinue)) {
        if (-not $allCerts.ContainsKey($cert.Thumbprint)) {
            $allCerts[$cert.Thumbprint] = $cert
        }
    }
}

# Also capture certificates from the live TLS handshake (e.g. Skyhigh proxy cert)
try {
    $script:chainCerts = @()
    $tcp = New-Object System.Net.Sockets.TcpClient("platform.claude.com", 443)
    $callback = {
        param($sender, $cert, $chain, $errors)
        foreach ($el in $chain.ChainElements) { $script:chainCerts += $el.Certificate }
        return $true
    }
    $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, $callback)
    $ssl.AuthenticateAsClient("platform.claude.com")
    $ssl.Close(); $tcp.Close()
    foreach ($c in $script:chainCerts) {
        if (-not $allCerts.ContainsKey($c.Thumbprint)) { $allCerts[$c.Thumbprint] = $c }
    }
} catch { }

$pem = [System.Text.StringBuilder]::new()
foreach ($cert in $allCerts.Values) {
    $base64 = [Convert]::ToBase64String($cert.RawData, 'InsertLineBreaks')
    [void]$pem.AppendLine("-----BEGIN CERTIFICATE-----")
    [void]$pem.AppendLine($base64)
    [void]$pem.AppendLine("-----END CERTIFICATE-----")
}
[System.IO.File]::WriteAllText($caBundlePath, $pem.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Success "✓ Exported $($allCerts.Count) CA certificates (stores + proxy chain)"

$envVars = @{
    AMD_LLM_API_KEY                    = $env:AMD_LLM_API_KEY
    ANTHROPIC_API_KEY                  = $env:AMD_LLM_API_KEY
    ANTHROPIC_CUSTOM_HEADERS           = "Ocp-Apim-Subscription-Key:$($env:AMD_LLM_API_KEY)"
    ANTHROPIC_BASE_URL                 = "https://llm-api.amd.com/Anthropic"
    ANTHROPIC_MODEL                    = "claude-opus-4.6"
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1"
    LLM_GATEWAY_KEY                    = $env:AMD_LLM_API_KEY
    NODE_EXTRA_CA_CERTS                = $caBundlePath
}

foreach ($kv in $envVars.GetEnumerator()) {
    [System.Environment]::SetEnvironmentVariable($kv.Key, $kv.Value, [System.EnvironmentVariableTarget]::User)
    Set-Item -Path "Env:\$($kv.Key)" -Value $kv.Value
}

Write-Success "✓ Environment variables set (User-level persistent + current session)"
Write-Host ""

# Check if Python is installed
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Err "ERROR: Python is not installed!"
    Write-Host "Please install Python 3 before continuing."
    Write-Host "  winget install Python.Python.3.12"
    exit 1
}

$pythonVersion = python --version
Write-Success "✓ $pythonVersion detected"
Write-Host ""

# Install Python SDKs
Write-Warn "Installing Python SDKs..."

$pipCmd = Get-Command pip -ErrorAction SilentlyContinue
if (-not $pipCmd) {
    Write-Err "ERROR: pip is not installed!"
    exit 1
}

pip install openai-agents
Write-Success "✓ openai-agents installed"

pip install claude-agent-sdk
Write-Success "✓ claude-agent-sdk installed"
Write-Host ""

# Success message
Write-Success "======================================"
Write-Success "✓ Setup Complete!"
Write-Success "======================================"
Write-Host ""

Write-Warn "Next Steps:"
Write-Host "1. Open a new PowerShell window to pick up the environment variables."
Write-Host ""
Write-Host "2. Set up the codex plugin inside Claude Code:"
Write-Host "   Launch 'claude', then run the following slash commands:"
Write-Success "   /plugin marketplace add openai/codex-plugin-cc"
Write-Success "   /plugin install codex@openai-codex"
Write-Success "   /reload-plugins"
Write-Success "   /codex:setup"
Write-Host ""
Write-Host "3. Test the SDKs by running the example agents."
Write-Host ""

Write-Warn "Usage Instructions:"
Write-Host ""
Write-Host "• Using Claude Code:"
Write-Host "  After running this setup, you can use 'claude' in ANY project folder."
Write-Host '  To enable the 3 common MCP servers (context7, codex, playwright):'
Write-Success '  Copy-Item .mcp.json C:\path\to\your\project\'
Write-Host ""
Write-Host "• Using Codex Agent:"
Write-Host "  You can use Codex in ANY folder with:"
Write-Success '  codex -c model_provider=''amd-openai'''
Write-Host ""
