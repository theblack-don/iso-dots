# iNiR Supporter Installation Script

A simple installation script for Ko-Fi supporters to set up iNiR desktop shell along with recommended applications.

## What This Installs

- **iNiR** - A complete Niri desktop shell with Material You theming
- **equibop** - Discord desktop app with Equicord pre-installed
- **obsidian** - Knowledge base / note-taking application
- **helium-browser** - Private, fast Chromium-based web browser

## Features

- ✅ Automatic Arch-based distro detection
- ✅ AUR helper auto-detection (yay/paru) or installation
- ✅ Config backup before installation
- ✅ Preserves your existing niri config (keybinds, monitors, etc.)
- ✅ Custom fastfetch logo configuration
- ✅ Clear instructions for post-install setup

## Requirements

- Arch-based Linux distribution (Arch, EndeavourOS, Manjaro, etc.)
- Niri compositor installed
- Internet connection for package downloads

## Usage

### Option 1: Download and Run

```bash
# Clone or download this repository
git clone https://github.com/theblack-don/iso-dots.git
cd iso-dots

# Make the script executable
chmod +x install.sh

# Run the installation
./install.sh
```

### Option 2: One-Liner

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/iso-dots/main/install.sh | bash
```

## Post-Installation

After the script completes, you'll need to:

1. **Add iNiR startup to your niri config:**

   Edit `~/.config/niri/config.kdl` and add:
   ```
   spawn-at-startup "inir" "run"
   ```

2. **Reload niri config:**
   ```bash
   niri msg action load-config-file
   ```

3. **Or simply reboot** (recommended)

## Config Backup

Your existing configs are backed up to:
```
~/.config-backup-inir-YYYYMMDDHHMMSS/
```

To restore any config manually:
```bash
cp -r ~/.config-backup-inir-YYYYMMDDHHMMSS/<config-name> ~/.config/
```

## iNiR Quick Reference

| Command | Description |
|---------|-------------|
| `inir run` | Start the shell |
| `inir settings` | Open settings GUI |
| `inir logs` | Check runtime logs |
| `inir doctor` | Auto-diagnose and fix |
| `inir update` | Update iNiR |

## Keybinds

| Key | Action |
|-----|--------|
| `Super+Space` | Overview / app search |
| `Alt+Tab` | Window switcher |
| `Super+V` | Clipboard history |
| `Super+Shift+S` | Screenshot region |
| `Super+Shift+W` | Switch panel style |
| `Super+,` | Settings |

## Troubleshooting

If something goes wrong:

1. Check iNiR logs: `inir logs`
2. Run diagnostics: `inir doctor`
3. Restore your backup: `cp -r ~/.config-backup-inir-*/niri ~/.config/`
4. Reboot and try again

## Support

For iNiR-specific issues:
- [iNiR Documentation](https://github.com/snowarch/iNiR)
- [iNiR Discord](https://discord.gg/pAPTfAhZUJ)

## License

This installation script is provided as-is for Ko-Fi supporters.

---

Made with ❤️ for supporters
# iso-dots
