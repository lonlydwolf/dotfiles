#!/bin/sh
# Cold start: curl -fsSL https://raw.githubusercontent.com/lonlydwolf/dotfiles/main/bootstrap.sh | sh
# Everything runs from main(), called on the last line: a truncated download runs nothing.
set -eu

REPO_URL="https://github.com/lonlydwolf/dotfiles.git"  # public; pushes rewrite to SSH (git config)
REPO_DIR="$HOME/dotfiles"
IDENTITY="$HOME/.config/chezmoi/key.txt"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

main() {
    # age identity is restored by hand first (rebuild step 1)
    if [ ! -f "$IDENTITY" ]; then
        die "age identity missing at $IDENTITY — restore it first (rebuild step 1)"
    fi

    # Cache sudo up front: the Homebrew install below runs NONINTERACTIVE and fails without it.
    echo "Bootstrap needs sudo for system installs; enter your password if asked."
    sudo -v || die "sudo failed — run bootstrap from a terminal as an admin user"

    os="$(uname -s)"
    case "$os" in
    Darwin)
        if ! xcode-select -p >/dev/null 2>&1; then
            xcode-select --install
            echo "Waiting for Xcode Command Line Tools..."
            until xcode-select -p >/dev/null 2>&1; do sleep 5; done  # installer is async
        fi
        # Homebrew refuses until the Xcode license is accepted; needs sudo (no-op if already agreed).
        # Also refreshes the sudo timestamp, which may have expired during the CLT wait.
        echo "Accepting the Xcode license (may prompt for your password)…"
        sudo xcodebuild -license accept 2>/dev/null || true
        if ! command -v brew >/dev/null 2>&1; then
            NONINTERACTIVE=1 /bin/bash -c \
              "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"  # brew not on PATH yet
        command -v ansible-playbook >/dev/null 2>&1 || brew install ansible
        command -v chezmoi          >/dev/null 2>&1 || brew install chezmoi
        command -v just             >/dev/null 2>&1 || brew install just
        ;;
    Linux)
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm base-devel git ansible chezmoi
        else
            die "unsupported Linux (no pacman)"
        fi
        ;;
    *)
        die "unsupported OS: $os"
        ;;
    esac

    # .git, not just the directory: an interrupted or stray ~/dotfiles is not a clone.
    [ -d "$REPO_DIR/.git" ] || git clone "$REPO_URL" "$REPO_DIR"  # single clone; chezmoi reuses it
    cd "$REPO_DIR"

    # Interactive install of the # @core subset -> a usable machine before the slow rest.
    if [ "$os" = Darwin ]; then
        just install-core
    fi

    ansible-galaxy collection install -r ansible/requirements.yml  # cold core lacks community.general
    ansible-playbook ansible/site.yml

    echo "Core ready. Run 'just install' for the full set (casks + mas — sign into the App Store first)."
}

main "$@"
