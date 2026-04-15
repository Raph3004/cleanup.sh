#!/bin/bash

set -u

# =========================
# Config
# =========================
LOG_FILE="$HOME/mac_cleanup.log"
DOWNLOADS_DIR="$HOME/Downloads"
PDF_DIR="$HOME/Documents/PDF"
IMAGES_DIR="$HOME/Documents/Images"
ARCHIVES_DIR="$HOME/Documents/Archives"
OLD_DAYS=30
DRY_RUN=false
BEFORE=$(df -h ~ | awk 'NR==2 {print $4}')
AFTER=$(df -h ~ | awk 'NR==2 {print $4}')

# =========================
# Helpers
# =========================
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    log "DRY-RUN: $*"
  else
    eval "$@"
  fi
}

show_usage() {
  echo "Usage: $0 [--dry-run]"
  echo "  --dry-run   Preview actions without changing files"
}

# =========================
# Args
# =========================
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
elif [ "${1:-}" != "" ]; then
  show_usage
  exit 1
fi

# =========================
# Start
# =========================
log "Starting Mac cleanup script"
log "Dry run mode: $DRY_RUN"

# Ensure folders exist
log "Ensuring destination folders exist"
mkdir -p "$PDF_DIR"
mkdir -p "$IMAGES_DIR"
mkdir -p "$ARCHIVES_DIR"

# =========================
# Preview
# =========================
log "Preview of files in Downloads to organize:"
find "$DOWNLOADS_DIR" -maxdepth 1 -type f \( \
  -iname "*.pdf" -o \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.heic" -o \
  -iname "*.zip" -o -iname "*.rar" -o -iname "*.7z" -o -iname "*.tar" -o -iname "*.gz" \
\) -print | tee -a "$LOG_FILE"

# =========================
# Move files safely
# =========================
log "Moving PDF files"
find "$DOWNLOADS_DIR" -maxdepth 1 -type f -iname "*.pdf" -exec mv -n {} "$PDF_DIR"/ \;

log "Moving image files"
find "$DOWNLOADS_DIR" -maxdepth 1 -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.heic" \
\) -exec mv -n {} "$IMAGES_DIR"/ \;

log "Moving archive files"
find "$DOWNLOADS_DIR" -maxdepth 1 -type f \( \
  -iname "*.zip" -o -iname "*.rar" -o -iname "*.7z" -o -iname "*.tar" -o -iname "*.gz" \
\) -exec mv -n {} "$ARCHIVES_DIR"/ \;

# =========================
# Delete old files in Downloads
# =========================
log "Preview old files in Downloads older than $OLD_DAYS days"
find "$DOWNLOADS_DIR" -maxdepth 1 -type f -mtime +"$OLD_DAYS" -print | tee -a "$LOG_FILE"

if [ "$DRY_RUN" = false ]; then
  log "Deleting old files in Downloads older than $OLD_DAYS days"
  find "$DOWNLOADS_DIR" -maxdepth 1 -type f -mtime +"$OLD_DAYS" -delete
else
  log "Skipping deletion because DRY_RUN is enabled"
fi

# =========================
# Clean user cache carefully
# =========================
CACHE_DIR="$HOME/Library/Caches"

if [ -d "$CACHE_DIR" ]; then
  log "Preview cache directories"
  find "$CACHE_DIR" -maxdepth 1 -mindepth 1 -type d -print | tee -a "$LOG_FILE"

  if [ "$DRY_RUN" = false ]; then
    log "Cleaning user cache contents"
    find "$CACHE_DIR" -mindepth 1 -delete 2>/dev/null
  else
    log "Skipping cache cleanup because DRY_RUN is enabled"
  fi
else
  log "Cache directory not found: $CACHE_DIR"
fi


# =========================
# STATS
# =========================
echo "Storage before: $BEFORE"
echo "Storage after: $AFTER"


log "Cleanup complete"
