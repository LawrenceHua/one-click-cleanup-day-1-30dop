#!/bin/bash

# =============================================================================
# macOS Cache Cleanup Script v2.0
# Safe cache cleaning for any Mac (Intel or Apple Silicon)
# Double-click to run, or use --auto flag for automatic mode
# =============================================================================
#
# USAGE:
#   Double-click         Interactive mode with confirmation prompt
#   ./Clean\ Cache.command --auto    Automatic mode (no confirmation)
#   ./Clean\ Cache.command --yes     Same as --auto
#   ./Clean\ Cache.command -y        Same as --auto
#
# FIRST TIME RUNNING?
#   If macOS blocks this script with "unidentified developer":
#   1. Right-click the file → Open → Open
#   OR
#   2. System Settings → Privacy & Security → Click "Open Anyway"
#
# =============================================================================

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# =============================================================================
# Parse command line arguments
# =============================================================================

AUTO_MODE=false
for arg in "$@"; do
    case $arg in
        --auto|--yes|-y)
            AUTO_MODE=true
            shift
            ;;
        --help|-h)
            echo "macOS Cache Cleanup Script"
            echo ""
            echo "Usage: ./Clean Cache.command [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto, --yes, -y    Run without confirmation prompt"
            echo "  --help, -h           Show this help message"
            echo ""
            exit 0
            ;;
    esac
done

# Change to user's home directory
cd ~ || exit 1

# =============================================================================
# Helper Functions
# =============================================================================

# Calculate directory size in human-readable format
get_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Calculate directory size in kilobytes
get_size_bytes() {
    if [ -d "$1" ]; then
        du -sk "$1" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# Count files in a directory
count_files() {
    if [ -d "$1" ]; then
        find "$1" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Count subdirectories in a directory
count_dirs() {
    if [ -d "$1" ]; then
        find "$1" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Format bytes to human readable
format_size() {
    local bytes=$1
    if [ "$bytes" -gt 1073741824 ]; then
        echo "$((bytes / 1048576))G"
    elif [ "$bytes" -gt 1048576 ]; then
        echo "$((bytes / 1024))M"
    elif [ "$bytes" -gt 1024 ]; then
        echo "${bytes}K"
    else
        echo "${bytes}B"
    fi
}

# Progress spinner
spin() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

# =============================================================================
# System Detection
# =============================================================================

# Get macOS version
MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
MACOS_NAME=$(sw_vers -productName 2>/dev/null || echo "macOS")
MACOS_BUILD=$(sw_vers -buildVersion 2>/dev/null || echo "")

# Get chip type
CHIP_TYPE=$(uname -m)
if [ "$CHIP_TYPE" = "arm64" ]; then
    CHIP_DISPLAY="Apple Silicon"
    # Try to get specific chip
    CHIP_DETAIL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "")
    if [[ "$CHIP_DETAIL" == *"M1"* ]]; then
        CHIP_DISPLAY="Apple M1"
    elif [[ "$CHIP_DETAIL" == *"M2"* ]]; then
        CHIP_DISPLAY="Apple M2"
    elif [[ "$CHIP_DETAIL" == *"M3"* ]]; then
        CHIP_DISPLAY="Apple M3"
    elif [[ "$CHIP_DETAIL" == *"M4"* ]]; then
        CHIP_DISPLAY="Apple M4"
    fi
else
    CHIP_DISPLAY="Intel"
fi

# Get Mac model
MAC_MODEL=$(sysctl -n hw.model 2>/dev/null || echo "Mac")

# =============================================================================
# Display Header
# =============================================================================

clear
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}${BOLD}                  macOS Cache Cleanup Utility v2.0                  ${NC}${CYAN}║${NC}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${DIM}System:${NC} ${MACOS_NAME} ${MACOS_VERSION} (${MACOS_BUILD})                              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${DIM}Chip:${NC}   ${CHIP_DISPLAY} (${CHIP_TYPE})                                      ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${DIM}Model:${NC}  ${MAC_MODEL}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$AUTO_MODE" = true ]; then
    echo -e "${MAGENTA}[AUTOMATIC MODE]${NC} Running without confirmation prompt"
    echo ""
fi

# =============================================================================
# First-run Gatekeeper Instructions
# =============================================================================

# Check if this might be a blocked execution (script path check)
SCRIPT_PATH="$0"
if [[ "$SCRIPT_PATH" == *"quarantine"* ]] || [[ ! -x "$SCRIPT_PATH" ]]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}FIRST TIME RUNNING?${NC}"
    echo -e "If macOS blocked this script, here's how to allow it:"
    echo -e "  1. Right-click the file and select 'Open'"
    echo -e "  2. Click 'Open' in the dialog that appears"
    echo -e "  OR go to System Settings → Privacy & Security → Open Anyway"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

