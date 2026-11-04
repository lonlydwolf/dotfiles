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

## Hotkeys

Caps Lock is a Hyper key (⌃⌥⇧⌘) through Hyperkey, skhd maps Hyper shortcuts
to yabai (`~/.config/skhd/skhdrc`), Maccy keeps clipboard history, and
Spotlight launches apps. These need one-time setup by hand after `just install`:

1. **Coming from Raycast:** turn off Raycast's Hyper Key first (Raycast
   Settings → Advanced → Hyper Key). It remaps Caps Lock to F20 with `hidutil`,
   which would otherwise fight Hyperkey. Then quit and uninstall Raycast
   (`brew uninstall --cask raycast`). If Caps Lock still acts odd, clear the
   leftover mapping with `hidutil property --set '{"UserKeyMapping":[]}'` or
   reboot.
2. **Hyperkey:** set Caps Lock as the Hyper key, keep Shift included (skhd's
   `hyper` is all four modifiers), turn on launch at login, and grant
   Accessibility.
3. **skhd:** `skhd --start-service`, allow it under System Settings → Privacy &
   Security → Accessibility, then `skhd --restart-service`. `skhd --status`
   checks it. yabai runs the same way (`yabai --start-service`).
4. **Spotlight:** System Settings → Keyboard → Keyboard Shortcuts → Spotlight →
   turn on "Show Spotlight search" (⌘Space).
5. **Maccy:** Settings → General → Open → record Caps Lock+V (Hyper+V), turn on
   launch at login, and grant Accessibility so it can paste.
6. **Desktops:** System Settings → Keyboard → Keyboard Shortcuts → Mission
   Control → set "Switch to Desktop 1"–"5" to ⌥⌘1–⌥⌘5 (not set by this repo).
   skhd adds ⌥⌘6 for the space after them, usually a full-screen app.

## Secrets

Small secrets live here age-encrypted (`encrypted_*.age`); the private key and
SSH/GPG stay on offline backup and are restored by hand (step 1); everything
else is re-authenticated on rebuild — nothing sensitive is ever committed.

## Commit signing

Git automatically signs new commits with SSH. Jujutsu signs commits authored
by the configured user as they are created or modified (`signing.behavior =
"own"`), without waiting for a push. Both use `~/.ssh/github_ed25519.pub`
through the macOS SSH agent and verify against `~/.config/git/allowed_signers`.
The expected key fingerprint is
`SHA256:XA4Gi8DOAuoaOAvbQx7Ofpu9aIveNDhoaS/EiKv1Cc4`.

On a rebuilt machine, restore the existing SSH key pair from backup, then load
it into the macOS agent (interactive once if its passphrase is needed):

```sh
/usr/bin/ssh-add --apple-use-keychain ~/.ssh/github_ed25519
ssh-add -l
```

T3-Code and other coding agents inherit the global Git/jj settings; no shell
alias or signing flag is required. Their process environment must expose the
loaded agent through `SSH_AUTH_SOCK`. If it is missing, launch the app from a
shell with the macOS agent socket exported (restart an already running app):

```sh
export SSH_AUTH_SOCK="$(launchctl getenv SSH_AUTH_SOCK)"
```

The public-key path deliberately requires the agent, so unattended commits do
not prompt for the private key's passphrase. Agent sandboxes must allow access
to that socket. Repository settings or explicit `--no-gpg-sign`/jj signing
overrides can still disable these defaults.

For GitHub's Verified badge, add this same public key to the account as a
**Signing Key**, even if it is already registered for authentication, and
ensure `contact@ahmadmollaei.dev` is a verified account email. Local signature
verification does not require GitHub registration.
