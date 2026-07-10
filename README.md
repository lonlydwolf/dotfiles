# dotfiles

My reproducible macOS setup — one command from factory reset to a working
machine. Ansible orchestrates, chezmoi applies dotfiles, brew + mise install
packages. `stow-archive` holds the pre-chezmoi history.

## Rebuild

**1. Restore the age identity first** (from offline backup — bootstrap refuses
to run without it):

```sh
mkdir -p ~/.config/chezmoi
cp /path/to/backup/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

**2. Sign in to the App Store** (needed for the `mas` apps), then bootstrap:

```sh
curl -fsSL https://raw.githubusercontent.com/lonlydwolf/dotfiles/main/bootstrap.sh | sh
```

**3. Log out and back in** — the keyboard settings need a full logout.

If a download fails mid-run, just re-run the one-liner — it picks up where it
left off. Afterwards, re-authenticate the tools that never store credentials
here (`gh auth login`, browsers, API keys).

## Day to day

```sh
just diff      # what would chezmoi change
just apply     # apply dotfiles
just check     # whole-system dry-run
just sync      # converge after editing a manifest or role
just audit     # what's installed but undeclared
just prune     # list undeclared; force=-f removes
```

Freshness is by hand: `topgrade` for packages, `chezmoi apply
--refresh-externals` for externals like nvim.

## Secrets

Small secrets live here age-encrypted (`encrypted_*.age`); the private key and
SSH/GPG stay on offline backup and are restored by hand (step 1); everything
else is re-authenticated on rebuild — nothing sensitive is ever committed.
