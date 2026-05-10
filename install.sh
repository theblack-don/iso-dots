#!/usr/bin/env bash
###############################################################################
# iNiR Supporter Installation Script
# Installs iNiR shell + equibop, obsidian, helium-browser
# Preserves existing niri config (keybinds, monitors, etc.)
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }

# Abort on error with message
trap 'error "Script failed at line $LINENO. Check backup at: $BACKUP_DIR" && exit 1' ERR

# Script directory (for logo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup directory
BACKUP_DIR="$HOME/.config-backup-inir-$(date +%Y%m%d%H%M%S)"

###############################################################################
# Step 1: Detect Arch-based distro
###############################################################################
check_arch() {
    info "Checking if running on Arch-based distro..."

    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi

    source /etc/os-release

    # Check ID or ID_LIKE for arch
    if [[ "${ID,,}" == "arch" ]] || [[ "${ID_LIKE,,}" == *"arch"* ]]; then
        success "Arch-based distro detected: ${PRETTY_NAME}"
    else
        error "This script only supports Arch-based distros. Detected: ${PRETTY_NAME}"
        exit 1
    fi
}

###############################################################################
# Step 2: Check/install AUR helper
###############################################################################
setup_aur_helper() {
    info "Checking for AUR helper..."

    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
        success "Found paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
        success "Found yay"
    else
        warn "No AUR helper found. Installing yay..."

        # Install base-devel and git if missing
        if ! command -v makepkg &>/dev/null; then
            info "Installing base-devel and git..."
            sudo pacman -S --needed --noconfirm base-devel git
        fi

        # Build yay from AUR
        local tmpdir
        tmpdir=$(mktemp -d)
        cd "$tmpdir"

        info "Cloning yay AUR package..."
        git clone https://aur.archlinux.org/yay.git
        cd yay

        info "Building and installing yay..."
        makepkg -si --noconfirm

        cd "$HOME"
        rm -rf "$tmpdir"

        AUR_HELPER="yay"
        success "yay installed successfully"
    fi

    export AUR_HELPER
}

###############################################################################
# Step 3: Backup existing configs
###############################################################################
backup_configs() {
    info "Creating config backup..."

    mkdir -p "$BACKUP_DIR"

    # List of configs iNiR may overwrite
    local configs=(
        "niri"
        "fish"
        "kitty"
        "foot"
        "gtk-3.0"
        "gtk-4.0"
        "fuzzel"
        "mpv"
        "vesktop"
        "Kvantum"
        "fontconfig"
        "matugen"
        "xdg-desktop-portal"
        "kdeglobals"
        "darklyrc"
        "dolphinrc"
        "konsolerc"
        "kservicemenurc"
        "chrome-flags.conf"
        "code-flags.conf"
    )

    local backed_up=0

    for config in "${configs[@]}"; do
        local src="$HOME/.config/$config"
        if [[ -e "$src" ]]; then
            local dest="$BACKUP_DIR/$config"
            cp -r "$src" "$dest"
            info "Backed up: $config"
            ((backed_up++))
        fi
    done

    if [[ $backed_up -eq 0 ]]; then
        warn "No existing configs found to backup"
    else
        success "Backed up $backed_up config(s) to: $BACKUP_DIR"
    fi
}

###############################################################################
# Step 4: Clone & install iNiR
###############################################################################
install_inir() {
    info "Installing iNiR dotfiles..."

    local inir_dir="$HOME/.config/quickshell/inir"

    # Check if already installed
    if [[ -d "$inir_dir/.git" ]]; then
        warn "iNiR already installed at $inir_dir"
        info "Updating existing installation..."
        cd "$inir_dir"
        git pull
    else
        # Create parent directory if needed
        mkdir -p "$(dirname "$inir_dir")"

        info "Cloning iNiR repository..."
        git clone https://github.com/snowarch/inir.git "$inir_dir"
        cd "$inir_dir"
    fi

    info "Running iNiR setup (this may take a while)..."
    ./setup install -y

    success "iNiR installed successfully"
}

