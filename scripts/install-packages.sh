#!/bin/bash

# i3 Developer Setup - Package Installation Script
# This script installs all required packages for the i3 configuration

set -e

echo "🚀 Installing i3 Developer Setup packages..."

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

# Check if running on Arch Linux
if ! command -v pacman &> /dev/null; then
    print_error "This script is designed for Arch Linux systems with pacman"
    exit 1
fi

print_status "Updating package database..."
sudo pacman -Sy

# Remove conflicting audio packages (this setup uses PipeWire)
# Note: lightdm is removed later by install-configs.sh, once SDDM is in place,
# to avoid leaving the system with no display manager.
print_status "Checking for conflicting packages..."
for pkg in pulseaudio pulseaudio-alsa; do
    if pacman -Qq "$pkg" &> /dev/null; then
        print_warning "Removing conflicting package: $pkg"
        sudo pacman -Rns --noconfirm "$pkg" || \
            print_warning "Could not auto-remove $pkg (check dependencies manually)"
    fi
done

print_status "Installing Wayland / sway session stack..."
sudo pacman -S --needed --noconfirm \
    sway \
    swaybg \
    swayidle \
    swaylock \
    waybar \
    fuzzel \
    grim \
    slurp \
    swappy \
    wl-clipboard \
    cliphist \
    xdg-desktop-portal-wlr

# Optional: wl-clip-persist keeps clipboard content alive after the source app
# exits. Available as a prebuilt package in the CachyOS repo (which this setup
# enables); on stock Arch it is AUR-only. Try the repo first, then an AUR helper,
# else skip (cliphist history still covers re-selecting recent copies).
if pacman -Si wl-clip-persist &> /dev/null; then
    sudo pacman -S --needed --noconfirm wl-clip-persist || \
        print_warning "wl-clip-persist install failed; skipping (optional)"
elif command -v paru &> /dev/null; then
    paru -S --needed --noconfirm wl-clip-persist || \
        print_warning "wl-clip-persist install failed; skipping (optional)"
elif command -v yay &> /dev/null; then
    yay -S --needed --noconfirm wl-clip-persist || \
        print_warning "wl-clip-persist install failed; skipping (optional)"
else
    print_warning "wl-clip-persist unavailable (no repo pkg, no AUR helper) — skipping (optional)"
fi

print_status "Installing login (greetd) and session utilities..."
# greetd = minimal Wayland login daemon (no X). regreet+cage = graphical greeter
# (wallpaper, remembers user); tuigreet = lightweight console fallback greeter.
sudo pacman -S --noconfirm \
    greetd \
    greetd-regreet \
    greetd-tuigreet \
    cage \
    dunst \
    dex

print_status "Installing applications..."
sudo pacman -S --noconfirm \
    kitty \
    alacritty \
    zed \
    firefox \
    thunar \
    thunar-archive-plugin \
    file-roller \
    xarchiver \
    imv \
    libwebp \
    libavif \
    libheif \
    mupdf \
    mpv \
    flameshot

print_status "Installing fonts and theming..."
sudo pacman -S --noconfirm \
    ttf-hack-nerd \
    ttf-firacode-nerd \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    noto-fonts-extra \
    ttf-liberation \
    ttf-dejavu \
    papirus-icon-theme \
    materia-gtk-theme \
    breeze-gtk

print_status "Installing system utilities..."
sudo pacman -S --noconfirm \
    brightnessctl \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    pavucontrol \
    networkmanager \
    network-manager-applet \
    xdg-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr \
    gvfs \
    xorg-xwayland \
    xorg-xrandr \
    qt5ct \
    kvantum

print_status "Installing development tools..."
sudo pacman -S --noconfirm \
    git \
    base-devel \
    vim \
    neovim \
    fzf

# ---------------------------------------------------------------------------
# Shell: zsh + plugins + Starship prompt, and make it the default shell
# ---------------------------------------------------------------------------
print_status "Installing zsh shell stack..."
sudo pacman -S --needed --noconfirm \
    zsh \
    zsh-completions \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    starship

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
    print_status "Setting zsh as the default login shell..."
    sudo chsh -s "$(command -v zsh)" "$USER" && \
        print_success "Default shell changed to zsh (effective on next login)"
