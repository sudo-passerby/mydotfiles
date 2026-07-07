#!/bin/bash

# sway (Wayland) Developer Setup - Configuration Installation Script
# This script copies all configuration files to their proper locations

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

print_status "Installing sway (Wayland) Developer configurations..."
print_status "Dotfiles directory: $DOTFILES_DIR"

# Create backup directory
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
print_status "Backup directory created: $BACKUP_DIR"

# Function to backup and copy config
backup_and_copy() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ -e "$dest" ]; then
        print_warning "Backing up existing $name configuration"
        cp -r "$dest" "$BACKUP_DIR/"
    fi
    
    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
    print_success "$name configuration installed"
}

# Install user configurations
print_status "Installing user configurations..."

backup_and_copy "$DOTFILES_DIR/config/kitty" "$HOME/.config/kitty" "kitty"
backup_and_copy "$DOTFILES_DIR/config/alacritty" "$HOME/.config/alacritty" "alacritty"
# Wayland / sway session
backup_and_copy "$DOTFILES_DIR/config/sway" "$HOME/.config/sway" "sway"
backup_and_copy "$DOTFILES_DIR/config/waybar" "$HOME/.config/waybar" "waybar"
backup_and_copy "$DOTFILES_DIR/config/fuzzel" "$HOME/.config/fuzzel" "fuzzel"
backup_and_copy "$DOTFILES_DIR/config/swaylock" "$HOME/.config/swaylock" "swaylock"
chmod +x "$HOME/.config/sway/scripts/wallpaper.sh" 2>/dev/null || true
backup_and_copy "$DOTFILES_DIR/config/dunst" "$HOME/.config/dunst" "dunst"
backup_and_copy "$DOTFILES_DIR/config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal" "xdg-desktop-portal"
backup_and_copy "$DOTFILES_DIR/config/fontconfig" "$HOME/.config/fontconfig" "fontconfig"
backup_and_copy "$DOTFILES_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0" "GTK3"
backup_and_copy "$DOTFILES_DIR/config/qt5ct" "$HOME/.config/qt5ct" "Qt5ct"
backup_and_copy "$DOTFILES_DIR/config/zed" "$HOME/.config/zed" "Zed"
backup_and_copy "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim" "Neovim"

# Copy single files
cp "$DOTFILES_DIR/config/mimeapps.list" "$HOME/.config/"
cp "$DOTFILES_DIR/config/gtkrc-2.0" "$HOME/.gtkrc-2.0" 2>/dev/null || true
cp "$DOTFILES_DIR/config/wallpaper.jpg" "$HOME/.config/wallpaper.jpg" 2>/dev/null || true

# zsh config (interactive + login env). Back up any existing ones first.
for z in zshrc zprofile; do
    [ -e "$HOME/.$z" ] && cp "$HOME/.$z" "$BACKUP_DIR/" 2>/dev/null
    cp "$DOTFILES_DIR/config/$z" "$HOME/.$z" 2>/dev/null || true
done
# One-time: seed zsh history from bash history so suggestions/Ctrl-R work immediately
if [ -f "$HOME/.bash_history" ] && [ ! -s "$HOME/.zsh_history" ]; then
    awk '!seen[$0]++' "$HOME/.bash_history" > "$HOME/.zsh_history"
fi

print_success "User configurations installed"

# Install system configurations (requires sudo)
print_status "Installing system configurations (requires sudo)..."

# greetd login configuration (Wayland; touchpad is handled by sway's input block)
print_status "Installing greetd login configuration..."
sudo mkdir -p /etc/greetd
sudo cp "$DOTFILES_DIR/config/greetd/config.toml" /etc/greetd/config.toml
sudo cp "$DOTFILES_DIR/config/greetd/regreet.toml" /etc/greetd/regreet.toml
print_success "greetd config installed"

# Login wallpaper — copied to a system-readable path (the greeter user cannot
# read ~/Pictures). regreet.toml points at /usr/share/backgrounds/greetd-login.jpg
print_status "Installing login wallpaper..."
sudo mkdir -p /usr/share/backgrounds
sudo cp "$DOTFILES_DIR/config/wallpaper.jpg" /usr/share/backgrounds/greetd-login.jpg
sudo chmod 644 /usr/share/backgrounds/greetd-login.jpg
print_success "login wallpaper installed"

# ReGreet state dirs so it can remember the last username/session
sudo mkdir -p /var/lib/regreet /var/cache/regreet
sudo chown -R greeter:greeter /var/lib/regreet /var/cache/regreet 2>/dev/null || true

# Enable greetd as the display manager
print_status "Enabling greetd service..."
sudo systemctl disable sddm.service 2>/dev/null || true
sudo systemctl enable greetd.service
print_success "greetd service enabled"

# Create sway (Wayland) desktop session
print_status "Creating sway (Wayland) desktop session..."
sudo mkdir -p /usr/share/wayland-sessions/
sudo tee /usr/share/wayland-sessions/sway.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=sway
Comment=An i3-compatible Wayland compositor
Exec=sway
TryExec=sway
Type=Application
DesktopNames=sway
Keywords=tiling;wm;wayland;compositor;
EOF
print_success "sway desktop session created"

# Update desktop and font databases
print_status "Updating system databases..."
update-desktop-database ~/.local/share/applications 2>/dev/null || true
fc-cache -fv > /dev/null 2>&1
print_success "System databases updated"

# Set up environment variables
print_status "Setting up environment variables..."
grep -q "GTK_THEME=Materia-dark" ~/.profile 2>/dev/null || echo "export GTK_THEME=Materia-dark" >> ~/.profile
grep -q "QT_QPA_PLATFORMTHEME=qt5ct" ~/.profile 2>/dev/null || echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> ~/.profile
grep -q "QT_STYLE_OVERRIDE=Fusion" ~/.profile 2>/dev/null || echo "export QT_STYLE_OVERRIDE=Fusion" >> ~/.profile
grep -q "QT_AUTO_SCREEN_SCALE_FACTOR=1" ~/.profile 2>/dev/null || echo "export QT_AUTO_SCREEN_SCALE_FACTOR=1" >> ~/.profile
grep -q "XCURSOR_SIZE=48" ~/.profile 2>/dev/null || echo "export XCURSOR_SIZE=48" >> ~/.profile
grep -q "XDG_CURRENT_DESKTOP=sway" ~/.profile 2>/dev/null || echo "export XDG_CURRENT_DESKTOP=sway" >> ~/.profile
print_success "Environment variables configured"

print_success "🎉 Installation complete!"
echo ""
print_status "Configuration backup saved to: $BACKUP_DIR"
print_status "Next steps:"
echo "  1. Reboot your system"
echo "  2. Log in at the greetd/ReGreet screen (session: sway)"
echo "  3. Press Super+Return to open a terminal"
echo "  4. Super+d = app launcher (fuzzel), Super+Shift+v = clipboard history"
echo ""
print_warning "Note: You may need to restart some applications to see theme changes"