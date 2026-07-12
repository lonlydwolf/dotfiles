# dotfiles

My reproducible macOS setup — from factory reset to a working machine.
`bootstrap.sh` installs a usable core and converges system state; `just install`
fills in the full app set. Ansible detects drift and converges, chezmoi applies
dotfiles, brew + mise install packages. `stow-archive` holds the pre-chezmoi history.

## Rebuild

**1. Restore the age identity first** (from offline backup — bootstrap refuses
to run without it):

```sh
mkdir -p ~/.config/chezmoi
cp /path/to/backup/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

**2. Bootstrap** — installs the core (shell, terminal, editor, tooling) and
converges the system into a working machine:

```sh
curl -fsSL https://raw.githubusercontent.com/lonlydwolf/dotfiles/main/bootstrap.sh | sh
```

**3. Install the full set** — sign into the App Store first (for the `mas`
apps), then run the interactive install. This step is interactive because casks
like docker/zoom prompt for your password, which Ansible's non-TTY run can't do:

```sh
just install
```

**4. Log out and back in** — the keyboard settings need a full logout.

If a download fails mid-run, just re-run — bootstrap and `just install` both
pick up where they left off. Afterwards, re-authenticate the tools that never
store credentials here (`gh auth login`, browsers, API keys).

## Day to day

```sh
just diff      # what would chezmoi change
just apply     # apply dotfiles
just install   # install/converge the full Brewfile (interactive)
just sync      # converge system state; report package drift
just check     # whole-system dry-run
just audit     # what's installed but undeclared
just prune     # list undeclared; `just prune -f` removes (interactive)
```

Package installs (brew) run interactively via `just install`; Ansible only
reports brew drift and points you here (casks need a TTY to prompt for sudo).
Freshness is by hand: `topgrade` for packages, `chezmoi apply
--refresh-externals` for externals like nvim.

## Secrets

Small secrets live here age-encrypted (`encrypted_*.age`); the private key and
SSH/GPG stay on offline backup and are restored by hand (step 1); everything
else is re-authenticated on rebuild — nothing sensitive is ever committed.
