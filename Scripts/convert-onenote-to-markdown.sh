#!/bin/bash
# Script: Fully Automated OneNote to Markdown Conversion (Bash)
# Purpose: Convert .docx to markdown, organize by module (for WSL/Linux)
# Usage: bash convert-onenote-to-markdown.sh --dry-run (preview first)
#        bash convert-onenote-to-markdown.sh (execute)

# ============================================================================
# Configuration
# ============================================================================

set -euo pipefail

OUTPUT_PATH="${1:-/f/OneDrive/OneNote_Export}"
DRY_RUN=false
SKIP_EXISTING=false
LOG_FILE="$OUTPUT_PATH/conversion.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
while [[ $# -gt 1 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --skip-existing)
            SKIP_EXISTING=true
            ;;
        --output)
            OUTPUT_PATH="$2"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

log_info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

log_file() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" >> "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$*${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# ============================================================================
# Validation
# ============================================================================

print_header "OneNote to Markdown - Fully Automated (Bash)"

log_info "Validating prerequisites..."

if [[ ! -d "$OUTPUT_PATH" ]]; then
    log_error "Output path not found: $OUTPUT_PATH"
    log_file "FAILED: Output path not found"
    exit 1
fi

if ! command -v pandoc &> /dev/null; then
    log_error "Pandoc not found. Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install pandoc"
    echo "  macOS: brew install pandoc"
    log_file "FAILED: Pandoc not installed"
    exit 1
fi

if [[ ! -w "$OUTPUT_PATH" ]]; then
    log_error "No write permission on: $OUTPUT_PATH"
    log_file "FAILED: No write permission"
    exit 1
fi

log_success "Prerequisites validated"
log_file "Prerequisites check passed"

# ============================================================================
# Stage 1: Find .docx files
# ============================================================================

log_info ""
log_info "[Stage 1/4] Finding DOCX files..."

docx_count=$(find "$OUTPUT_PATH" -name "*.docx" -type f | wc -l)
log_info "Found: $docx_count .docx files"

if [[ $docx_count -eq 0 ]]; then
    log_warning "No DOCX files found. Please run:"
    echo "  On Windows: .\Scripts\Export-OneNoteToDOCX.ps1 -OutputPath \"$OUTPUT_PATH\""
    echo "  OR manually export in OneNote: File → Export → Word Document"
    log_file "ABORTED: No DOCX files found"
    exit 0
fi

log_file "Found $docx_count .docx files"

# ============================================================================
# Stage 2: Convert DOCX to Markdown with Pandoc
# ============================================================================

log_info ""
log_info "[Stage 2/4] Converting DOCX to Markdown..."

converted=0
skipped=0
failed=0
start_time=$(date +%s)

while IFS= read -r -d '' docx_file; do
    md_file="${docx_file%.docx}.md"
    filename=$(basename "$docx_file")
    
    # Check if markdown already exists
    if [[ -f "$md_file" ]] && [[ "$SKIP_EXISTING" == "true" ]]; then
        echo -e "  ${GRAY}⏭ SKIP: $(basename "$md_file")${NC}"
        ((skipped++))
        log_file "SKIPPED: $filename (already exists)"
        continue
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}📝 [DRY-RUN] Would convert: $filename${NC}"
        ((converted++))
    else
        if pandoc "$docx_file" -t markdown -o "$md_file" 2>/dev/null; then
            md_size=$(du -h "$md_file" | cut -f1)
            echo -e "  ${GREEN}✅ $(basename "$md_file") ($md_size)${NC}"
            ((converted++))
            log_file "CONVERTED: $filename → $(basename "$md_file")"
        else
            echo -e "  ${RED}❌ FAILED: $filename${NC}"
            ((failed++))
            log_file "FAILED: $filename"
        fi
    fi
done < <(find "$OUTPUT_PATH" -name "*.docx" -type f -print0)

log_success "Conversion complete"

# ============================================================================
# Stage 3: Organize by Module
# ============================================================================

log_info ""
log_info "[Stage 3/4] Organizing files by module..."

# Module mapping
declare -A modules=(
    [health]="doctor|appointment|medication|prescription|health|medical|hospital|clinic|patient"
    [insurance]="insurance|policy|premium|coverage|renewal|claim|deductible"
    [work]="work|job|salary|contract|project|team|employment|company|payroll|benefits|it|development"
    [family]="family|birthday|anniversary|relatives|mother|father|brother|sister|parent"
    [car]="car|vehicle|maintenance|repair|registration|service|mechanic|fuel|tire|engine"
    [real_estate]="house|property|apartment|mortgage|real estate|rent|lease|building|renovation|home"
    [documents]="document|certificate|personal|finance|financial|tax|account|banking|receipt|invoice|bill"
)

# Move markdown files to module folders
while IFS= read -r -d '' md_file; do
    filename=$(basename "$md_file")
    filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
    
    # Check each module
    moved=false
    for module in "${!modules[@]}"; do
        keywords="${modules[$module]}"
        
        # Check if filename matches any keyword
        if echo "$filename_lower" | grep -iE "$keywords" > /dev/null; then
            module_dir="$OUTPUT_PATH/$module"
            
            if [[ ! -d "$module_dir" ]]; then
                mkdir -p "$module_dir"
                echo -e "  ${CYAN}📁 Created: $module/${NC}"
            fi
            
            target_path="$module_dir/$filename"
            
            if [[ "$DRY_RUN" == "true" ]]; then
                echo -e "    ${YELLOW}📝 [DRY-RUN] Would move: $filename${NC}"
            else
                mv "$md_file" "$target_path"
                echo -e "    ${GREEN}✅ $filename → $module/${NC}"
                log_file "ORGANIZED: $filename → $module/"
            fi
            
            moved=true
            break
        fi
    done
    
    # If not moved to any module, move to "unmapped"
    if [[ "$moved" == "false" ]]; then
        unmapped_dir="$OUTPUT_PATH/unmapped"
        
        if [[ ! -d "$unmapped_dir" ]]; then
            mkdir -p "$unmapped_dir"
            echo -e "  ${CYAN}📁 Created: unmapped/${NC}"
        fi
        
        target_path="$unmapped_dir/$filename"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "    ${YELLOW}📝 [DRY-RUN] Would move: $filename${NC}"
        else
            mv "$md_file" "$target_path"
            echo -e "    ${GREEN}✅ $filename → unmapped/${NC}"
            log_file "ORGANIZED: $filename → unmapped/"
        fi
    fi
done < <(find "$OUTPUT_PATH" -maxdepth 1 -name "*.md" -type f -print0)

log_success "Files organized by module"

# ============================================================================
# Stage 4: Generate Index
# ============================================================================

log_info ""
log_info "[Stage 4/4] Generating index..."

end_time=$(date +%s)
duration=$((end_time - start_time))

index_file="$OUTPUT_PATH/INDEX.md"
md_count=$(find "$OUTPUT_PATH" -name "*.md" -type f | wc -l)

cat > /tmp/index.md << EOF
# OneNote Export - Markdown Index

Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Summary

- **Total Markdown Files:** $md_count
- **Conversion Time:** $(printf '%dh %dm %ds\n' $((duration/3600)) $((duration%3600/60)) $((duration%60)))

---

## By Module

EOF

for module in "${!modules[@]}"; do
    module_dir="$OUTPUT_PATH/$module"
    if [[ -d "$module_dir" ]]; then
        file_count=$(find "$module_dir" -name "*.md" -type f | wc -l)
        if [[ $file_count -gt 0 ]]; then
            echo "### $(echo "$module" | sed 's/^./\U&/') ($file_count files)" >> /tmp/index.md
            echo "" >> /tmp/index.md
            
            find "$module_dir" -name "*.md" -type f | sort | while read -r file; do
                relative_path="${file#$OUTPUT_PATH/}"
                basename_file=$(basename "$file" .md)
                echo "- [$basename_file](./$relative_path)" >> /tmp/index.md
            done
            echo "" >> /tmp/index.md
        fi
    fi
done

# Check for unmapped files
unmapped_dir="$OUTPUT_PATH/unmapped"
if [[ -d "$unmapped_dir" ]]; then
    file_count=$(find "$unmapped_dir" -name "*.md" -type f | wc -l)
    if [[ $file_count -gt 0 ]]; then
        echo "### Unmapped ($file_count files)" >> /tmp/index.md
        echo "" >> /tmp/index.md
        
        find "$unmapped_dir" -name "*.md" -type f | sort | while read -r file; do
            relative_path="${file#$OUTPUT_PATH/}"
            basename_file=$(basename "$file" .md)
            echo "- [$basename_file](./$relative_path)" >> /tmp/index.md
        done
    fi
fi

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Would create: INDEX.md"
else
    mv /tmp/index.md "$index_file"
    log_success "Index created: INDEX.md"
    log_file "Created: INDEX.md"
fi

# ============================================================================
# Final Report
# ============================================================================

print_header "Conversion Report"

echo -e "${YELLOW}Stage Results:${NC}"
echo -e "  ${GRAY}.docx files found:   $docx_count${NC}"
echo -e "  ${GREEN}.md files converted: $converted${NC}"
echo -e "  ${GRAY}.md files skipped:   $skipped${NC}"
echo -e "  ${RED}.md files failed:    $failed${NC}"

echo ""
echo -e "${YELLOW}Output Location:${NC}"
echo -e "  ${CYAN}$OUTPUT_PATH${NC}"

echo ""
echo -e "${YELLOW}Index File:${NC}"
echo -e "  ${CYAN}$index_file${NC}"

echo ""
echo -e "${YELLOW}Total Duration:${NC}"
echo -e "  ${GREEN}$duration seconds${NC}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  DRY-RUN MODE - No files were actually modified${NC}"
fi

echo ""
print_header ""

log_file "Conversion complete: Converted=$converted, Skipped=$skipped, Failed=$failed"
