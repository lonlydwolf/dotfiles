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

# Succeeds (with one line naming the public key) if $IDENTITY is the repo's age key
# with mode 600; otherwise says what is wrong and how to fix it. Never prints the key.
check_age_key() {
    want="$(sed -n 's/^[[:space:]]*recipient[[:space:]]*=[[:space:]]*"\(age1[0-9a-z]*\)".*/\1/p' \
        "$REPO_DIR/home/.chezmoi.toml.tmpl")"
    [ -n "$want" ] || die "no age recipient found in $REPO_DIR/home/.chezmoi.toml.tmpl"
    restore="cp /path/to/backup/key.txt $IDENTITY && chmod 600 $IDENTITY"
    if [ ! -e "$IDENTITY" ]; then
        echo "age key: missing at $IDENTITY" >&2
        echo "  fix: mkdir -p ${IDENTITY%/*} && $restore" >&2
        return 1
    fi
    have="$(chezmoi age-keygen -y "$IDENTITY" 2>/dev/null)" || have=""
    if [ -z "$have" ]; then
        echo "age key: $IDENTITY is not a readable age identity" >&2
        echo "  fix: $restore" >&2
        return 1
    fi
    if [ "$have" != "$want" ]; then
        echo "age key: wrong key at $IDENTITY (public key $have, repo expects $want)" >&2
        echo "  fix: $restore" >&2
        return 1
    fi
    mode="$(stat -L -c %a "$IDENTITY" 2>/dev/null || stat -L -f %Lp "$IDENTITY")"  # GNU, then BSD
    if [ "$mode" != 600 ]; then
        echo "age key: $IDENTITY has mode $mode, must be 600" >&2
        echo "  fix: chmod 600 $IDENTITY" >&2
        return 1
    fi
    echo "age key OK ($have)"
}

# The one gate: runs before the slow installs, silent apart from one line when the key is right.
age_gate() {
    while ! check_age_key; do
        # Prompts read /dev/tty: under curl | sh, stdin is the script itself.
        (exec </dev/tty) 2>/dev/null ||
            die "the age key needs attention and there is no terminal to ask; fix it as above and re-run"
        printf '[Enter] check again   [s] continue without secrets   [q] quit\n> ' >/dev/tty
        read -r answer </dev/tty || answer=q  # EOF quits rather than looping
        case "$answer" in
        s | S)
            continue_without_secrets
            return 0
            ;;
        q | Q) die "stopped at the age key check; re-run bootstrap once it is fixed" ;;
        esac  # anything else, including Enter: check again
    done
}

# chezmoi skips the encrypted targets while $IDENTITY does not exist (home/.chezmoiignore).
# A wrong or unsafe key would make every apply fail on them, so it is moved aside, never deleted.
continue_without_secrets() {
    if [ -e "$IDENTITY" ]; then
        # mktemp picks an unused name, so an earlier set-aside key is never overwritten.
        aside="$(mktemp "$IDENTITY.rejected-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
        mv -f "$IDENTITY" "$aside"
        chmod 600 "$aside"  # it may still be a private key
        echo "Moved the rejected key to $aside so chezmoi skips the secrets; delete it once you no longer need it."
    fi
    echo "Continuing without secrets. Later: put the right key at $IDENTITY (chmod 600), then 'just apply'."
}

main() {
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

    # chezmoi and the repo are in place, the slow installs are not: check the key now.
    age_gate

    # Interactive install of the # @core subset -> a usable machine before the slow rest.
    if [ "$os" = Darwin ]; then
        just install-core
    fi

    ansible-galaxy collection install -r ansible/requirements.yml  # cold core lacks community.general
    ansible-playbook ansible/site.yml

    echo "Core ready. Run 'just install' for the full set (casks + mas — sign into the App Store first)."
}

main "$@"
