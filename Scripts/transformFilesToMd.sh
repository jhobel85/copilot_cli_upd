#!/bin/bash
# Google Drive File Transformer - Convert all files to Markdown
# Purpose: Recursively convert all documents in F:\GDrive\ to Markdown in F:\MDs\GDrive\
# Supports: PDF, DOCX, DOC, PPTX, PPT, ODT, XLSX, XLS, TXT, HTML, HTM
#
# Usage:
#   bash transformFilesToMd.sh [--dry-run] [--skip-existing]
#
#   --dry-run        Show what would be converted without writing files
#   --force          Re-convert files even if output .md already exists

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse flags
DRY_RUN=false
SKIP_EXISTING=true
PURGE_EMPTY=false
for arg in "$@"; do
    case $arg in
        --dry-run)       DRY_RUN=true ;;
        --skip-existing) SKIP_EXISTING=true ;;   # already default, kept for compatibility
        --force)         SKIP_EXISTING=false ;;
        --purge-empty)   PURGE_EMPTY=true ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--force] [--purge-empty]"
            echo "  --dry-run      Show what would be converted (no files written)"
            echo "  --force        Re-convert files even if output .md already exists"
            echo "  --purge-empty  Delete existing .md files that contain only a YAML header"
            echo "                 (empty body), so they are re-converted on this run"
            echo ""
            echo "Supported formats: PDF, DOCX, DOC, ODT, PPTX, PPT, XLSX, XLS,"
            echo "                   TXT, HTML, HTM, JPG, JPEG, PNG, TIF, TIFF"
            exit 0
            ;;
    esac
done

# Configuration
GDRIVE_WSL_PATH="/mnt/f/GDrive"
OUTPUT_BASE="/mnt/f/MDs/GDrive"
PDF_PASSWORD="8511192184"   # tried on encrypted PDFs before skipping
TEMP_DIR="/tmp/gdrive-transform-$$"
LOG_FILE="$OUTPUT_BASE/transform.log"

# ============================================================================
# STEP 1: Install Required Tools
# ============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Google Drive File Transformer${NC}"
if [ "$DRY_RUN" = true ]; then echo -e "${YELLOW}  (DRY RUN - no files will be written)${NC}"; fi
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Step 1: Checking and installing required tools...${NC}"
echo ""

APT_UPDATED=0

install_tool() {
    local tool_name="$1"
    local package_name="$2"
    local command_name="${3:-$2}"
    if ! command -v "$command_name" &>/dev/null; then
        echo -e "${YELLOW}Installing $tool_name...${NC}"
        if [ "$APT_UPDATED" -eq 0 ]; then
            sudo apt-get update -qq
            APT_UPDATED=1
        fi
        if sudo apt-get install -y "$package_name" 2>/dev/null; then
            command -v "$command_name" &>/dev/null \
                && echo -e "${GREEN}+ $tool_name installed${NC}" \
                || { echo -e "${RED}x $tool_name installation failed${NC}"; exit 1; }
        else
            echo -e "${RED}x Failed to install $tool_name${NC}"; exit 1
        fi
    else
        echo -e "${GREEN}+ $tool_name already installed${NC}"
    fi
}

