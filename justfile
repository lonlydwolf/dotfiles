# Steady-state front door (Ansible + chezmoi verbs). Freshness is by-hand: `topgrade`.
set shell := ["bash", "-euo", "pipefail", "-c"]

playbook := "ansible/site.yml"
brewfile := "home/dot_config/Brew/Brewfile"

default:
    @just --list

# preview dotfile changes
diff:
    chezmoi diff

# apply dotfiles (diff first)
apply: diff
    chezmoi apply

# whole-system dry-run
check:
    ansible-playbook {{playbook}} --check --diff

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
prune force="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "{{force}}" ]; then
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
