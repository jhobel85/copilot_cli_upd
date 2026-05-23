#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Assembles the three layered Copilot instruction files from source layers.

.DESCRIPTION
    Source layers live in Instructions/src/ and contain no duplication.
    This script concatenates them in order to produce three composite output files:

        copilot-instructions.meta.md    = meta only
        copilot-instructions.dev.md     = meta + dev
        copilot-instructions.agentic.md = meta + dev + agentic

    ALWAYS edit the source layers, never the output files.

.EXAMPLE
    .\build-instructions.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$srcDir     = Join-Path $PSScriptRoot "src"
$outDir     = $PSScriptRoot

$layerMeta    = Join-Path $srcDir "layer.meta.md"
$layerDev     = Join-Path $srcDir "layer.dev.md"
$layerAgentic = Join-Path $srcDir "layer.agentic.md"

function Build-Output {
    param(
        [string]   $OutputPath,
        [string[]] $Layers,
        [string]   $Label
    )

    $banner = @"
<!-- ============================================================
     GENERATED FILE — do not edit directly.
     Source layers: $Label
     Regenerate:    Instructions\build-instructions.ps1
     ============================================================ -->

"@

    $parts = @($banner)
    foreach ($layer in $Layers) {
        $parts += Get-Content $layer -Raw
        $parts += "`n"
    }

    $parts -join "" | Set-Content -Path $OutputPath -Encoding UTF8 -NoNewline
    Write-Host "  ✅ $(Split-Path $OutputPath -Leaf)"
}

Write-Host ""
Write-Host "Building Copilot instruction files..."
Write-Host ""

Build-Output `
    -OutputPath (Join-Path $outDir "copilot-instructions.meta.md") `
    -Layers     @($layerMeta) `
    -Label      "layer.meta"

Build-Output `
    -OutputPath (Join-Path $outDir "copilot-instructions.dev.md") `
    -Layers     @($layerMeta, $layerDev) `
    -Label      "layer.meta + layer.dev"

Build-Output `
    -OutputPath (Join-Path $outDir "copilot-instructions.agentic.md") `
    -Layers     @($layerMeta, $layerDev, $layerAgentic) `
    -Label      "layer.meta + layer.dev + layer.agentic"

Write-Host ""
Write-Host "Done. Three output files written to: $outDir"
Write-Host ""