if [ "$DRY_RUN" = false ]; then
    install_tool "ocrmypdf"      "ocrmypdf"              "ocrmypdf"
    install_tool "pandoc"        "pandoc"                 "pandoc"
    install_tool "pdftotext"     "poppler-utils"          "pdftotext"
    install_tool "libreoffice"   "libreoffice"            "libreoffice"
    install_tool "qpdf"          "qpdf"                   "qpdf"
    install_tool "tesseract-ocr" "tesseract-ocr"          "tesseract"
    install_tool "exiftool"      "libimage-exiftool-perl" "exiftool"

    # Tesseract language packs are not commands - check via list-langs
    if ! tesseract --list-langs 2>/dev/null | grep -q "^ces$"; then
        echo -e "${YELLOW}Installing Tesseract Czech language data...${NC}"
        if [ "$APT_UPDATED" -eq 0 ]; then sudo apt-get update -qq; APT_UPDATED=1; fi
        sudo apt-get install -y tesseract-ocr-ces 2>/dev/null \
            && echo -e "${GREEN}+ Tesseract Czech (ces) installed${NC}" \
            || echo -e "${YELLOW}! Could not install tesseract-ocr-ces, OCR will use English only${NC}"
    else
        echo -e "${GREEN}+ Tesseract Czech (ces) already installed${NC}"
    fi
    if ! tesseract --list-langs 2>/dev/null | grep -q "^eng$"; then
        if [ "$APT_UPDATED" -eq 0 ]; then sudo apt-get update -qq; APT_UPDATED=1; fi
        sudo apt-get install -y tesseract-ocr-eng 2>/dev/null || true
    fi
else
    echo -e "${YELLOW}Dry-run: skipping tool installation check${NC}"
fi

echo ""
echo -e "${GREEN}+ All dependencies installed and verified!${NC}"

# ============================================================================
# STEP 2: Verify Google Drive Folder Access
# ============================================================================

echo ""
echo -e "${YELLOW}Step 2: Checking Google Drive folder access...${NC}"

if [ ! -d "$GDRIVE_WSL_PATH" ]; then
    echo -e "${RED}x Google Drive folder not found: $GDRIVE_WSL_PATH${NC}"
    echo "Troubleshooting:"
    echo "  1. Verify Google Drive is synced in Windows"
    echo "  2. Check if F: drive is accessible: ls /mnt/f/"
    echo "  3. Ensure the GDrive folder exists in the F: root"
    exit 1
fi

echo -e "${GREEN}+ Google Drive folder accessible: $GDRIVE_WSL_PATH${NC}"

# ============================================================================
# STEP 3: Create Output Directory
# ============================================================================

echo ""
echo -e "${YELLOW}Step 3: Creating output directory...${NC}"

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$OUTPUT_BASE"
    mkdir -p "$TEMP_DIR"
fi

echo -e "${GREEN}+ Output directory: $OUTPUT_BASE${NC}"

# ============================================================================
# STEP 4: Define Conversion Functions
# ============================================================================

# Counters - kept in main shell (NOT in a pipe subshell)
TOTAL_FILES=0
CONVERTED_FILES=0
FAILED_FILES=0
SKIPPED_FILES=0

# Cleanup temp dir on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

log_message() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    if [ "$DRY_RUN" = false ]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

# Write YAML front-matter to a new file
write_yaml_header() {
    local output="$1" title="$2" source="$3" type="$4" date="$5"
    {
        echo "---"
        echo "title: \"$title\""
        echo "source: \"$source\""
        echo "date: $date"
        echo "type: $type"
        echo "---"
        echo ""
    } > "$output"
}

# ============================================================================
# STEP 4b: Purge header-only (empty body) .md files (optional)
# ============================================================================

