# 🚀 sway (Wayland) Developer Setup

A complete, modern **sway** (Wayland) tiling-WM configuration for developers, on an
Arch/CachyOS laptop (AMD Strix Halo). Nord-inspired dark theme, an X-free session,
and a fast keyboard-driven workflow. Migrated from an earlier i3/X11 setup — see
[`docs/wayland-migration.md`](docs/wayland-migration.md) for the full rationale
(the short version: X11's blocking, owner-based clipboard was hanging Chrome; Wayland
fixes that class of bug by design).

## ✨ Highlights

- **100% Wayland session** — no X server. `xorg-xwayland` is kept so X-only apps
  (Steam, some Electron apps) still run inside sway.
- **Reliable clipboard** — `wl-clipboard` + `cliphist` (+ `wl-clip-persist`), no more
  stale pastes or Chrome freezes.
- **Nord-inspired dark theme** across sway, waybar, fuzzel, swaylock and GTK/Qt apps.
- **HiDPI done right** — integer `output scale 2.0` on the 2.5k panel (crisp, no blur).
- **Vim-style navigation** (`Super + h/j/k/l`) and the familiar i3 keymap.

## 📋 What's Included

### Core applications
- **Terminals**: kitty (`Super+Return`), alacritty
- **Editor**: Zed · **Browser**: Firefox · **Files**: Thunar
- **Image viewer**: imv · **PDF**: mupdf · **Media**: mpv

### Session components (all Wayland-native)
- **Compositor / WM**: sway (composites natively — no picom)
- **Status bar**: waybar
- **Launcher**: fuzzel
- **Lock / idle**: swaylock + swayidle
- **Login (display manager)**: greetd + ReGreet (graphical, on `cage`)
- **Screenshots**: grim + slurp + swappy
- **Wallpaper**: swaybg · **Notifications**: dunst
- **Clipboard**: wl-clipboard + cliphist (+ wl-clip-persist)

### Theming
- GTK: Materia-dark · Icons: Papirus · Qt: qt5ct/kvantum
- Font: Hack Nerd Font (terminals: FiraCode Nerd Font)

## 🛠 Installation

### Prerequisites
- Arch Linux / CachyOS, internet connection, sudo privileges.

### Quick install
```bash
git clone https://github.com/glitchdoescode/mydotfiles.git ~/mydotfiles
cd ~/mydotfiles
./setup.sh          # runs install-packages.sh then install-configs.sh
reboot
```
At the greetd/ReGreet login screen, pick the **sway** session and log in.

## 🎮 Keybindings

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (kitty) |
| `Super + d` | App launcher (fuzzel) |
| `Super + Shift + v` | Clipboard history (cliphist) |
| `Super + c` | Zed editor |
| `Super + Shift + f` | File manager (Thunar) |
| `Super + Shift + w` | Firefox |
| `Super + Shift + s` | Region screenshot → swappy |
| `Print` | Full-screen screenshot → swappy |
| `Super + h/j/k/l` | Focus window (vim-style) |
| `Super + Shift + h/j/k/l` | Move window |
| `Super + b` / `Super + v` | Split horizontal / vertical |
| `Super + f` | Fullscreen toggle |
| `Super + Shift + Space` | Float / unfloat |
| `Super + 1..0` | Switch to workspace 1–10 |
| `Super + Shift + 1..0` | Move window to workspace |
| `Super + Shift + r` | Reload sway config |
| `Super + Shift + e` | Exit sway (via swaynag) |
| Volume / Brightness keys | pactl / brightnessctl |

## 📁 Directory structure

```
mydotfiles/
├── config/
│   ├── sway/          # sway WM config + wallpaper script
│   ├── waybar/        # status bar (config + style.css)
│   ├── fuzzel/        # app launcher
│   ├── swaylock/      # lock screen
│   ├── greetd/        # login: config.toml + regreet.toml
│   ├── kitty/ alacritty/   # terminals
│   ├── dunst/         # notifications
│   ├── nvim/ zed/     # editors
│   ├── gtk-3.0/ qt5ct/ fontconfig/   # theming
│   ├── xdg-desktop-portal/           # portals (file dialogs, screencast)
│   ├── zshrc zprofile mimeapps.list gtkrc-2.0 wallpaper.jpg
│   └── ollama/        # local LLM config
├── scripts/           # install-packages.sh, install-configs.sh
├── docs/              # wayland-migration.md (design/rationale)
├── packages.txt       # complete package list
└── setup.sh           # one-command installer
```

## 🖥 Display scaling

HiDPI is set in `config/sway/config`:
```
output eDP-1 scale 2.0
```
Change to `1.75` / `1.5` for smaller UI, then `Super+Shift+r` to reload. Terminal font
sizes live in `config/kitty/kitty.conf` and `config/alacritty/alacritty.toml`.

## 📝 License

MIT — see [LICENSE](LICENSE).

---

*Migrated to Wayland/sway and battle-tested in daily development. X-free by design,
with XWayland retained for app compatibility.*