# =============================================================================
# Define Cache Locations
# =============================================================================

USER_CACHE="$HOME/Library/Caches"
SYSTEM_CACHE="/Library/Caches"
USER_LOGS="$HOME/Library/Logs"
SYSTEM_LOGS="/Library/Logs"
TMP_DIR="/private/tmp"
USER_CRASH="$HOME/Library/Application Support/CrashReporter"
USER_SAVED_STATE="$HOME/Library/Saved Application State"

# =============================================================================
# Analyze Cache Directories
# =============================================================================

echo -e "${BLUE}Analyzing cache directories...${NC}"
echo -e "${DIM}(This may take a moment for large caches)${NC}"
echo ""

# User caches
echo -ne "  Scanning user caches...      \r"
USER_CACHE_SIZE=$(get_size "$USER_CACHE")
USER_CACHE_BYTES=$(get_size_bytes "$USER_CACHE")
USER_CACHE_FILES=$(count_files "$USER_CACHE")
USER_CACHE_DIRS=$(count_dirs "$USER_CACHE")

# System caches
echo -ne "  Scanning system caches...    \r"
SYSTEM_CACHE_SIZE=$(get_size "$SYSTEM_CACHE")
SYSTEM_CACHE_BYTES=$(get_size_bytes "$SYSTEM_CACHE")
SYSTEM_CACHE_FILES=$(count_files "$SYSTEM_CACHE")

# User logs
echo -ne "  Scanning user logs...        \r"
USER_LOGS_SIZE=$(get_size "$USER_LOGS")
USER_LOGS_BYTES=$(get_size_bytes "$USER_LOGS")
USER_LOGS_FILES=$(count_files "$USER_LOGS")

# Count old logs (7+ days)
OLD_LOGS_COUNT=$(find "$USER_LOGS" -type f -mtime +7 2>/dev/null | wc -l | tr -d ' ')

# Temp files
echo -ne "  Scanning temp files...       \r"
TMP_SIZE=$(get_size "$TMP_DIR")
TMP_BYTES=$(get_size_bytes "$TMP_DIR")
TMP_FILES=$(count_files "$TMP_DIR")

# Crash reports
echo -ne "  Scanning crash reports...    \r"
USER_CRASH_SIZE=$(get_size "$USER_CRASH")
USER_CRASH_BYTES=$(get_size_bytes "$USER_CRASH")
USER_CRASH_FILES=$(count_files "$USER_CRASH")

# Saved application state
echo -ne "  Scanning saved states...     \r"
USER_SAVED_SIZE=$(get_size "$USER_SAVED_STATE")
USER_SAVED_BYTES=$(get_size_bytes "$USER_SAVED_STATE")
USER_SAVED_DIRS=$(count_dirs "$USER_SAVED_STATE")

echo -e "  Analysis complete!           "
echo ""

# Calculate total
TOTAL_BYTES=$((USER_CACHE_BYTES + SYSTEM_CACHE_BYTES + USER_LOGS_BYTES + TMP_BYTES + USER_CRASH_BYTES + USER_SAVED_BYTES))
TOTAL_SIZE=$(format_size "$TOTAL_BYTES")

# =============================================================================
# Display Detailed Summary
# =============================================================================