if [ "$PURGE_EMPTY" = true ] && [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${YELLOW}Step 4b: Purging header-only .md files...${NC}"
    PURGED=0
    while IFS= read -r md_file; do
        # A header-only file has no non-whitespace content after the closing "---".
        if ! awk '
            /^---/ { if (++fence == 2) { body=1; next } }
            body && /[^[:space:]]/ { found=1; exit }
            END { exit !found }
        ' "$md_file" 2>/dev/null; then
            rm -f "$md_file"
            PURGED=$((PURGED + 1))
            log_message "  - Purged empty: $(basename "$md_file")"
        fi
    done < <(find "$OUTPUT_BASE" -name "*.md" ! -name "transform.log" 2>/dev/null)
    echo -e "${GREEN}+ Purged $PURGED header-only .md file(s)${NC}"
fi

convert_pdf() {
    local input="$1" output="$2"
    local filename date work_pdf decrypted temp_txt ocr_pdf ocr_txt ocr_err ocr_langs
    filename=$(basename "$input")
    date=$(stat -c %y "$input" | cut -d' ' -f1)
    log_message "Processing PDF: $filename"

    # Try to decrypt encrypted PDFs before any processing
    work_pdf="$input"
    if [ -n "$PDF_PASSWORD" ] && command -v qpdf &>/dev/null; then
        decrypted="$TEMP_DIR/${filename%.pdf}_decrypted.pdf"
        if qpdf --password="$PDF_PASSWORD" --decrypt "$input" "$decrypted" 2>/dev/null; then
            work_pdf="$decrypted"
            log_message "  * Decrypted PDF with password"
        fi
    fi

    temp_txt="$TEMP_DIR/${filename%.pdf}.txt"
    if pdftotext -q "$work_pdf" "$temp_txt" 2>/dev/null \
            && grep -q '[^[:space:]]' "$temp_txt" 2>/dev/null; then
        write_yaml_header "$output" "$filename" "$input" "PDF (text-based)" "$date"
        cat "$temp_txt" >> "$output"
        rm -f "$temp_txt" "$decrypted"
        log_message "  + Converted PDF (text-based) -> Markdown"
        return 0
    fi
    rm -f "$temp_txt"

    # Scanned PDF - try OCR
    ocr_pdf="$TEMP_DIR/${filename%.pdf}_ocr.pdf"
    ocr_txt="${ocr_pdf}.txt"
    ocr_err="$TEMP_DIR/${filename%.pdf}_ocr.err"
    log_message "  * Running OCR on scanned PDF..."

    ocr_langs="eng"
    tesseract --list-langs 2>/dev/null | grep -q "^ces$" && ocr_langs="ces+eng"

    if ocrmypdf -l "$ocr_langs" --skip-text --quiet \
            --sidecar "$ocr_txt" "$work_pdf" "$ocr_pdf" 2>"$ocr_err"; then
        if [ -f "$ocr_txt" ] && grep -q '[^[:space:]]' "$ocr_txt" 2>/dev/null; then
            write_yaml_header "$output" "$filename" "$input" "PDF (scanned+OCR)" "$date"
            cat "$ocr_txt" >> "$output"
            rm -f "$ocr_txt" "$ocr_pdf" "$ocr_err" "$decrypted"
            log_message "  + Converted PDF (scanned+OCR) -> Markdown"
            return 0
        fi
    fi

    if [ -s "$ocr_err" ]; then
        local err_line
        err_line=$(head -1 "$ocr_err")
        log_message "  ! OCR error: $err_line"
    fi
    rm -f "$ocr_txt" "$ocr_pdf" "$ocr_err" "$decrypted"
    log_message "  ! Failed to process PDF, skipping"
    return 1
}

convert_office_doc() {
    local input="$1" output="$2" doc_type="$3"
    local filename base date temp_html temp_md
    filename=$(basename "$input")
    base="${filename%.*}"
    date=$(stat -c %y "$input" | cut -d' ' -f1)
    log_message "Processing $doc_type: $filename"

    temp_html="$TEMP_DIR/${base}.html"
    temp_md="$TEMP_DIR/${base}.md"

    if libreoffice --headless --convert-to html --outdir "$TEMP_DIR" "$input" &>/dev/null \
            && [ -f "$temp_html" ] \
            && pandoc -f html -t markdown "$temp_html" -o "$temp_md" 2>/dev/null; then
        write_yaml_header "$output" "$filename" "$input" "$doc_type" "$date"
        cat "$temp_md" >> "$output"
        rm -f "$temp_html" "$temp_md"
        log_message "  + Converted $doc_type -> Markdown"
        return 0
    fi

    rm -f "$temp_html" "$temp_md"
    log_message "  ! Failed to convert $doc_type, skipping"
    return 1
}

convert_office_pres() {
    local input="$1" output="$2" doc_type="$3"
    local filename base date temp_html temp_md
    filename=$(basename "$input")
    base="${filename%.*}"
    date=$(stat -c %y "$input" | cut -d' ' -f1)
    log_message "Processing $doc_type: $filename"

    temp_html="$TEMP_DIR/${base}.html"
    temp_md="$TEMP_DIR/${base}.md"

    if libreoffice --headless --convert-to html --outdir "$TEMP_DIR" "$input" &>/dev/null \
            && [ -f "$temp_html" ] \
            && pandoc -f html -t markdown "$temp_html" -o "$temp_md" 2>/dev/null; then
        write_yaml_header "$output" "$filename" "$input" "$doc_type" "$date"
        cat "$temp_md" >> "$output"
        rm -f "$temp_html" "$temp_md"
        log_message "  + Converted $doc_type -> Markdown"
        return 0
    fi

    rm -f "$temp_html" "$temp_md"
    log_message "  ! Failed to convert $doc_type, skipping"
    return 1
}

convert_xlsx() {
    local input="$1" output="$2"
    local filename base date temp_csv
    filename=$(basename "$input")
    base="${filename%.*}"
    date=$(stat -c %y "$input" | cut -d' ' -f1)
    log_message "Processing XLSX: $filename"

    temp_csv="$TEMP_DIR/${base}.csv"
    if libreoffice --headless --convert-to csv --outdir "$TEMP_DIR" "$input" &>/dev/null \
            && [ -f "$temp_csv" ] && [ -s "$temp_csv" ]; then
        write_yaml_header "$output" "$filename" "$input" "XLSX" "$date"
        awk -F',' '
            NR==1 { printf "| "; for(i=1;i<=NF;i++) printf "%s | ",$i; print ""; printf "|"; for(i=1;i<=NF;i++) printf " --- |"; print ""; next }
            { printf "| "; for(i=1;i<=NF;i++) printf "%s | ",$i; print "" }
        ' "$temp_csv" >> "$output"
        rm -f "$temp_csv"
        log_message "  + Converted XLSX -> Markdown table"
        return 0
    fi

    rm -f "$temp_csv"
    log_message "  ! Failed to convert XLSX, skipping"
    return 1
}

convert_txt() {
    local input="$1" output="$2"
    local filename date
    filename=$(basename "$input")
    date=$(stat -c %y "$input" | cut -d' ' -f1)
    log_message "Processing TXT: $filename"
    write_yaml_header "$output" "$filename" "$input" "TXT" "$date"
    cat "$input" >> "$output"
    log_message "  + Converted TXT -> Markdown"
    return 0
}

convert_html() {
    local input="$1" output="$2"
    local filename date temp_md
    filename=$(basename "$input")
    date=$(stat -c %y "$input" | cut -d' ' -f1)
    temp_md="$TEMP_DIR/${filename%.*}.md"
    log_message "Processing HTML: $filename"

    if pandoc -f html -t markdown "$input" -o "$temp_md" 2>/dev/null; then
        write_yaml_header "$output" "$filename" "$input" "HTML" "$date"
        cat "$temp_md" >> "$output"
        rm -f "$temp_md"
        log_message "  + Converted HTML -> Markdown"
        return 0
    fi

    rm -f "$temp_md"
    log_message "  ! Failed to convert HTML, skipping"
    return 1
}

convert_image() {
    local input="$1" output="$2"
    local filename base date ocr_base ocr_txt ocr_langs
    filename=$(basename "$input")
    base="${filename%.*}"
    date=$(stat -c %y "$input" | cut -d' ' -f1)
    log_message "Processing image: $filename"

    ocr_base="$TEMP_DIR/${base}_img_ocr"
    ocr_txt="${ocr_base}.txt"

    ocr_langs="eng"
    tesseract --list-langs 2>/dev/null | grep -q "^ces$" && ocr_langs="ces+eng"

    if tesseract "$input" "$ocr_base" -l "$ocr_langs" 2>/dev/null \
            && [ -f "$ocr_txt" ] && grep -q '[^[:space:]]' "$ocr_txt" 2>/dev/null; then
        write_yaml_header "$output" "$filename" "$input" "Image (OCR)" "$date"
        cat "$ocr_txt" >> "$output"
        rm -f "$ocr_txt"
        log_message "  + Converted image (OCR) -> Markdown"
        return 0
    fi

    rm -f "$ocr_txt"

    # OCR found no text — fall back to EXIF metadata extraction
    if command -v exiftool &>/dev/null; then
        local exif_out
        exif_out=$(exiftool -s "$input" 2>/dev/null)
        if [ -n "$exif_out" ]; then
            # Helper: extract a single tag value from exiftool -s output
            exif_field() { echo "$exif_out" | awk -F': ' -v tag="$1" '$1==tag{sub(/^[[:space:]]+/,"",$2);print $2;exit}'; }

            local date_taken make model gps dims filesize
            date_taken=$(exif_field "DateTimeOriginal")
            [ -z "$date_taken" ] && date_taken=$(exif_field "CreateDate")
            make=$(exif_field "Make")
            model=$(exif_field "Model")
            gps=$(exif_field "GPSPosition")
            dims=$(exif_field "ImageSize")
            filesize=$(exif_field "FileSize")

            # Use EXIF date for YAML header if available (reformat YYYY:MM:DD HH:MM:SS → YYYY-MM-DD)
            local yaml_date="$date"
            if [ -n "$date_taken" ]; then
                yaml_date=$(echo "$date_taken" | sed 's/^\([0-9]\{4\}\):\([0-9]\{2\}\):\([0-9]\{2\}\).*/\1-\2-\3/')
            fi

            write_yaml_header "$output" "$filename" "$input" "Image (metadata)" "$yaml_date"
            {
                echo "## Image Metadata"
                echo ""
                [ -n "$date_taken" ] && echo "- **Date Taken**: $date_taken"
                [ -n "$make" ] || [ -n "$model" ] && echo "- **Camera**: ${make:+$make }${model}"
                [ -n "$gps" ]      && echo "- **GPS Position**: $gps"
                [ -n "$dims" ]     && echo "- **Dimensions**: $dims"
                [ -n "$filesize" ] && echo "- **File Size**: $filesize"
            } >> "$output"
            log_message "  + Extracted image metadata (EXIF) -> Markdown"
            return 0
        fi
    fi

    log_message "  ! No text or metadata extractable from image, skipping"
    return 1
}



echo ""
echo -e "${YELLOW}Step 5: Processing all files in Google Drive...${NC}"
echo ""

if [ "$DRY_RUN" = false ]; then
    log_message "========================================="
    log_message "Starting transformation: $(date)"
    log_message "Source: $GDRIVE_WSL_PATH"
    log_message "Output: $OUTPUT_BASE"
    log_message "========================================="
fi

# IMPORTANT: Use process substitution `< <(find ...)` instead of `find | while read`
# so that counter updates persist in the parent shell (not a throwaway subshell).
while IFS= read -r input_file; do

    TOTAL_FILES=$((TOTAL_FILES + 1))

    ext_lower=$(basename "$input_file" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
    relative_path="${input_file#"$GDRIVE_WSL_PATH/"}"
    output_dir="$OUTPUT_BASE/$(dirname "$relative_path")"
    output_file="$output_dir/$(basename "${input_file%.*}").md"

    if [ "$SKIP_EXISTING" = true ] && [ -f "$output_file" ]; then
        SKIPPED_FILES=$((SKIPPED_FILES + 1))
        [ "$DRY_RUN" = false ] && log_message "  - Skipping (exists): $(basename "$input_file")"
        continue
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY] Would convert: $relative_path"
        CONVERTED_FILES=$((CONVERTED_FILES + 1))
        continue
    fi

    mkdir -p "$output_dir"

    case "$ext_lower" in
        pdf)
            convert_pdf "$input_file" "$output_file" \
                && CONVERTED_FILES=$((CONVERTED_FILES + 1)) || FAILED_FILES=$((FAILED_FILES + 1))
            ;;
        docx|doc|odt)
            convert_office_doc "$input_file" "$output_file" "${ext_lower^^}" \
                && CONVERTED_FILES=$((CONVERTED_FILES + 1)) || FAILED_FILES=$((FAILED_FILES + 1))
            ;;
        pptx|ppt)
            convert_office_pres "$input_file" "$output_file" "${ext_lower^^}" \
                && CONVERTED_FILES=$((CONVERTED_FILES + 1)) || FAILED_FILES=$((FAILED_FILES + 1))
            ;;
        xlsx|xls)
            convert_xlsx "$input_file" "$output_file" \
                && CONVERTED_FILES=$((CONVERTED_FILES + 1)) || FAILED_FILES=$((FAILED_FILES + 1))
            ;;
        txt)
            convert_txt "$input_file" "$output_file" \
                && CONVERTED_FILES=$((CONVERTED_FILES + 1)) || FAILED_FILES=$((FAILED_FILES + 1))
            ;;
        html|htm)
            convert_html "$input_file" "$output_file" \
                && CONVERTED_FILES=$((CONVERTED_FILES + 1)) || FAILED_FILES=$((FAILED_FILES + 1))
            ;;
        jpg|jpeg|png|tif|tiff)
            convert_image "$input_file" "$output_file" \
                && CONVERTED_FILES=$((CONVERTED_FILES + 1)) || FAILED_FILES=$((FAILED_FILES + 1))
            ;;
        *)
            SKIPPED_FILES=$((SKIPPED_FILES + 1))
            ;;
    esac

