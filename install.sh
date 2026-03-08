#!/bin/bash
set -e

DOTFILES_REPO="https://github.com/greew/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# If run from inside a clone, use that directory
if [ -f "$(dirname "$0")/.zshrc" ]; then
    DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}::${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*"; }

ask() {
    local prompt="$1" default="${2:-y}"
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    read -rp "$(echo -e "${YELLOW}?${NC} $prompt")" answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]$ ]]
}

# --------------------------------------------------------------------------
# Introduction
# --------------------------------------------------------------------------

echo ""
echo -e "${BOLD}Dotfiles Installer${NC}"
echo -e "──────────────────"
echo ""
echo "This script will:"
echo "  1. Install dependencies (zsh, eza, curl, git, vim)"
echo "  2. Install Oh My Zsh and plugins (zsh-autosuggestions)"
echo "  3. Symlink dotfiles (.zshrc, .vimrc, .gitconfig, .gitignore) to ~/dotfiles"
echo "  4. Configure git identity and commit signing"
echo "  5. Set zsh as default shell (if not already)"
echo ""
echo -e "Dotfiles source: ${BLUE}$DOTFILES_DIR${NC}"
echo ""

if ! ask "Ready to proceed?"; then
    echo "Aborted."
    exit 0
fi

echo ""

# --------------------------------------------------------------------------
# Dependencies
# --------------------------------------------------------------------------

PACKAGES=(zsh eza curl git vim)
MISSING=()

info "Checking dependencies..."

for pkg in "${PACKAGES[@]}"; do
    if command -v "$pkg" &>/dev/null; then
        success "$pkg is installed"
    else
        warn "$pkg is not installed"
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    info "Missing packages: ${MISSING[*]}"
    if ask "Install them with apt?"; then
        sudo apt update -qq
        sudo apt install -y -qq "${MISSING[@]}"
        success "Packages installed"
    else
        error "Cannot continue without: ${MISSING[*]}"
        exit 1
    fi
fi

echo ""

# --------------------------------------------------------------------------
# Clone dotfiles repo (if not already in a clone)
# --------------------------------------------------------------------------

if [ ! -d "$DOTFILES_DIR/.git" ]; then
    info "Cloning dotfiles repo into $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    success "Dotfiles cloned to $DOTFILES_DIR"
else
    info "Updating dotfiles repo..."
    git -C "$DOTFILES_DIR" pull --ff-only
    success "Dotfiles updated"
fi

echo ""

# --------------------------------------------------------------------------
# Oh My Zsh
# --------------------------------------------------------------------------

if [ -d "$HOME/.oh-my-zsh" ]; then
    success "Oh My Zsh is installed"
else
    info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed"
fi

# --------------------------------------------------------------------------
# Oh My Zsh plugins
# --------------------------------------------------------------------------

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    success "zsh-autosuggestions is installed"
else
    info "Installing zsh-autosuggestions..."
    git clone -q https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installed"
fi

echo ""

# --------------------------------------------------------------------------
# Eza zsh completions
# --------------------------------------------------------------------------

EZA_COMP="/usr/local/share/zsh/site-functions/_eza"
EZA_COMP_URL="https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza"

if [ -f "$EZA_COMP" ]; then
    success "Eza zsh completions installed"
    if ask "Re-download latest eza completions?" "n"; then
        sudo curl -fsSL -o "$EZA_COMP" "$EZA_COMP_URL"
        success "Eza completions updated"
    fi
else
    info "Installing eza zsh completions..."
    sudo mkdir -p /usr/local/share/zsh/site-functions
    sudo curl -fsSL -o "$EZA_COMP" "$EZA_COMP_URL"
    success "Eza completions installed"
fi

echo ""

# --------------------------------------------------------------------------
# Symlink dotfiles
# --------------------------------------------------------------------------

FILES=(.zshrc .vimrc .gitconfig .gitignore)

info "Setting up symlinks..."

for file in "${FILES[@]}"; do
    source_file="$DOTFILES_DIR/$file"
    target="$HOME/$file"

    # Source file must exist in the repo
    if [ ! -f "$source_file" ]; then
        warn "$file not found in dotfiles repo, skipping"
        continue
    fi

    # Already correctly linked
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source_file")" ]; then
        success "$file is already linked"
        continue
    fi

    # Existing file or different symlink
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo ""
        warn "$target already exists"

        if [ -L "$target" ]; then
            echo "  Current symlink: $(readlink "$target")"
        else
            echo "  Regular file, $(wc -l < "$target") lines"
        fi

        # Show diff if it's a regular file
        if [ -f "$target" ] && [ ! -L "$target" ]; then
            if ask "  Show diff between existing and repo version?" "n"; then
                echo ""
                diff --color=always -u "$target" "$source_file" || true
                echo ""
            fi
        fi

        echo "  What to do with the existing $file?"
        echo "    b) Backup to ${file}.bak and link"
        echo "    d) Delete and link"
        echo "    s) Skip"
        read -rp "$(echo -e "  ${YELLOW}?${NC} Choice [b/d/s]: ")" choice
        choice="${choice:-b}"

        case "$choice" in
            b)
                mv "$target" "${target}.bak"
                info "Backed up to ${target}.bak"
                ;;
            d)
                rm -f "$target"
                info "Deleted $target"
                ;;
            s)
                warn "Skipped $file"
                continue
                ;;
            *)
                warn "Unknown choice, skipping $file"
                continue
                ;;
        esac
    fi

    ln -sf "$source_file" "$target"
    success "Linked $file → $source_file"
