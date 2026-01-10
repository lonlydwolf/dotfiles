# Dotfiles

A comprehensive, keyboard-centric macOS development environment configuration managed via GNU Stow.
Focused on low latency, visual consistency (Catppuccin Mocha), and seamless integration between terminal tools.

## 🎨 Theme & Philosophy

*   **Visual Style:** Catppuccin Mocha (Matte Bubble).
*   **Workflow:** Vim-everywhere (Shell, Tmux, Editor, File Manager).
*   **Performance:** Native tools preferred (Zsh globbing, `fd`, `rg`, `fzf`).
*   **Management:** `stow` for symlink management, `topgrade` for system updates.

## 🛠️ Core Components

| Component | Tool | Configuration Highlights |
| :--- | :--- | :--- |
| **Shell** | **Zsh** | Oh-My-Zsh, Oh-My-Posh (Bubbles Extra), Vi-Mode, Smart Lang Detection |
| **Terminal** | **Ghostty** | JetBrainsMono Nerd Font, Blur, Tabs, Block Cursor |
| **Multiplexer** | **Tmux** | TPM, Popups (IPython/Terminal/Jrnl), SessionX, Continuum |
| **Editor** | **Neovim** | Kickstart-based, LSP, Treesitter, Harpoon, Oil.nvim |
| **File Manager** | **Yazi** | Custom Native QuickLook (`ql.swift`), VLC focus handling |
| **Version Control** | **Jujutsu (jj)** | Integrated into Zsh Prompt (Zero-Fork), Magic Enter |
| **Updates** | **Topgrade** | Unified system update strategy |
| **Symlinks** | **Stow** | Easy deployment to `~/.config` |

## ⚡ Performance Architecture

This dotfiles setup prioritizes **latency** above all else.
*   **Zero-Fork Prompt:** The `oh-my-posh` prompt uses a custom Zsh `precmd` hook with native globbing. It detects project languages (Python, Go, Node, etc.) *without* spawning external processes like `fd` or `find`, ensuring an instant prompt even in massive monorepos.
*   **Compiled Binaries:** Yazi's QuickLook uses a pre-compiled Swift binary to avoid interpretation overhead.
*   **Init Caching:** `oh-my-posh` initialization is cached to a static file (`init.zsh`), regenerating only when the config changes.
*   **Lazy Loading:** Neovim plugins are lazy-loaded via `lazy.nvim`, and Zsh plugins rely on autoloading where possible.

## 🚀 Installation

### 1. Prerequisites
Ensure you have **Homebrew** installed. Then install all dependencies from the Brewfile:

```bash
brew bundle --file=Brew/Brewfile
```

### 2. Clone & Stow
Clone this repository to your home directory:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Use `stow` to symlink configurations to your home directory. This will link folders like `zsh` to `~/.zshrc`, `nvim` to `~/.config/nvim`, etc.

```bash
# Link all core configurations
stow zsh ghostty nvim tmux yazi oh-my-posh topgrade bat

# Optional: Link oh-my-zsh custom plugins if needed
# stow oh-my-zsh
```

## ⚙️ Configuration Details

### 🐚 Zsh (The Shell)
*   **Prompt:** `oh-my-posh` (Cached init) with a custom "Bubbles Extra" theme.
    *   **Smart Logic:** Language segments (Python, Go, Node, etc.) *only* appear when inside a Git/JJ repository.
    *   **Skeleton Mode:** Displays a skull (💀) if multiple languages are detected to keep the prompt clean.
*   **Completions:** **`carapace`** (Universal) and **`fzf-tab`** (Interactive) enabled.
*   **Magic Enter:** Pressing `Enter` on an empty line runs `jj st` (if in a git/jj repo) or `clear` otherwise.
*   **Wrappers:** `y` launches Yazi and changes directory on exit.
*   **Aliases:** Modern replacements enabled (`cat`->`bat`, `find`->`fd`, `grep`->`rg`).

### 🖥️ Ghostty (The Terminal)
*   **Font:** JetBrainsMono Nerd Font Mono (Medium Italic).
*   **Style:** Minimalist, matte background (`#1e1e2e`) with blur.
*   **Integration:** Shell integration enabled for Zsh.

### 🧩 Tmux (The Multiplexer)
*   **Prefix:** `Ctrl+a` (Remapped from `Ctrl+b`).
*   **Popups:**
    *   `Prefix + C-p`: IPython
    *   **`Prefix + C-t`**: Quick Terminal
    *   `Prefix + C-j`: Jrnl Entry
*   **Session Management:** `tmux-sessionx` for fuzzy session switching.
*   **Persistence:** Auto-saves and restores sessions via `tmux-continuum`.

### 📂 Yazi (File Manager)
*   **Plugins:**
    *   **`ouch`:** Archive preview and compression support.
    *   **`chmod`:** Rapid permission changing.
    *   **`smart-enter`:** Unified "Enter" behavior (enters directories, opens files).
    *   **`folder-rules`:** Auto-sorts `~/Downloads` by modification time (newest first).
*   **Features:**
    *   **Native QuickLook (`Ctrl+p`):** Uses a **compiled Swift binary** (`quicklook`) for instant, focus-stealing native previews.
    *   **Git Navigation:** `gr` jumps immediately to the git repository root.
    *   **VLC Handling:** Opening video files triggers `open -a VLC` for proper window focus.

### 📝 Neovim (The Editor)
*   **Base:** Kickstart.nvim (Modular).
*   **Key Plugins:**
    *   **Navigation:** `harpoon`, `oil.nvim`, `vim-tmux-navigator`.
    *   **Coding:** `blink.cmp`, `conform.nvim`, `mini.indentscope`, `nvim-treesitter-textobjects`.
    *   **UI:** `trouble.nvim` (Diagnostics), `neo-tree`.
*   **Colorscheme:** Catppuccin Mocha.

## ⌨️ Keybindings Cheat Sheet

| Context | Key | Action |
| :--- | :--- | :--- |
| **Global** | `jk` | Escape (in Insert Mode) |
| **Zsh** | `Enter` | Magic Enter (JJ status or Clear) |
| **Zsh** | `y` | Yazi (Syncs CWD on exit) |
| **Zsh** | `Ctrl+t` | FZF File Search |
| **Zsh** | `Ctrl+r` | FZF History Search |
| **Tmux** | `Ctrl+a` | Prefix |
| **Tmux** | `Ctrl+a` `|` | Split Horizontal |
| **Tmux** | `Ctrl+a` `-` | Split Vertical |
| **Tmux** | `Ctrl+h/j/k/l` | Navigate Panes (Vim style) |
| **Yazi** | `Ctrl+p` | Native QuickLook Preview |
| **Yazi** | `gr` | Go to Git Root |
| **Yazi** | `C` | Compress selection (ouch) |
| **Yazi** | `c` `m` | Change Permissions (chmod) |
| **Yazi** | `l` / `Enter` | Smart Enter |
| **Neovim** | `<Space>` | Leader Key |
| **Neovim** | `<Space>sf` | Search Files (Telescope) |
| **Neovim** | `<Space>sg` | Search Grep (Telescope) |
| **Neovim** | `<Space>xx` | Toggle Diagnostics (Trouble) |
| **Neovim** | `<Space>cs` | Document Symbols (Trouble) |

## 🔄 Maintenance

To update the entire system (Brew, Tmux plugins, Vim plugins, Firmware, etc.):

```bash
topgrade
```

**Restoring Yazi Plugins:**
When setting up on a new machine, run:
```bash
ya pkg install
```