echo -e "${YELLOW}┌──────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│${NC}${BOLD}                         CLEANUP SUMMARY                              ${NC}${YELLOW}│${NC}"
echo -e "${YELLOW}├──────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${YELLOW}│${NC}                                                                      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  ${BOLD}1. User Caches${NC}          ${GREEN}${USER_CACHE_SIZE}${NC} (${USER_CACHE_FILES} files in ${USER_CACHE_DIRS} apps)       ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}~/Library/Caches${NC}                                                ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}Temporary data stored by apps. Safe to delete - apps rebuild.${NC}  ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}                                                                      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  ${BOLD}2. System Caches${NC}        ${GREEN}${SYSTEM_CACHE_SIZE}${NC} (${SYSTEM_CACHE_FILES} files)                       ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}/Library/Caches${NC}                                                 ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}System-wide cache. Requires admin password. macOS rebuilds.${NC}    ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}                                                                      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  ${BOLD}3. Old Log Files${NC}        ${GREEN}${USER_LOGS_SIZE}${NC} (${OLD_LOGS_COUNT} files older than 7 days)       ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}~/Library/Logs${NC}                                                  ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}Diagnostic logs. Only removes files 7+ days old for safety.${NC}    ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}                                                                      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  ${BOLD}4. Temp Files${NC}           ${GREEN}${TMP_SIZE}${NC} (${TMP_FILES} files)                           ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}/private/tmp${NC}                                                    ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}Temporary system files. Automatically cleared on reboot.${NC}       ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}                                                                      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  ${BOLD}5. Crash Reports${NC}        ${GREEN}${USER_CRASH_SIZE}${NC} (${USER_CRASH_FILES} reports)                        ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}~/Library/.../CrashReporter${NC}                                     ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}App crash logs. Only useful for debugging, safe to delete.${NC}     ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}                                                                      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  ${BOLD}6. Saved App States${NC}     ${GREEN}${USER_SAVED_SIZE}${NC} (${USER_SAVED_DIRS} apps)                          ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}~/Library/Saved Application State${NC}                               ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}     ${DIM}Window positions/states. Apps may not restore last state.${NC}      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}                                                                      ${YELLOW}│${NC}"
echo -e "${YELLOW}├──────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${YELLOW}│${NC}  ${BOLD}ESTIMATED TOTAL TO CLEAN:${NC}                    ${GREEN}~${TOTAL_SIZE}${NC}               ${YELLOW}│${NC}"
echo -e "${YELLOW}└──────────────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${CYAN}Additional actions:${NC}"
echo -e "  ${DIM}+${NC} DNS cache flush (resolves some network issues)"
echo -e "  ${DIM}+${NC} Inactive memory purge (frees up RAM)"
echo ""

echo -e "${RED}Protected (will NOT be touched):${NC}"
echo -e "  ${DIM}-${NC} Browser caches: Chrome, Safari, Firefox, Brave, Edge, Opera, Atlas"
echo -e "  ${DIM}-${NC} Application data and preferences"
echo -e "  ${DIM}-${NC} Recent log files (less than 7 days old)"
echo ""

# =============================================================================
# Confirmation Prompt (unless auto mode)
# =============================================================================

if [ "$AUTO_MODE" = true ]; then
    echo -e "${MAGENTA}[AUTO MODE]${NC} Proceeding with cleanup automatically..."
    echo ""
else
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Press ENTER to proceed with cleanup, or 'c' to cancel:${NC} "
    read -r response
    if [[ "$response" == "c" || "$response" == "C" ]]; then
        echo ""
        echo -e "${YELLOW}Cleanup cancelled. No files were deleted.${NC}"
        echo ""
        echo "Press any key to close..."
        read -n 1
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}                         STARTING CLEANUP                             ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# =============================================================================
# Perform Cleanup
# =============================================================================

# Track statistics
cleaned_items=0
cleaned_files=0
skipped_browsers=0
failed_items=0

# -----------------------------------------------------------------------------
# Step 1: Clean user caches (skip browser caches)
# -----------------------------------------------------------------------------

echo -e "${CYAN}[Step 1/6]${NC} ${BOLD}Cleaning user caches...${NC}"
echo -e "${DIM}           Skipping browser-related caches as requested${NC}"
echo ""