###############################################################################
# Step 5: Restore user's niri config
###############################################################################
restore_niri_config() {
    info "Checking for backed up niri config..."

    local backup_niri="$BACKUP_DIR/niri"
    local target_niri="$HOME/.config/niri"

    if [[ -d "$backup_niri" ]]; then
        info "Restoring original niri config..."

        # Remove iNiR's niri config
        rm -rf "$target_niri"

        # Restore user's original config
        cp -r "$backup_niri" "$target_niri"

        success "Original niri config restored"
        warn "You may need to manually add iNiR bindings to your niri config"
    else
        info "No previous niri config found. Keeping iNiR defaults."
    fi
}

###############################################################################
# Step 6: Install AUR packages
###############################################################################
install_aur_packages() {
    info "Installing additional packages from AUR..."

    local packages=(
        "equibop-bin"
        "obsidian-bin"
        "helium-browser-bin"
    )

    for pkg in "${packages[@]}"; do
        # Check if already installed
        if pacman -Q "$pkg" &>/dev/null; then
            info "$pkg is already installed, skipping..."
        else
            info "Installing $pkg..."
            $AUR_HELPER -S --needed --noconfirm "$pkg"
            success "$pkg installed"
        fi
    done
}

###############################################################################
# Step 7: Configure fastfetch with custom logo
###############################################################################
setup_fastfetch_logo() {
    info "Configuring fastfetch with custom logo..."

    # Install fastfetch and chafa if not present
    if ! command -v fastfetch &>/dev/null; then
        info "Installing fastfetch..."
        sudo pacman -S --needed --noconfirm fastfetch
        success "fastfetch installed"
    fi

    if ! command -v chafa &>/dev/null; then
        info "Installing chafa..."
        sudo pacman -S --needed --noconfirm chafa
        success "chafa installed"
    fi

    # Setup fastfetch config directory
    local ff_dir="$HOME/.config/fastfetch"
    mkdir -p "$ff_dir"

    # Copy logo
    local logo_src="$SCRIPT_DIR/29bb8e2b9d99779be8d686873c8acbf4.png"
    local logo_dest="$ff_dir/logo.png"

    if [[ ! -f "$logo_src" ]]; then
        error "Logo file not found at: $logo_src"
        exit 1
    fi

    cp "$logo_src" "$logo_dest"
    info "Logo copied to: $logo_dest"

    # Update fastfetch config
    local ff_config="$ff_dir/config.jsonc"

    if [[ -f "$ff_config" ]]; then
        info "Updating existing fastfetch config..."

        # Use python3 to safely update JSONC
        python3 << 'PYTHON_SCRIPT'
import json
import re
import sys
from pathlib import Path

config_path = Path.home() / ".config" / "fastfetch" / "config.jsonc"

if not config_path.exists():
    print("Config file not found", file=sys.stderr)
    sys.exit(1)

# Read original content
with open(config_path, 'r') as f:
    original = f.read()

# Strip comments for JSON parsing (only line-starting comments to avoid breaking URLs)
def strip_jsonc(text):
    # Remove single-line comments (only at start of line, after optional whitespace)
    text = re.sub(r'^\s*//[^\n]*', '', text, flags=re.MULTILINE)
    # Remove multi-line comments
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    # Replace tabs with spaces (JSON doesn't allow tabs)
    text = text.replace('\t', '    ')
    # Remove trailing commas before } or ]
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return text

clean = strip_jsonc(original)

try:
    config = json.loads(clean)
except json.JSONDecodeError as e:
    print(f"Failed to parse config: {e}", file=sys.stderr)
    sys.exit(1)

# Update logo section
config['logo'] = {
    'source': '$HOME/.config/fastfetch/logo.png',
    'type': 'chafa'
}

# Write back
with open(config_path, 'w') as f:
    json.dump(config, f, indent=4)

print("Fastfetch config updated successfully")
PYTHON_SCRIPT

        success "Fastfetch config updated"
    else
        # Create new config
        info "Creating new fastfetch config..."
        cat > "$ff_config" << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "$HOME/.config/fastfetch/logo.png",
        "type": "chafa"
    },
    "display": {
        "separator": " "
    },
    "modules": [
        "break",
        {
            "type": "title",
            "keyWidth": 10
        },
        "break",
        {
            "type": "os",
            "key": "OS ",
            "keyColor": "34"
        },
        {
            "type": "kernel",
            "key": "Kernel ",
            "keyColor": "34"
        },
        {
            "type": "uptime",
            "key": "Uptime ",
            "keyColor": "34"
        },
        {
            "type": "packages",
            "key": "Packages ",
            "keyColor": "34"
        },
        {
            "type": "shell",
            "key": "Shell ",
            "keyColor": "34"
        },
        {
            "type": "wm",
            "key": "WM ",
            "keyColor": "34"
        },
        {
            "type": "terminal",
            "key": "Terminal ",
            "keyColor": "34"
        },
        "break"
    ]
}
EOF
        success "Fastfetch config created"
    fi
}

