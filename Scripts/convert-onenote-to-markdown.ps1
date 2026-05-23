# PowerShell Script: DOCX to Markdown Conversion
# Purpose: Convert DOCX files to markdown and organize by module
# Note: For .one → DOCX export, use: one-note-to-markdown tool
#       https://github.com/segunak/one-note-to-markdown
# Usage: .\convert-onenote-to-markdown.ps1 -DryRun (preview first)
#        .\convert-onenote-to-markdown.ps1 (execute)

param(
    [string]$DocxPath = "F:\OneDrive\OneNote_Export",
    [string]$OutputPath = "F:\OneDrive",
    [switch]$DryRun = $false,
    [switch]$SkipExisting = $false,
    [string]$ModuleMappingFile = "$PSScriptRoot\onenote-module-mapping.json",
    [string]$LogFile = "$OutputPath\conversion.log"
)

$ErrorActionPreference = "Stop"

# Color output
$Colors = @{
    Green  = 'Green'
    Yellow = 'Yellow'
    Red    = 'Red'
    Cyan   = 'Cyan'
    Gray   = 'Gray'
}

function Write-Info { Write-Host $args -ForegroundColor $Colors.Cyan }
function Write-Success { Write-Host $args -ForegroundColor $Colors.Green }
function Write-Warning { Write-Host $args -ForegroundColor $Colors.Yellow }
function Write-Error-Custom { Write-Host $args -ForegroundColor $Colors.Red }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Add-Content -Path $LogFile
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DOCX to Markdown Conversion & Organization" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Validate prerequisites
Write-Info "Validating prerequisites..."