done

echo ""

# --------------------------------------------------------------------------
# Git identity
# --------------------------------------------------------------------------

GIT_LOCAL="$HOME/.gitconfig.local"

if [ -f "$GIT_LOCAL" ]; then
    existing_name="$(git config --file "$GIT_LOCAL" user.name 2>/dev/null || true)"
    existing_email="$(git config --file "$GIT_LOCAL" user.email 2>/dev/null || true)"
fi

if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
    success "Git identity: $existing_name <$existing_email>"
else
    info "Git identity not configured"

    read -rp "$(echo -e "${YELLOW}?${NC} Your name for git commits: ")" git_name
    read -rp "$(echo -e "${YELLOW}?${NC} Your email for git commits: ")" git_email

    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        git config --file "$GIT_LOCAL" user.name "$git_name"
        git config --file "$GIT_LOCAL" user.email "$git_email"
        success "Git identity set in $GIT_LOCAL"
    else
        warn "Skipped — set manually in ~/.gitconfig.local"
    fi
fi

echo ""

# --------------------------------------------------------------------------
# Git commit signing
# --------------------------------------------------------------------------

existing_key="$(git config --file "$GIT_LOCAL" user.signingkey 2>/dev/null || true)"

if [ -n "$existing_key" ]; then
    success "Git signing key configured"
else
    if ask "Set up SSH commit signing?"; then
        # List available SSH keys
        echo ""
        echo "  Available SSH public keys:"
        found_keys=0
        for keyfile in "$HOME"/.ssh/*.pub; do
            if [ -f "$keyfile" ]; then
                echo "    $(basename "$keyfile"): $(cat "$keyfile" | cut -d' ' -f1-2 | cut -c1-80)..."
                found_keys=1
            fi
        done

        if [ "$found_keys" = "0" ]; then
            # Check if agent has keys
            agent_keys="$(ssh-add -L 2>/dev/null || true)"
            if [ -n "$agent_keys" ]; then
                echo "    (from SSH agent):"
                echo "$agent_keys" | while read -r line; do
                    echo "    $(echo "$line" | cut -d' ' -f1-2 | cut -c1-80)..."
                done
            else
                warn "No SSH keys found"
            fi
        fi

        echo ""
        read -rp "$(echo -e "${YELLOW}?${NC} Paste your SSH public key for signing: ")" signing_key

        if [ -n "$signing_key" ]; then
            git config --file "$GIT_LOCAL" user.signingkey "$signing_key"
            success "Signing key configured"

            # Check for 1Password SSH agent
            if [ -x "/opt/1Password/op-ssh-sign" ]; then
                if ask "Use 1Password for SSH signing?"; then
                    git config --file "$GIT_LOCAL" gpg.ssh.program "/opt/1Password/op-ssh-sign"
                    success "1Password signing configured"
                fi
            fi
        else
            warn "Skipped — set manually: git config --file ~/.gitconfig.local user.signingkey 'key...'"
        fi
    else
        warn "Commit signing not configured"
    fi
fi

echo ""

# --------------------------------------------------------------------------
# Default shell
# --------------------------------------------------------------------------

current_shell="$(basename "$SHELL")"
if [ "$current_shell" = "zsh" ]; then
    success "Default shell is already zsh"
else
    if ask "Change default shell to zsh?"; then
        sudo chsh -s "$(which zsh)" "$USER"
        success "Default shell changed to zsh (log out and back in to apply)"
    else
        warn "Shell not changed — run: sudo chsh -s \$(which zsh) \$USER"
    fi
fi

# --------------------------------------------------------------------------
# Done
# --------------------------------------------------------------------------

echo ""
echo -e "${GREEN}${BOLD}All done!${NC}"
echo ""
echo "Machine-specific config:"
echo "  ~/.zshrc.local.pre  — extra plugins, theme overrides (before OMZ loads)"
echo "  ~/.zshrc.local      — aliases, functions, env vars (after OMZ loads)"
echo "  ~/.gitconfig.local  — git identity and signing key"
echo ""