if [ -d "$USER_CACHE" ]; then
    app_count=0
    for dir in "$USER_CACHE"/*; do
        if [ -d "$dir" ]; then
            dirname=$(basename "$dir")
            dir_size=$(get_size "$dir")
            dir_files=$(count_files "$dir")
            
            # Skip browser caches
            case "$dirname" in
                *Google*|*Chrome*|*Firefox*|*Safari*|*Brave*|*Edge*|*Opera*|*Atlas*|*WebKit*)
                    echo -e "  ${YELLOW}SKIP${NC}    $dirname ${DIM}(browser - protected)${NC}"
                    ((skipped_browsers++))
                    ;;
                *)
                    if rm -rf "$dir" 2>/dev/null; then
                        echo -e "  ${GREEN}CLEAN${NC}   $dirname ${DIM}($dir_size, $dir_files files)${NC}"
                        ((cleaned_items++))
                        ((cleaned_files += dir_files))
                        ((app_count++))
                    else
                        echo -e "  ${RED}FAIL${NC}    $dirname ${DIM}(permission denied)${NC}"
                        ((failed_items++))
                    fi
                    ;;
            esac
        fi
    done
    echo ""
    echo -e "  ${DIM}Cleaned $app_count app caches, skipped $skipped_browsers browser caches${NC}"
else
    echo -e "  ${YELLOW}Directory not found${NC}"
fi

# -----------------------------------------------------------------------------
# Step 2: Clean old user logs
# -----------------------------------------------------------------------------

echo ""
echo -e "${CYAN}[Step 2/6]${NC} ${BOLD}Cleaning old log files...${NC}"
echo -e "${DIM}           Only removing files older than 7 days${NC}"
echo ""

if [ -d "$USER_LOGS" ]; then
    old_log_count=$(find "$USER_LOGS" -type f -mtime +7 2>/dev/null | wc -l | tr -d ' ')
    if [ "$old_log_count" -gt 0 ]; then
        find "$USER_LOGS" -type f -mtime +7 -delete 2>/dev/null
        echo -e "  ${GREEN}CLEAN${NC}   Removed $old_log_count old log files"
        ((cleaned_items++))
        ((cleaned_files += old_log_count))
    else
        echo -e "  ${DIM}No log files older than 7 days found${NC}"
    fi
else
    echo -e "  ${YELLOW}Directory not found: $USER_LOGS${NC}"
fi

# -----------------------------------------------------------------------------
# Step 3: Clean crash reports
# -----------------------------------------------------------------------------

echo ""
echo -e "${CYAN}[Step 3/6]${NC} ${BOLD}Cleaning crash reports...${NC}"
echo -e "${DIM}           Removing app crash diagnostics${NC}"
echo ""

if [ -d "$USER_CRASH" ]; then
    crash_count=$(count_files "$USER_CRASH")
    if [ "$crash_count" -gt 0 ]; then
        rm -rf "$USER_CRASH"/* 2>/dev/null
        echo -e "  ${GREEN}CLEAN${NC}   Removed $crash_count crash reports"
        ((cleaned_items++))
        ((cleaned_files += crash_count))
    else
        echo -e "  ${DIM}No crash reports found${NC}"
    fi
else
    echo -e "  ${DIM}No crash reports directory found${NC}"
fi

# -----------------------------------------------------------------------------
# Step 4: Clean saved application state
# -----------------------------------------------------------------------------

echo ""
echo -e "${CYAN}[Step 4/6]${NC} ${BOLD}Cleaning saved application states...${NC}"
echo -e "${DIM}           Window positions and states (apps will reset to defaults)${NC}"
echo ""

if [ -d "$USER_SAVED_STATE" ]; then
    state_count=$(count_dirs "$USER_SAVED_STATE")
    if [ "$state_count" -gt 0 ]; then
        rm -rf "$USER_SAVED_STATE"/* 2>/dev/null
        echo -e "  ${GREEN}CLEAN${NC}   Cleared saved states for $state_count apps"
        ((cleaned_items++))
    else
        echo -e "  ${DIM}No saved states found${NC}"
    fi
else
    echo -e "  ${DIM}No saved states directory found${NC}"
fi

# -----------------------------------------------------------------------------
# Step 5: Clean system caches (requires sudo)
# -----------------------------------------------------------------------------

echo ""
echo -e "${CYAN}[Step 5/6]${NC} ${BOLD}Cleaning system caches...${NC}"
echo -e "${DIM}           Requires administrator password${NC}"
echo ""

# Request sudo access
echo -e "  ${DIM}Requesting administrator access...${NC}"
if sudo -v 2>/dev/null; then
    echo -e "  ${GREEN}OK${NC}      Administrator access granted"
    echo ""
    
    # Clean system caches
    if [ -d "$SYSTEM_CACHE" ]; then
        sys_cache_count=$(find "$SYSTEM_CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        sudo find "$SYSTEM_CACHE" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \; 2>/dev/null
        echo -e "  ${GREEN}CLEAN${NC}   System caches ($sys_cache_count directories)"
        ((cleaned_items++))
    fi
    
    # Clean system temp files
    if [ -d "$TMP_DIR" ]; then
        tmp_count=$(count_files "$TMP_DIR")
        sudo rm -rf /private/tmp/* 2>/dev/null
        echo -e "  ${GREEN}CLEAN${NC}   System temp files ($tmp_count files)"
        ((cleaned_items++))
        ((cleaned_files += tmp_count))
    fi
    
    # Flush DNS cache
    echo -e "  ${DIM}Flushing DNS cache...${NC}"
    sudo dscacheutil -flushcache 2>/dev/null
    sudo killall -HUP mDNSResponder 2>/dev/null
    echo -e "  ${GREEN}FLUSH${NC}   DNS cache cleared"
    
    # Purge inactive memory
    echo -e "  ${DIM}Purging inactive memory...${NC}"
    sudo purge 2>/dev/null
    echo -e "  ${GREEN}PURGE${NC}   Inactive memory freed"
    
else
    echo -e "  ${YELLOW}SKIP${NC}    System caches (sudo authentication failed or cancelled)"
    echo -e "  ${DIM}User-level cleanup was still completed successfully${NC}"
    ((failed_items++))
fi

# -----------------------------------------------------------------------------
# Step 6: Additional cleanup
# -----------------------------------------------------------------------------

echo ""
echo -e "${CYAN}[Step 6/6]${NC} ${BOLD}Finalizing...${NC}"
echo ""

# Clear Finder Recent Items (optional, doesn't need sudo)
if [ -f "$HOME/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.RecentDocuments.sfl2" ]; then
    echo -e "  ${DIM}Recent items list location found${NC}"
fi

echo -e "  ${GREEN}DONE${NC}    Cleanup operations complete"

# =============================================================================
# Calculate Results
# =============================================================================

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}${BOLD}                       CLEANUP COMPLETE!                              ${NC}${GREEN}║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════╣${NC}"

# Calculate new sizes
NEW_USER_CACHE_BYTES=$(get_size_bytes "$USER_CACHE")
NEW_SYSTEM_CACHE_BYTES=$(get_size_bytes "$SYSTEM_CACHE")
NEW_TOTAL_BYTES=$((NEW_USER_CACHE_BYTES + NEW_SYSTEM_CACHE_BYTES))
FREED_BYTES=$((TOTAL_BYTES - NEW_TOTAL_BYTES))

# Handle negative (shouldn't happen, but just in case)
if [ "$FREED_BYTES" -lt 0 ]; then
    FREED_BYTES=0
fi

FREED_SIZE=$(format_size "$FREED_BYTES")

echo -e "${GREEN}║${NC}                                                                      ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Space Freed:${NC}           ${GREEN}~${FREED_SIZE}${NC}                                       ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Items Processed:${NC}       ${cleaned_items} cache locations                        ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Files Removed:${NC}         ~${cleaned_files} files                                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Browsers Protected:${NC}    ${skipped_browsers} browser caches skipped                  ${GREEN}║${NC}"
if [ "$failed_items" -gt 0 ]; then
echo -e "${GREEN}║${NC}  ${YELLOW}Skipped/Failed:${NC}        ${failed_items} items (permission issues)               ${GREEN}║${NC}"
fi
echo -e "${GREEN}║${NC}                                                                      ${GREEN}║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}  ${CYAN}TIP:${NC} Restart your Mac for the best results after cache cleanup.    ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${CYAN}TIP:${NC} Run this monthly to keep your Mac running smoothly.           ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$AUTO_MODE" = true ]; then
    echo -e "${MAGENTA}[AUTO MODE]${NC} Cleanup finished. Exiting in 5 seconds..."
    sleep 5
else
    echo -e "${YELLOW}Press any key to close...${NC}"
    read -n 1
fi

exit 0
