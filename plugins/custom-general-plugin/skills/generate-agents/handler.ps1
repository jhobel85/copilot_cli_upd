param(
    [string]$targetPath = "$(Get-Location)",
    [string]$mode = "auto",
    [int]$fixedCount = 5,
    [string]$packageFolderName = ".agents-plugin"
)

# Generator: creates multiple Python agent folders under $targetPath\.agents
if (-not (Test-Path $targetPath)) { Write-Error "Target path does not exist: $targetPath"; exit 1 }
$agentsDir = Join-Path $targetPath '.agents'
New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null

# Determine count
if ($mode -eq 'fixed') { $count = $fixedCount } else { $count = 5 }

# Template for agent (Node.js)
$agentTemplate = Get-Content -Path (Join-Path $PSScriptRoot '..\..\templates\agent_template.js') -Raw

# Create agents
for ($i=1; $i -le $count; $i++) {
    $agentFolder = Join-Path $agentsDir ("agent_$i")
    New-Item -ItemType Directory -Force -Path $agentFolder | Out-Null
    $agentJs = Join-Path $agentFolder 'agent.js'
    Set-Content -Path $agentJs -Value $agentTemplate -Encoding UTF8
    # Make executable on Unix
    try { icacls $agentJs /grant *S-1-1-0:RX } catch { }
    # Create README
    $readme = "# Agent $i`nThis agent performs local analysis of the project root. Run with: node agent.js"
    Set-Content -Path (Join-Path $agentFolder 'README.md') -Value $readme -Encoding UTF8
}

# Create pm2 ecosystem file to run all agents with restart policy
$ecosystem = @{ apps = @() }
for ($i=1; $i -le $count; $i++) {
    $appName = "agent_$i"
    $script = "./.agents/agent_$i/agent.js"
    $ecosystem.apps += @{ name = $appName; script = $script; cwd = $targetPath; restart_delay = 5000; autorestart = $true }
}
$ecosystemJson = $ecosystem | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $targetPath 'ecosystem.config.json') -Value $ecosystemJson -Encoding UTF8

# Package as plugin
$packagePath = Join-Path $targetPath $packageFolderName
if (Test-Path $packagePath) { Remove-Item -Recurse -Force -Path $packagePath }
New-Item -ItemType Directory -Force -Path $packagePath | Out-Null
Copy-Item -Path $agentsDir -Destination $packagePath -Recurse -Force
Copy-Item -Path (Join-Path $targetPath 'ecosystem.config.json') -Destination $packagePath -Force

# Create simple plugin manifest and an install script
$pluginJson = @{
    name = "agents-plugin"
    version = "0.1.0"
    description = "Generated autonomous Node.js agents package"
    author = @{ name = "copilot" }
}
$pluginJson | ConvertTo-Json -Depth 3 | Set-Content -Path (Join-Path $packagePath 'plugin.json') -Encoding UTF8

$installPs = @'
# Install and start agents with pm2 (requires npm and pm2 installed)
if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Output "npm not found; please install Node.js/npm first"
  exit 1
}
try {
  npm install -g pm2
} catch { }
pm2 start ecosystem.config.json --cwd .
'@
Set-Content -Path (Join-Path $packagePath 'install_agents.ps1') -Value $installPs -Encoding UTF8

Write-Output "Generated $count agents in: $agentsDir"
Write-Output "Packaged plugin at: $packagePath"