if (-not (Test-Path $DocxPath)) {
    Write-Error-Custom "ERROR: DOCX path not found: $DocxPath"
    Write-Error-Custom ""
    Write-Error-Custom "Please export DOCX files first:"
    Write-Error-Custom "  1. Use: https://github.com/segunak/one-note-to-markdown"
    Write-Error-Custom "  2. Download OneNoteMarkdownExporter.exe from GitHub Releases"
    Write-Error-Custom "  3. Run: OneNoteMarkdownExporter.exe --all --output `"$DocxPath`""
    Write-Error-Custom ""
    Write-Error-Custom "Or manually export from OneNote Desktop:"
    Write-Error-Custom "  File → Export → Select notebooks → Word Document (.docx)"
    Write-Error-Custom "  Save to: $DocxPath\"
    exit 1
}

if (-not (Test-Path $OutputPath)) {
    Write-Error-Custom "ERROR: Output path not found: $OutputPath"
    exit 1
}

if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "ERROR: Pandoc not found. Install with: choco install pandoc"
    Write-Log "FAILED: Pandoc not installed"
    exit 1
}

if (-not (Test-Path $ModuleMappingFile)) {
    Write-Warning "Module mapping file not found, creating default..."
    $defaultMapping = @{
        health = @{
            keywords = @("doctor", "appointment", "medication", "prescription", "health", "medical")
            notebooks = @("Health", "Medical")
        }
        insurance = @{
            keywords = @("insurance", "policy", "premium", "coverage", "renewal", "claim")
            notebooks = @("Insurance")
        }
        work = @{
            keywords = @("work", "job", "salary", "contract", "project", "team")
            notebooks = @("Work", "Projects", "IT")
        }
        family = @{
            keywords = @("family", "birthday", "anniversary", "relatives")
            notebooks = @("Family")
        }
        car = @{
            keywords = @("car", "vehicle", "maintenance", "repair", "registration")
            notebooks = @("Car")
        }
        real_estate = @{
            keywords = @("house", "property", "apartment", "mortgage", "real estate")
            notebooks = @("Real Estate")
        }
        documents = @{
            keywords = @("document", "certificate", "personal", "finance")
            notebooks = @("Documents", "Personal", "Finance")
        }
    }
    $defaultMapping | ConvertTo-Json | Set-Content -Path $ModuleMappingFile
    Write-Success "Created: $ModuleMappingFile"
}

$mapping = Get-Content $ModuleMappingFile | ConvertFrom-Json
Write-Success "✅ Prerequisites validated"
Write-Log "Prerequisites check passed"

# ==================== STAGE 1: Check for .docx files ====================
Write-Info "`n[Stage 1/3] Checking for DOCX files..."
Write-Info "  Searching: $DocxPath"

$docxFiles = Get-ChildItem -Path $DocxPath -Recurse -Filter "*.docx" -ErrorAction SilentlyContinue
$docxCount = $docxFiles.Count
Write-Host "  Found: $docxCount .docx files"

if ($docxCount -eq 0) {
    Write-Warning "`nNo DOCX files found in: $DocxPath"
    Write-Host ""
    Write-Host "To export OneNote notebooks to DOCX format:"
    Write-Host ""
    Write-Host "RECOMMENDED: Use one-note-to-markdown tool"
    Write-Host "  1. Download: https://github.com/segunak/one-note-to-markdown/releases"
    Write-Host "  2. Extract and run: OneNoteMarkdownExporter.exe"
    Write-Host "  3. Or use CLI: OneNoteMarkdownExporter.exe --all --output `"$DocxPath`""
    Write-Host ""
    Write-Host "ALTERNATIVE: Manual export from OneNote Desktop"
    Write-Host "  1. Open OneNote Desktop"
    Write-Host "  2. File → Export"
    Write-Host "  3. Choose: 'All Notebooks' or export individually"
    Write-Host "  4. Format: Word Document (.docx)"
    Write-Host "  5. Save to: $DocxPath\"
    Write-Host ""
    Write-Log "No .docx files found"
    exit 0
}

Write-Success "✅ Found $docxCount DOCX files"
Write-Log "Found $docxCount .docx files"

# ==================== STAGE 2: Convert DOCX to Markdown ====================
Write-Info "`n[Stage 2/3] Converting DOCX to Markdown with Pandoc..."

$stats = @{
    Converted = 0
    Skipped = 0
    Failed = 0
    TotalSize = 0
}

$failedFiles = @()
$startTime = Get-Date

foreach ($docxFile in $docxFiles) {
    $mdPath = $docxFile.FullName -replace '\.docx$', '.md'
    
    # Check if markdown already exists
    if ((Test-Path $mdPath) -and $SkipExisting) {
        Write-Host "  ⏭️  SKIP: $(Split-Path $mdPath -Leaf)" -ForegroundColor Gray
        $stats.Skipped++
        Write-Log "SKIPPED: $($docxFile.Name) (already exists)"
        continue
    }
    
    if ($DryRun) {
        Write-Host "  📝 [DRY-RUN] Would convert: $(Split-Path $docxFile.FullName -Leaf)" -ForegroundColor Yellow
        $stats.Converted++
    } else {
        try {
            # Run Pandoc conversion
            & pandoc "$($docxFile.FullName)" -t markdown -o "$mdPath" 2>&1 | Out-Null
            
            if (Test-Path $mdPath) {
                $mdSize = (Get-Item $mdPath).Length / 1KB
                Write-Host "  ✅ $(Split-Path $mdPath -Leaf) ($([Math]::Round($mdSize, 1)) KB)" -ForegroundColor Green
                $stats.Converted++
                $stats.TotalSize += $mdSize
                Write-Log "CONVERTED: $($docxFile.Name) → $(Split-Path $mdPath -Leaf)"
            } else {
                Write-Host "  ❌ FAILED: $(Split-Path $docxFile.FullName -Leaf)" -ForegroundColor Red
                $stats.Failed++
                $failedFiles += $docxFile.Name
                Write-Log "FAILED: $($docxFile.Name)"
            }
        } catch {
            Write-Host "  ❌ ERROR: $(Split-Path $docxFile.FullName -Leaf) - $_" -ForegroundColor Red
            $stats.Failed++
            $failedFiles += $docxFile.Name
            Write-Log "ERROR: $($docxFile.Name) - $_"
        }
    }
}

$duration = (Get-Date) - $startTime
Write-Success "✅ Conversion complete ($('{0:hh\:mm\:ss}' -f $duration))"

# ==================== STAGE 3: Organize by Module ====================
Write-Info "`n[Stage 4/4] Organizing files by module..."

$mdFiles = Get-ChildItem -Path $OutputPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue

$organization = @{}
foreach ($module in $mapping.PSObject.Properties.Name) {
    $organization[$module] = @()
}
$organization["unmapped"] = @()

foreach ($mdFile in $mdFiles) {
    $content = Get-Content $mdFile.FullName -Raw
    $fileName = $mdFile.Name.ToLower()
    $parentName = (Split-Path $mdFile.FullName -Parent | Split-Path -Leaf).ToLower()
    
    $mapped = $false
    foreach ($module in $mapping.PSObject.Properties.Name) {
        $moduleConfig = $mapping.$module
        
        # Check by notebook name first
        foreach ($notebook in $moduleConfig.notebooks) {
            if ($parentName -like "*$($notebook.ToLower())*") {
                $organization[$module] += $mdFile
                $mapped = $true
                break
            }
        }
        
        # Check by keywords in filename
        if (-not $mapped) {
            foreach ($keyword in $moduleConfig.keywords) {
                if ($fileName -like "*$($keyword.ToLower())*") {
                    $organization[$module] += $mdFile
                    $mapped = $true
                    break
                }
            }
        }
        
        if ($mapped) { break }
    }
    
    if (-not $mapped) {
        $organization["unmapped"] += $mdFile
    }
}

# Create module folders and move files
foreach ($module in $organization.Keys) {
    $files = $organization[$module]
    
    if ($files.Count -eq 0) {
        continue
    }
    
    $moduleFolder = Join-Path $OutputPath $module
    
    if (-not (Test-Path $moduleFolder)) {
        New-Item -ItemType Directory -Path $moduleFolder -Force | Out-Null
        Write-Host "  📁 Created: $module/" -ForegroundColor Cyan
    }
    
    foreach ($file in $files) {
        $targetPath = Join-Path $moduleFolder $file.Name
        
        if ($DryRun) {
            Write-Host "    📝 [DRY-RUN] Would move: $($file.Name)" -ForegroundColor Yellow
        } else {
            Move-Item -Path $file.FullName -Destination $targetPath -Force -ErrorAction SilentlyContinue
            Write-Host "    ✅ $($file.Name) → $module/" -ForegroundColor Green
            Write-Log "ORGANIZED: $($file.Name) → $module/"
        }
    }
    
    Write-Host "    └─ $($files.Count) files" -ForegroundColor Gray
}

Write-Success "✅ Files organized by module"

# ==================== STAGE 4: Generate Index ====================
Write-Info "`n[Stage 4/4] Generating index..."

$indexContent = @"
# OneNote Export - Markdown Index

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary

- **Total Markdown Files:** $($mdFiles.Count)
- **Conversion Time:** $('{0:hh\:mm\:ss}' -f $duration)
- **Total Size:** $([Math]::Round($stats.TotalSize, 1)) KB

---

## By Module

"@

foreach ($module in $organization.Keys) {
    $files = $organization[$module]
    if ($files.Count -gt 0) {
        $indexContent += "`n### $([char]::ToUpper($module[0])) $($module.Substring(1)) ($($files.Count) files)`n`n"
        
        foreach ($file in $files | Sort-Object Name) {
            $relativePath = $file.FullName -replace [regex]::Escape("$OutputPath\"), ""
            $indexContent += "- [$($file.BaseName)](./$relativePath)`n"
        }
    }
}

$indexPath = Join-Path $OutputPath "INDEX.md"

if ($DryRun) {
    Write-Host "  📝 [DRY-RUN] Would create: INDEX.md" -ForegroundColor Yellow
} else {
    $indexContent | Set-Content -Path $indexPath
    Write-Success "✅ Index created: INDEX.md"
    Write-Log "Created: INDEX.md"
}

# ==================== Final Report ====================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Conversion Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Stage Results:" -ForegroundColor Yellow
Write-Host "  .docx files found:   $docxCount" -ForegroundColor Gray
Write-Host "  .md files converted: $($stats.Converted)" -ForegroundColor Green
Write-Host "  .md files skipped:   $($stats.Skipped)" -ForegroundColor Gray
Write-Host "  Conversion failed:   $($stats.Failed)" -ForegroundColor $($stats.Failed -gt 0 ? $Colors.Red : $Colors.Green)

Write-Host ""
Write-Host "Organization:" -ForegroundColor Yellow
foreach ($module in $organization.Keys | Sort-Object) {
    $count = $organization[$module].Count
    if ($count -gt 0) {
        Write-Host "  $module`: $count files" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Output Location:" -ForegroundColor Yellow
Write-Host "  $OutputPath" -ForegroundColor Cyan

Write-Host ""
Write-Host "Index File:" -ForegroundColor Yellow
Write-Host "  $indexPath" -ForegroundColor Cyan

Write-Host ""
Write-Host "Total Duration:" -ForegroundColor Yellow
Write-Host "  $('{0:hh\:mm\:ss}' -f $duration)" -ForegroundColor Green

if ($DryRun) {
    Write-Host ""
    Write-Host "⚠️  DRY-RUN MODE - No files were actually modified" -ForegroundColor Yellow
}

if ($stats.Failed -gt 0) {
    Write-Host ""
    Write-Host "Failed Files:" -ForegroundColor Red
    $failedFiles | ForEach-Object { Write-Host "  ❌ $_" -ForegroundColor Red }
}

Write-Host ""
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Log "Conversion complete: Converted=$($stats.Converted), Skipped=$($stats.Skipped), Failed=$($stats.Failed)"