done < <(find "$GDRIVE_WSL_PATH" -type f \
    ! -name '~$*' \
    \( \
    -iname "*.pdf"  -o -iname "*.docx" -o -iname "*.doc"  \
    -o -iname "*.pptx" -o -iname "*.ppt" -o -iname "*.odt" \
    -o -iname "*.xlsx" -o -iname "*.xls" \
    -o -iname "*.txt"  -o -iname "*.html" -o -iname "*.htm" \
    -o -iname "*.jpg"  -o -iname "*.jpeg" \
    -o -iname "*.png"  -o -iname "*.tif"  -o -iname "*.tiff" \
    \) 2>/dev/null | sort)

# ============================================================================
# STEP 6: Display Summary
# ============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Dry Run Complete${NC}"
else
    echo -e "${GREEN}Transformation Complete!${NC}"
fi
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Statistics:"
echo "  Total files found:              $TOTAL_FILES"
if [ "$DRY_RUN" = true ]; then
    echo -e "  ${GREEN}+ Would convert:                $CONVERTED_FILES${NC}"
else
    echo -e "  ${GREEN}+ Successfully converted:       $CONVERTED_FILES${NC}"
    echo -e "  ${YELLOW}! Failed:                       $FAILED_FILES${NC}"
fi
echo "  - Skipped (unsupported/exists): $SKIPPED_FILES"
echo ""
if [ "$DRY_RUN" = false ]; then
    echo "Output: $OUTPUT_BASE"
    echo "Log:    $LOG_FILE"
    echo ""
    echo "Tip: next run with --skip-existing to update incrementally"
fi
echo -e "${BLUE}========================================${NC}"

if [ "$DRY_RUN" = false ]; then
    log_message "========================================="
    log_message "Transformation complete: $(date)"
    log_message "total=$TOTAL_FILES converted=$CONVERTED_FILES failed=$FAILED_FILES skipped=$SKIPPED_FILES"
    log_message "========================================="
fi