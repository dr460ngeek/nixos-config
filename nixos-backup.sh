#!/usr/bin/env bash

# NixOS Configuration Backup Script
# Usage:
#   ./nixos-backup.sh              → backs up into ./backups/<num>_<timestamp>/
#   ./nixos-backup.sh -m "msg"     → backs up into ./backups/<num>_<timestamp>/ with README.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUPS_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +"%H-%M-%S_%d-%m-%Y")
MESSAGE=""

# Parse flags
while getopts "m:" opt; do
    case $opt in
        m) MESSAGE="$OPTARG" ;;
        *) echo "Usage: $0 [-m \"message\"]"; exit 1 ;;
    esac
done

SRC_CONFIG="/etc/nixos/configuration.nix"
SRC_HARDWARE="/etc/nixos/hardware-configuration.nix"

# Validate sources exist before doing anything
if [ ! -f "$SRC_CONFIG" ]; then
    echo "✗ Error: $SRC_CONFIG not found"
    exit 1
fi
if [ ! -f "$SRC_HARDWARE" ]; then
    echo "✗ Error: $SRC_HARDWARE not found"
    exit 1
fi

# Create ./backups if it doesn't exist
mkdir -p "$BACKUPS_DIR"

# Determine next backup number from existing numbered folders inside ./backups
LAST=$(ls -d "$BACKUPS_DIR"/[0-9]*_* 2>/dev/null | grep -oP '(?<=\/)\d+(?=_)' | sort -n | tail -1)
NEXT=$(( ${LAST:-0} + 1 ))

BACKUP_DIR="$BACKUPS_DIR/${NEXT}_${TIMESTAMP}"

mkdir -p "$BACKUP_DIR"

cp "$SRC_CONFIG"   "$BACKUP_DIR/configuration.nix"
cp "$SRC_HARDWARE" "$BACKUP_DIR/hardware-configuration.nix"

echo "✓ Backed up: configuration.nix          → $BACKUP_DIR/configuration.nix"
echo "✓ Backed up: hardware-configuration.nix → $BACKUP_DIR/hardware-configuration.nix"

if [ -n "$MESSAGE" ]; then
    cat > "$BACKUP_DIR/README.md" <<EOF
# Backup Notes

\`\`\`message
$MESSAGE
\`\`\`
EOF
    echo "✓ Created:   README.md                  → $BACKUP_DIR/README.md"
fi

echo ""
echo "Backup complete! Folder: $BACKUP_DIR"