else
    print_status "zsh is already the default shell"
fi

# ---------------------------------------------------------------------------
# AMD GPU / graphics stack (this machine: Ryzen AI Max "Strix Halo", Radeon 8060S)
# The amdgpu kernel driver + mesa + RADV (vulkan-radeon) are all that's needed.
# ---------------------------------------------------------------------------
print_status "Installing AMD GPU / Vulkan graphics stack..."
sudo pacman -S --needed --noconfirm \
    mesa \
    vulkan-radeon \
    vulkan-icd-loader \
    vulkan-tools

# ---------------------------------------------------------------------------
# Multilib + gaming (32-bit graphics libs for Steam / Proton)
# ---------------------------------------------------------------------------
print_status "Enabling multilib repository..."
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    print_success "multilib enabled"
else
    print_status "multilib already enabled"
fi

print_status "Installing 32-bit graphics + Steam..."
sudo pacman -S --needed --noconfirm \
    lib32-mesa \
    lib32-vulkan-radeon \
    steam

# ---------------------------------------------------------------------------
# Vulkan LLM path (Strix Halo iGPU inference via RADV)
#   - ollama-vulkan : easy model management; the iGPU must be force-enabled
#                     (ollama skips integrated GPUs by default)
#   - llama-cpp-vulkan : direct llama.cpp with the Vulkan backend
# ---------------------------------------------------------------------------
print_status "Installing Vulkan LLM runtimes..."
sudo pacman -S --needed --noconfirm \
    ollama-vulkan \
    llama-cpp-vulkan

print_status "Configuring ollama to use the Strix Halo iGPU..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
# Strix Halo: the Radeon 8060S is an iGPU, which ollama skips by default.
Environment="OLLAMA_IGPU_ENABLE=1"
Environment="OLLAMA_VULKAN=1"
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ollama.service
print_success "ollama configured for Vulkan iGPU inference"

# ---------------------------------------------------------------------------
# CachyOS kernel — REQUIRED for internal speaker support on this ASUS TUF A14
# (FA401EA: AMD ACP7.0 / Realtek RT721 SDCA SoundWire amp). Stock Arch `linux`
# has no machine driver for it ("No matching ASoC machine driver"); the CachyOS
# kernel carries the quirk so speakers + mic work.
# NOTE: cachyos-repo.sh also runs a full `pacman -Syu`, migrating the system to
# CachyOS-optimized v4 builds. The stock `linux` kernel stays as a GRUB fallback.
# (Secure Boot is NOT scripted — sbctl keys are machine-specific; set it up by hand.)
# ---------------------------------------------------------------------------
print_status "Setting up CachyOS kernel (internal speaker support)..."
if ! grep -q '^\[cachyos\]' /etc/pacman.conf; then
    CACHY_TMP="$(mktemp -d)"
    if curl -fsSL https://mirror.cachyos.org/cachyos-repo.tar.xz | tar xJ -C "$CACHY_TMP"; then
        ( cd "$CACHY_TMP/cachyos-repo" && yes | sudo ./cachyos-repo.sh --install )
    else
        print_warning "Could not fetch CachyOS repo script; set it up manually: https://wiki.cachyos.org/"
    fi
    rm -rf "$CACHY_TMP"
else
    print_status "CachyOS repo already configured"
fi
if pacman -Si linux-cachyos &> /dev/null; then
    sudo pacman -S --needed --noconfirm linux-cachyos linux-cachyos-headers
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    print_success "CachyOS kernel installed (boot it from GRUB; stock 'linux' kept as fallback)"
else
    print_warning "linux-cachyos unavailable — skipped (needed for internal speakers on this machine)"
fi

print_success "All packages installed successfully!"
print_status "Next step: Run './install-configs.sh' to set up configurations"