###############################################################################
# Step 8: Final instructions
###############################################################################
print_final_instructions() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}Installation Complete!${NC}                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}IMPORTANT: Add iNiR startup to your niri config${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "To auto-start the iNiR shell, add this line to your niri config:"
    echo -e "  ${GREEN}~/.config/niri/config.kdl${NC}"
    echo ""
    echo -e "  ${CYAN}spawn-at-startup \"inir\" \"run\"${NC}"
    echo ""
    echo -e "Then reload your niri config:"
    echo -e "  ${CYAN}niri msg action load-config-file${NC}"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Backup Information${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Your original configs are backed up at:"
    echo -e "  ${GREEN}${BACKUP_DIR}${NC}"
    echo ""
    echo -e "To restore any config manually:"
    echo -e "  ${CYAN}cp -r ${BACKUP_DIR}/<config-name> ~/.config/${NC}"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Installed Packages${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  • ${GREEN}iNiR${NC} - Niri desktop shell"
    echo -e "  • ${GREEN}equibop${NC} - Discord with Equicord"
    echo -e "  • ${GREEN}obsidian${NC} - Knowledge base / notes"
    echo -e "  • ${GREEN}helium-browser${NC} - Privacy-focused web browser"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}iNiR Quick Start${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Start shell manually:  ${CYAN}inir run${NC}"
    echo -e "  Open settings:         ${CYAN}inir settings${NC}"
    echo -e "  Check logs:            ${CYAN}inir logs${NC}"
    echo -e "  Run diagnostics:       ${CYAN}inir doctor${NC}"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Keybinds (after adding iNiR startup)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}Super+Space${NC}    - Overview / app search"
    echo -e "  ${CYAN}Alt+Tab${NC}        - Window switcher"
    echo -e "  ${CYAN}Super+V${NC}        - Clipboard history"
    echo -e "  ${CYAN}Super+Shift+S${NC}  - Screenshot region"
    echo -e "  ${CYAN}Super+Shift+W${NC}  - Switch panel style"
    echo -e "  ${CYAN}Super+,${NC}        - Settings"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

###############################################################################
# Main
###############################################################################
main() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}iNiR Supporter Installation Script${NC}               ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_arch
    setup_aur_helper
    backup_configs
    install_inir
    restore_niri_config
    install_aur_packages
    setup_fastfetch_logo
    print_final_instructions

    # Ask for reboot
    echo -e "${YELLOW}A reboot is recommended to apply all changes.${NC}"
    read -rp "Would you like to reboot now? [y/N]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Rebooting..."
        systemctl reboot
    else
        info "Please reboot manually when ready."
    fi
}

main "$@"
