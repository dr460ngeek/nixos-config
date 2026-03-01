#!/usr/bin/env bash

# NixOS Configuration Recovery Script
#
# Usage:
#   ./nixos-recovery.sh                        → interactive mode (lists backups, pick one)
#   ./nixos-recovery.sh -l                     → list all available backups
#   ./nixos-recovery.sh -r <num>               → restore both files from backup <num>
#   ./nixos-recovery.sh -r <num> -f config     → restore only configuration.nix from backup <num>
#   ./nixos-recovery.sh -r <num> -f hardware   → restore only hardware-configuration.nix from backup <num>
#   ./nixos-recovery.sh -p <num>               → preview/diff backup <num> against current files
#   ./nixos-recovery.sh -d <num>               → delete backup <num>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUPS_DIR="$SCRIPT_DIR/backups"
DEST_CONFIG="/etc/nixos/configuration.nix"
DEST_HARDWARE="/etc/nixos/hardware-configuration.nix"

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Helpers ────────────────────────────────────────────────────────────────────

get_backups() {
    # Returns sorted list of backup dirs (by number prefix)
    ls -d "$BACKUPS_DIR"/[0-9]*_* 2>/dev/null | sort -t'/' -k1 -V
}

print_backups() {
    local backups
    mapfile -t backups < <(get_backups)

    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${YELLOW}No backups found in $BACKUPS_DIR${RESET}"
        exit 0
    fi

    echo -e "${BOLD}Available backups:${RESET}"
    echo -e "──────────────────────────────────────────────────────"
    for dir in "${backups[@]}"; do
        local folder
        folder=$(basename "$dir")
        local num
        num=$(echo "$folder" | grep -oP '^\d+')
        local timestamp
        timestamp=$(echo "$folder" | sed 's/^[0-9]*_//')

        # Check if README exists and extract message preview
        local note=""
        if [ -f "$dir/README.md" ]; then
            local msg
            msg=$(awk '/^```message/{found=1; next} /^```/{found=0} found{print; exit}' "$dir/README.md")
            [ -n "$msg" ] && note=" │ 💬 $msg"
        fi

        echo -e "  ${CYAN}[${num}]${RESET} ${timestamp}${note}"
    done
    echo -e "──────────────────────────────────────────────────────"
}

get_backup_dir_by_num() {
    local num="$1"
    local match
    match=$(ls -d "$BACKUPS_DIR/${num}_"* 2>/dev/null | head -1)
    if [ -z "$match" ]; then
        echo -e "${RED}✗ Error: No backup found with number ${num}${RESET}" >&2
        exit 1
    fi
    echo "$match"
}

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}✗ Error: Restoring files to /etc/nixos requires root. Run with sudo.${RESET}"
        exit 1
    fi
}

safe_restore() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [ ! -f "$src" ]; then
        echo -e "${RED}✗ Error: $src not found in backup${RESET}"
        exit 1
    fi

    # Auto-backup current file before overwriting
    local auto_bak="${dest}.bak_$(date +%H-%M-%S_%d-%m-%Y)"
    if [ -f "$dest" ]; then
        cp "$dest" "$auto_bak"
        echo -e "${YELLOW}  ↩ Auto-saved current ${label} → ${auto_bak}${RESET}"
    fi

    cp "$src" "$dest"
    echo -e "${GREEN}  ✓ Restored: ${label} → ${dest}${RESET}"
}

preview_backup() {
    local num="$1"
    local dir
    dir=$(get_backup_dir_by_num "$num")

    echo -e "${BOLD}Preview of backup [${num}] — $(basename "$dir")${RESET}"
    echo ""

    for pair in "configuration.nix:$DEST_CONFIG" "hardware-configuration.nix:$DEST_HARDWARE"; do
        local bak_file="${dir}/${pair%%:*}"
        local cur_file="${pair##*:}"
        local label="${pair%%:*}"

        echo -e "${CYAN}── diff: ${label} ──────────────────────────────────${RESET}"
        if [ ! -f "$bak_file" ]; then
            echo -e "${RED}  (not present in this backup)${RESET}"
        elif [ ! -f "$cur_file" ]; then
            echo -e "${YELLOW}  (no current file to compare against)${RESET}"
        else
            diff --color=always -u "$cur_file" "$bak_file" || true
        fi
        echo ""
    done
}

