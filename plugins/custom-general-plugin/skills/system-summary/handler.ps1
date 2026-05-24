# Handler for system-summary skill - outputs minimal overview with Skills and Instructions separated
$version = '1.0.52'

# Skills: count SKILL.md files under installed plugins and repo plugins
$skills = (Get-ChildItem -Path 'C:\Users\admin\.copilot\installed-plugins','C:\git\copilot_cli_upd\plugins' -Recurse -Filter 'SKILL.md' -File -ErrorAction SilentlyContinue | Measure-Object).Count

# Instructions: try CLI 'instructions list', fallback to INSTRUCTION.md files
$instructions = $null
try {
    $instrOutput = & copilot instructions list 2>$null
    if ($LASTEXITCODE -eq 0 -and $instrOutput) {
        # If output is multiple lines, count lines; otherwise if JSON, attempt to parse
        $instructions = ($instrOutput | Measure-Object).Count
    }
} catch {
    # ignore - fallback
}
if (-not $instructions -or $instructions -eq 0) {
    $instructions = (Get-ChildItem -Path 'C:\Users\admin\.copilot\installed-plugins','C:\git\copilot_cli_upd\plugins' -Recurse -Filter 'INSTRUCTION.md' -File -ErrorAction SilentlyContinue | Measure-Object).Count
}

# Plugins: top-level directories under installed-plugins
$plugins = (Get-ChildItem -Path 'C:\Users\admin\.copilot\installed-plugins' -Directory -ErrorAction SilentlyContinue | Measure-Object).Count

# MCP: search plugin.json files containing 'mcp'
$mcp = (Get-ChildItem -Path 'C:\Users\admin\.copilot\installed-plugins','C:\git\copilot_cli_upd\plugins' -Recurse -Filter 'plugin.json' -File -ErrorAction SilentlyContinue | Select-String -Pattern 'mcp' | Select-Object -ExpandProperty Path -Unique | Measure-Object).Count

# Agents: try CLI 'copilot agents list' to count active background agents
$agents = 0
try {
    $agentsOut = & copilot agents list 2>$null
    if ($LASTEXITCODE -eq 0 -and $agentsOut) {
        $agents = ($agentsOut | Measure-Object).Count
    }
} catch {
    # fallback to 0
}
if (-not $agents) { $agents = 0 }

Write-Output "Copilot CLI version: $version"
Write-Output "Skills: $skills"
Write-Output "Instructions: $instructions"
Write-Output "Agents: $agents"
Write-Output "Plugins: $plugins"
Write-Output "MCP: $mcp"
