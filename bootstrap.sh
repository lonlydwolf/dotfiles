#!/bin/sh
# Cold start: curl -fsSL https://raw.githubusercontent.com/lonlydwolf/dotfiles/main/bootstrap.sh | sh
set -eu

REPO_URL="https://github.com/lonlydwolf/dotfiles.git"
REPO_DIR="$HOME/dotfiles"
IDENTITY="$HOME/.config/chezmoi/key.txt"

# age identity is restored by hand first (rebuild step 1)
if [ ! -f "$IDENTITY" ]; then
    echo "ERROR: age identity missing at $IDENTITY — restore it first (rebuild step 1)" >&2
    exit 1
fi

os="$(uname -s)"
case "$os" in
Darwin)
    if ! xcode-select -p >/dev/null 2>&1; then
        xcode-select --install
        echo "Waiting for Xcode Command Line Tools..."
        until xcode-select -p >/dev/null 2>&1; do sleep 5; done  # installer is async
    fi
    if ! command -v brew >/dev/null 2>&1; then
        NONINTERACTIVE=1 /bin/bash -c \
          "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"  # brew not on PATH yet
    command -v ansible-playbook >/dev/null 2>&1 || brew install ansible
    command -v chezmoi          >/dev/null 2>&1 || brew install chezmoi
    ;;
Linux)
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm base-devel git ansible chezmoi
    else
        echo "ERROR: unsupported Linux (no pacman)" >&2
        exit 1
    fi
    ;;
*)
    echo "ERROR: unsupported OS: $os" >&2
    exit 1
    ;;
esac

[ -d "$REPO_DIR" ] || git clone "$REPO_URL" "$REPO_DIR"  # single clone; chezmoi reuses it
cd "$REPO_DIR"
ansible-galaxy collection install -r ansible/requirements.yml  # cold core lacks community.general
ansible-playbook ansible/site.yml