restore_backup() {
    local num="$1"
    local file_flag="$2"   # "config", "hardware", or "" (both)
    local dir
    dir=$(get_backup_dir_by_num "$num")

    require_root

    echo -e "${BOLD}Restoring from backup [${num}] — $(basename "$dir")${RESET}"
    echo ""

    case "$file_flag" in
        config)
            safe_restore "$dir/configuration.nix"      "$DEST_CONFIG"   "configuration.nix"
            ;;
        hardware)
            safe_restore "$dir/hardware-configuration.nix" "$DEST_HARDWARE" "hardware-configuration.nix"
            ;;
        "")
            safe_restore "$dir/configuration.nix"          "$DEST_CONFIG"   "configuration.nix"
            safe_restore "$dir/hardware-configuration.nix" "$DEST_HARDWARE" "hardware-configuration.nix"
            ;;
        *)
            echo -e "${RED}✗ Unknown -f value '${file_flag}'. Use 'config' or 'hardware'.${RESET}"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}Recovery complete!${RESET}"
    echo -e "  Run ${BOLD}sudo nixos-rebuild switch${RESET} to apply the restored configuration."
}

delete_backup() {
    local num="$1"
    local dir
    dir=$(get_backup_dir_by_num "$num")

    echo -e "${YELLOW}About to delete backup [${num}]: $(basename "$dir")${RESET}"
    read -rp "Are you sure? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$dir"
        echo -e "${GREEN}✓ Deleted backup [${num}]${RESET}"
    else
        echo "Aborted."
    fi
}

interactive_mode() {
    print_backups

    echo ""
    read -rp "Enter backup number to restore (or 'q' to quit): " choice
    [[ "$choice" == "q" || -z "$choice" ]] && exit 0

    echo ""
    echo -e "What would you like to restore?"
    echo -e "  ${CYAN}[1]${RESET} Both files"
    echo -e "  ${CYAN}[2]${RESET} configuration.nix only"
    echo -e "  ${CYAN}[3]${RESET} hardware-configuration.nix only"
    echo -e "  ${CYAN}[4]${RESET} Preview diff first"
    read -rp "Choice [1-4]: " action

    case "$action" in
        1) restore_backup "$choice" "" ;;
        2) restore_backup "$choice" "config" ;;
        3) restore_backup "$choice" "hardware" ;;
        4) preview_backup "$choice" ;;
        *) echo "Invalid choice. Aborted." ; exit 1 ;;
    esac
}

# ── Argument parsing ───────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
    interactive_mode
    exit 0
fi

MODE=""
BACKUP_NUM=""
FILE_FLAG=""

while getopts ":lr:f:p:d:" opt; do
    case $opt in
        l) MODE="list" ;;
        r) MODE="restore"; BACKUP_NUM="$OPTARG" ;;
        f) FILE_FLAG="$OPTARG" ;;
        p) MODE="preview"; BACKUP_NUM="$OPTARG" ;;
        d) MODE="delete"; BACKUP_NUM="$OPTARG" ;;
        :) echo -e "${RED}✗ Option -${OPTARG} requires an argument.${RESET}"; exit 1 ;;
        *) 
            echo "Usage:"
            echo "  $0                        → interactive mode"
            echo "  $0 -l                     → list backups"
            echo "  $0 -r <num>               → restore both files"
            echo "  $0 -r <num> -f config     → restore configuration.nix only"
            echo "  $0 -r <num> -f hardware   → restore hardware-configuration.nix only"
            echo "  $0 -p <num>               → preview diff"
            echo "  $0 -d <num>               → delete backup"
            exit 1
            ;;
    esac
done

case "$MODE" in
    list)    print_backups ;;
    restore) restore_backup "$BACKUP_NUM" "$FILE_FLAG" ;;
    preview) preview_backup "$BACKUP_NUM" ;;
    delete)  delete_backup  "$BACKUP_NUM" ;;
esac
