# Wayland / sway Migration — Design

**Date:** 2026-07-07
**Status:** Approved design, pending implementation
**Scope:** Add a Wayland (sway) session to this dotfiles repo, alongside the existing i3 setup.

## Why

The clipboard on the X11/i3 setup is unreliable in two ways:

1. **Stale paste** — a fresh copy doesn't "take"; the previously-copied text is pasted instead.
2. **Chrome tab hangs** — pasting terminal text into Chrome freezes the tab.

### Root cause

X11 has no central clipboard store. The app that copied *owns* the selection, and
every paste is a **synchronous, blocking request** to that owner — if the owner is
slow or unresponsive, the pasting app's UI thread blocks (Chrome hangs).

This machine made it worse by running **three** daemons that all fight for X selection
ownership at once:

- `copyq` (clipboard-history monitor, re-claims ownership to record history)
- `autocutsel` on CLIPBOARD (constantly re-takes ownership to sync)
- `autocutsel` on PRIMARY (same, for middle-click selection)

The ownership war produces both symptoms: a daemon re-asserts old content (stale
paste), or sits mid-sync when Chrome's blocking request arrives (hang). Directly
observed: `xclip -selection clipboard -o -t TARGETS` **timed out**, i.e. the current
selection owner was not answering requests — the exact mechanism that freezes Chrome.

### Why Wayland fixes it

Wayland clipboard transfer is async and compositor-mediated: a paste reads from a
pipe fd rather than issuing a synchronous X11 `SelectionRequest` that blocks the
pasting app. The hang mechanism does not exist, and the copyq/autocutsel ownership
war disappears (those are X11 tools). AMD Strix Halo / amdgpu has best-in-class
Wayland support, so this is low-risk on this hardware.

> A cheaper X11-only fix exists (kill the autocutsel/copyq war). We chose the Wayland
> migration deliberately as a long-term platform upgrade, not purely as a bug fix.

## Approach: sway *alongside* i3 (dual session)

SDDM already offers session selection at login. Add a **Wayland `sway` session** and
leave the entire i3 setup intact as a fallback — mirroring this repo's existing
"keep a fallback" philosophy (stock `linux` kernel is kept as a GRUB fallback).

- sway becomes the daily driver.
- i3 remains selectable at SDDM; nothing about i3 is changed, so rollback is instant.

## Component map

| Function          | i3 today (kept as fallback) | New sway stack                          | Notes |
|-------------------|-----------------------------|-----------------------------------------|-------|
| Compositor / WM   | i3-wm                       | **sway**                                | reads i3 config ~verbatim |
| Status bar        | polybar                     | **waybar**                              | polybar has no Wayland support |
| Launcher          | rofi                        | **fuzzel** (Wayland-native)             | crisp HiDPI scaling; themed to match |
| Lock + idle       | i3lock + xss-lock           | **swaylock + swayidle**                 | |
| Screenshot        | flameshot                   | **grim + slurp + swappy**               | swappy = annotate UI |
| Wallpaper         | feh (`wallpaper.sh`)        | **swaybg** (adapted cycle script)       | |
| **Clipboard**     | copyq + autocutsel×2        | **wl-clipboard + cliphist** (+ wl-clip-persist) | the actual fix |
| Notifications     | dunst                       | **dunst** (native Wayland)              | unchanged |
| Compositing       | picom                       | *(native — none needed)*                | |
| Portal            | xdg-desktop-portal-gtk      | **+ xdg-desktop-portal-wlr**            | screenshare/screenshot |
| HiDPI             | Xresources / xrdb           | sway `output scale`                     | cleaner |
| Volume/brightness | pactl / brightnessctl       | **unchanged**                           | already Wayland-safe |
| Chrome            | XWayland                    | native: `--ozone-platform=wayland`      | |

### Packages

Official `extra`: `sway waybar fuzzel swaylock swayidle grim slurp swappy swaybg
wl-clipboard cliphist xdg-desktop-portal-wlr`.

AUR (optional, gated behind "if AUR helper present"): `wl-clip-persist` — keeps
clipboard alive after the source app closes. Without it, `cliphist` history still
lets you re-select recent copies, covering most of the gap.

## Repo integration (`mydotfiles`)

- **New configs:** `config/sway/`, `config/waybar/`, `config/swaylock/`, `config/swayidle/`, `config/fuzzel/`, plus a Wayland-adapted wallpaper script.
- **Edit `packages.txt`:** add a `## Wayland / sway` section.
- **Edit `install-packages.sh`:** install the sway stack (official pkgs; AUR pkg gated).
- **Edit `install-configs.sh`:** copy the new configs; create `/usr/share/wayland-sessions/sway.desktop`.
- **Keep untouched:** all i3 / polybar / picom configs (fallback).
- **README:** document the dual-session setup and how to pick sway at login.
- Commit in logical chunks; push to `origin/main`.

## Clipboard on Wayland (design detail)

- `wl-paste --watch cliphist store` (started from sway config) records history.
- A `cliphist` picker is bound to a key (via fuzzel) for history selection.
- `wl-clip-persist --clipboard regular` (if installed) keeps content after source exit.
- No daemon "owns" the selection persistently → no ownership war, no blocking paste.

## Config porting gotchas

- **`for_window [class=...]` → `[app_id=...]`** for native Wayland apps (kitty, thunar,
  pavucontrol). XWayland apps still match on `class`. Each window rule must be mapped
  to the correct matcher.
- `bindcode $mod+40` (rofi) → `bindsym $mod+d exec fuzzel`.
- Drop `xrdb`/`.Xresources` from autostart; set HiDPI via `output <name> scale`.
- Replace the X portal-launch shell dance with sway's cleaner
  `dbus-update-activation-environment` + systemd portal startup.

## Test & rollback

1. `sway --validate` on the new config; nested test-run from within the current i3
   session before logging out.
2. Log out → pick **sway** at SDDM → verify: clipboard copy→paste into Chrome (no
   hang, no stale), waybar, swaylock, screenshot, wallpaper, all keybinds.
3. If broken → log out → pick **i3** → back to normal instantly (i3 unchanged).

## Deferred cleanup (final phase — gated on confirmed success)

Once sway has been the daily driver long enough to trust (a few days of real use,
user confirms), a final phase removes the now-unnecessary X11 stack:

- Remove i3-specific configs/packages: `i3-wm`, `i3blocks`, `i3lock`, `polybar`,
  `picom`, `xss-lock`, `autocutsel`, `copyq`, `feh` (if unused), `xorg-xrandr`/
  `xorg-xsetroot`, and the X11 touchpad conf.
- Drop the i3 `.desktop` xsession and the i3/polybar/picom `config/*` dirs from the repo.
- Rebrand the repo README from "i3 Developer Setup" to sway/Wayland.
- **Only after** the user explicitly confirms the migration is successful. Until then,
  i3 stays as an instant-rollback fallback.

## Out of scope

- Suspend/resume & audio codec issues — those are kernel/ACP-level, unaffected by the
  display server, and their existing systemd sleep hooks carry over untouched.
