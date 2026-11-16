# Steady-state front door (Ansible + chezmoi verbs). Freshness is by-hand: `topgrade`.
set shell := ["bash", "-euo", "pipefail", "-c"]

playbook := "ansible/site.yml"
brewfile := "home/dot_config/Brew/Brewfile"

default:
    @just --list

# preview dotfile changes
diff:
    chezmoi status
    chezmoi diff --exclude=encrypted

# apply dotfiles (diff first)
apply: diff
    chezmoi apply

# whole-system dry-run
check:
    ansible-playbook {{playbook}} --check --diff

# check the manual and drift-prone setup (read-only, offline; exit 1 if anything FAILs)
[no-exit-message]
doctor:
    #!/usr/bin/env bash
    # Only reads files, prefs and local repo state: no writes, no network, no secret values.
    set -uo pipefail
    repo="{{justfile_directory()}}"
    fails=0
    ok()   { printf '  ok    %s\n' "$1"; }
    fail() { printf '  FAIL  %s\n        fix: %s\n' "$1" "$2"; fails=$((fails + 1)); }
    todo() { printf '  todo  %s\n' "$1"; }
    mode() { stat -L -f %Lp "$1"; }

    echo "Secrets"
    key="$HOME/.config/chezmoi/key.txt"
    want="$(sed -n 's/^[[:space:]]*recipient[[:space:]]*=[[:space:]]*"\(age1[0-9a-z]*\)".*/\1/p' "$repo/home/.chezmoi.toml.tmpl")"
    if [[ ! -e "$key" ]]; then
        todo "running without secrets: restore the age key to $key (chmod 600), then 'just apply'"
    elif [[ "$(chezmoi age-keygen -y "$key" 2>/dev/null)" != "$want" ]]; then
        fail "age key at $key is not the repo's key ($want)" "replace it with the backup key.txt; chezmoi apply fails on the secrets until then"
    elif [[ "$(mode "$key")" != 600 ]]; then
        fail "age key has mode $(mode "$key")" "chmod 600 $key"
    elif [[ ! -f "$HOME/.config/cgm/.env" || ! -f "$HOME/.config/secrets/api-keys" ]]; then
        fail "age key OK but the decrypted secrets are missing" "just apply"
    else
        ok "age key matches $want; secrets applied"
    fi
    for aside in "$key".rejected-*; do
        [[ -e "$aside" ]] && todo "bootstrap set aside $aside; delete it once you no longer need it"
    done

    echo "SSH"
    ssh_key="$HOME/.ssh/github_ed25519"
    readme_fp="$(grep -o 'SHA256:[A-Za-z0-9+/]\{43\}' "$repo/README.md" | head -1)"
    signers="$HOME/.config/git/allowed_signers"
    if [[ ! -f "$ssh_key" || ! -f "$ssh_key.pub" ]]; then
        fail "$ssh_key(.pub) missing" "restore the pair from backup, chmod 600 $ssh_key, then /usr/bin/ssh-add --apple-use-keychain $ssh_key"
    else
        if [[ "$(mode "$ssh_key")" == 600 ]]; then ok "$ssh_key has mode 600"
        else fail "$ssh_key has mode $(mode "$ssh_key")" "chmod 600 $ssh_key"; fi
        fp="$(ssh-keygen -lf "$ssh_key.pub" | awk '{print $2}')"
        signer_fp="$(awk '{print $3, $4}' "$signers" 2>/dev/null | ssh-keygen -lf - 2>/dev/null | awk '{print $2}')"
        if [[ "$fp" == "$readme_fp" && "$fp" == "$signer_fp" ]]; then ok "key fingerprint $fp matches allowed_signers and README"
        else fail "key $fp, allowed_signers ${signer_fp:-missing}, README ${readme_fp:-missing}" "restore the right key pair, or update allowed_signers and README together"; fi
        if ssh-add -l 2>/dev/null | grep -qF " $fp "; then ok "key loaded in ssh-agent"
        else fail "key not loaded in ssh-agent (signing and pushes fail)" "/usr/bin/ssh-add --apple-use-keychain $ssh_key"; fi
    fi

    echo "Hotkeys"
    if skhd --status 2>&1 | grep -q 'event tap active'; then ok "skhd event tap active"
    else fail "skhd event tap not active" "skhd --start-service, allow skhd under Privacy & Security → Accessibility, then 'just hotkeys'"; fi
    if yabai -m query --spaces --space >/dev/null 2>&1; then ok "yabai responding"
    else fail "yabai not responding" "yabai --start-service and allow it under Accessibility"; fi
    # Shortcuts read from com.apple.symbolichotkeys: id, keycode, modifiers. An id with no
    # saved entry means the setting was never changed, which this cannot interpret.
    prefs="$(defaults export com.apple.symbolichotkeys - 2>/dev/null)"
    hotkey() { # id → "enabled keycode modifiers", empty if not saved
        local p="AppleSymbolicHotKeys.$1" e k m
        e="$(plutil -extract "$p.enabled" raw -o - - <<<"$prefs" 2>/dev/null)" || return 0
        k="$(plutil -extract "$p.value.parameters.1" raw -o - - <<<"$prefs" 2>/dev/null)"
        m="$(plutil -extract "$p.value.parameters.2" raw -o - - <<<"$prefs" 2>/dev/null)"
        echo "$e $k $m"
    }
    check_hotkey() { # label, id, keycode, modifiers, where to set it
        local got; got="$(hotkey "$2")"
        if [[ -z "$got" ]]; then todo "$1: no saved setting; check $5"
        elif [[ "$got" == "true $3 $4" ]]; then ok "$1"
        else fail "$1 is not set" "$5"; fi
    }
    check_hotkey "Spotlight on ⌘Space" 64 49 1048576 \
        "System Settings → Keyboard → Keyboard Shortcuts → Spotlight → Show Spotlight search"
    n=1
    for code in 18 19 20 21 23; do
        check_hotkey "Switch to Desktop $n on ⌥⌘$n" $((117 + n)) "$code" 1572864 \
            "System Settings → Keyboard → Keyboard Shortcuts → Mission Control → Switch to Desktop $n"
        n=$((n + 1))
    done

    echo "Unpushed work (against the last fetched origin/main)"
    for dir in "$repo" "$HOME/.config/nvim"; do
        name="$dir"; case "$dir" in "$HOME"/*) name="~${dir#"$HOME"}" ;; esac
        if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
            fail "$name is not a repo" "just apply (clones nvim) or re-run bootstrap"; continue
        fi
        # jj-colocated: git HEAD is @-, so the working tree vs HEAD is the uncommitted @.
        dirty="$(git -C "$dir" --no-optional-locks status --porcelain | wc -l | tr -d ' ')"
        if ! git -C "$dir" rev-parse -q --verify origin/main >/dev/null; then
            fail "$name has no origin/main" "jj git fetch -R $name"; continue
        fi
        ahead="$(git -C "$dir" rev-list --count origin/main..HEAD)"
        if [[ "$dirty" == 0 && "$ahead" == 0 ]]; then ok "$name: nothing uncommitted or unpushed"
        else fail "$name: $dirty uncommitted path(s), $ahead commit(s) not on origin/main" "jj commit, then jj git push (from $name)"; fi
    done

    echo "By hand (cannot be checked)"
    todo "App Store signed in (needed by 'just install' for the mas apps)"
    todo "Accessibility granted to skhd, yabai, Hyperkey and Maccy"
    todo "Hyperkey: Caps Lock as Hyper, Shift included, launch at login"
    todo "Maccy: open on Hyper+V, launch at login"
    todo "logged out and back in after the first bootstrap (keyboard settings)"

    echo
    if (( fails )); then echo "$fails problem(s) found."; exit 1; fi
    echo "No problems found."

# converge after editing a manifest or role
sync:
    ansible-playbook {{playbook}}

# report package drift (advisory; converge with `just install`)
packages:
    ansible-playbook {{playbook}} --tags packages

# install the full Brewfile (interactive: casks may prompt for sudo)
install:
    brew bundle install --file={{brewfile}} --verbose

# install only the # @core subset — a usable machine first (used by bootstrap)
install-core:
    #!/usr/bin/env bash
    set -euo pipefail
    core="$(mktemp)"
    trap 'rm -f "$core"' EXIT
    grep '# @core' {{brewfile}} > "$core"
    brew bundle install --file="$core" --verbose

# cleanup report (feeds prune)
audit:
    ansible-playbook {{playbook}} --check --diff --tags packages
    just prune

# cleanup — report only; `just prune -f` uninstalls + purges caches (interactive)
[arg("force", long="force", short="f", value="true")]
prune force="false":
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ "{{force}}" == "true" ]]; then
        if ! read -r -p "Type 'prune' to confirm destructive cleanup: " answer </dev/tty; then
            echo "An interactive terminal is required." >&2
            exit 1
        fi

        if [[ "$answer" != "prune" ]]; then
            echo "Cleanup cancelled."
            exit 1
        fi

        brew bundle cleanup --file={{brewfile}} --force
        brew cleanup --prune=all
    else
        ansible-playbook {{playbook}} --tags prune
    fi

# restart skhd, then Hyperkey (Hyperkey must start last for Hyper hotkeys to reach skhd)
hotkeys:
    #!/usr/bin/env bash
    set -euo pipefail
    skhd --restart-service
    for _ in {1..20}; do
        skhd --status 2>&1 | grep -q 'event tap active' && break
        sleep 0.5
    done
    skhd --status 2>&1 | grep -q 'event tap active' || { echo "skhd's event tap never came up; see skhd --status" >&2; exit 1; }
    osascript -e 'quit app "Hyperkey"'
    while pgrep -xq Hyperkey; do sleep 0.2; done
    open -a Hyperkey
