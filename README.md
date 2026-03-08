# dotfiles

My personal terminal setup for new machines. Installs zsh, [Oh My Zsh](https://ohmyz.sh/), useful plugins, and symlinks config files — all in one script.

> **Note:** This is built for **Debian/Ubuntu** (uses `apt` for package installation). It won't work out of the box on Arch, Fedora, macOS, etc.

## What's included

| File | Description |
|------|-------------|
| `.zshrc` | Zsh config with Oh My Zsh, eza aliases, git shortcuts, NVM |
| `.vimrc` | Minimal vim config (line numbers, desert theme, 4-space tabs) |
| `.gitconfig` | Git defaults (main branch, global gitignore, SSH commit signing) |
| `.gitignore` | Global gitignore (`.idea/`) |
| `tmux/` | Tmux config with Catppuccin theme, TPM plugins, and custom modules |
| `install.sh` | Interactive installer that sets everything up |

## Quick start

### On a fresh machine (no git or curl needed)

```bash
bash <(wget -qO- https://raw.githubusercontent.com/greew/dotfiles/main/install.sh)
```

The script will install curl, git, and clone the repo for you.

### From a clone

```bash
git clone https://github.com/greew/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

## What the installer does

1. **Installs dependencies** — `zsh`, `eza`, `curl`, `git`, `vim`, `tmux` (via `apt`)
2. **Installs Oh My Zsh** and the [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) plugin
3. **Downloads eza zsh completions** from the [eza repo](https://github.com/eza-community/eza)
4. **Sets up tmux** — symlinks config, custom modules, and installs [TPM](https://github.com/tmux-plugins/tpm) (auto-bootstraps on first run)
5. **Symlinks dotfiles** to `~/.dotfiles` — with diff view, backup, and skip options for existing files
6. **Configures git identity and SSH commit signing**
7. **Sets zsh as default shell**

The installer is interactive and idempotent — safe to re-run at any time.

## Machine-specific config

Two local files are supported for per-machine customization:

### `~/.zshrc.local.pre` — before Oh My Zsh loads

Use this to add plugins, change the theme, or modify OMZ settings:

```bash
# Add extra plugins for this machine
plugins+=(tmux kubectl)
```

### `~/.zshrc.local` — after everything loads

Use this for aliases, functions, environment variables, etc:

```bash
alias proj="cd ~/projects/my-thing"

# Auto-start tmux
if [ -z "$TMUX" ]; then
  tmux new-session -A -s main
fi
```

### `~/.tmux.conf.local` — tmux prefix override

The default prefix is `Ctrl+A` (for servers). Override it per machine:

```bash
# Use Ctrl+Space as prefix on workstations
unbind C-a
set -g prefix C-space
bind C-space send-prefix
```

### `~/.gitconfig.local` — git identity and signing

Created by the installer. Stores your name, email, and SSH signing key — keeping the shared `.gitconfig` clean.

## License

This is my personal setup, shared publicly in case it's useful to others. Feel free to fork, copy, and adapt to your needs.

**No warranty.** This comes as-is with no guarantees. I take no responsibility if something breaks, eats your config files, or sets your terminal on fire. Use at your own risk.

## Support

If you found this useful, you can [buy me a coffee](https://buymeacoffee.com/greew).
