# Steady-state front door (Ansible + chezmoi verbs). Freshness is by-hand: `topgrade`.
set shell := ["bash", "-euo", "pipefail", "-c"]

playbook := "ansible/site.yml"

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

# converge just the packages role
packages:
    ansible-playbook {{playbook}} --tags packages

# cleanup report (feeds prune)
audit:
    ansible-playbook {{playbook}} --check --diff --tags packages
    just prune

# opt-in cleanup — list-only unless you pass --force / -f
prune force="":
    ansible-playbook {{playbook}} --tags prune {{ if force != "" { "-e prune_force=true" } else { "" } }}
