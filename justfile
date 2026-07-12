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
    brew bundle install --file={{brewfile}}

# install only the # @core subset — a usable machine first (used by bootstrap)
install-core:
    #!/usr/bin/env bash
    set -euo pipefail
    core="$(mktemp)"
    trap 'rm -f "$core"' EXIT
    grep '# @core' {{brewfile}} > "$core"
    brew bundle install --file="$core"

# cleanup report (feeds prune)
audit:
    ansible-playbook {{playbook}} --check --diff --tags packages
    just prune

# opt-in cleanup — list-only unless you pass --force / -f
prune force="":
    ansible-playbook {{playbook}} --tags prune {{ if force != "" { "-e prune_force=true" } else { "" } }}
