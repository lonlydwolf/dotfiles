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
| **Updates** | **Topgrade** | Unified system update strategy |
| **Symlinks** | **Stow** | Easy deployment to `~/.config` |

## 🚀 Installation

### 1. Prerequisites
Ensure you have **Homebrew** installed. Then install the core dependencies:

```bash
# Core Tools
brew install git stow starship zoxide fzf fd ripgrep bat eza topgrade yazi tmux zellij neovim

# Fonts (Crucial for icons)
brew install --cask font-jetbrains-mono-nerd-font

# Terminal (Optional if not already installed)
brew install --cask ghostty
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
*   **Prompt:** `oh-my-posh` with a custom "Bubbles Extra" theme.
    *   **Smart Logic:** Language segments (Python, Go, Node, etc.) *only* appear when inside a Git repository.
    *   **Skeleton Mode:** Displays a skull (💀) if multiple languages are detected to keep the prompt clean.
*   **Magic Enter:** Pressing `Enter` on an empty line runs `jj st` (if in a git/jj repo) or `clear` otherwise.
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
*   **Focus Handling:**
    *   **VLC:** Opening video files (`Enter`) triggers `open -a VLC` to ensure the window takes focus.
    *   **QuickLook (`Ctrl+p`):** Uses a custom Swift script (`~/.config/yazi/ql.swift`) to launch a **native** QuickLook panel (no "Debug" title bar) that properly steals focus.
*   **Navigation:** Vim-style bindings.

### 📝 Neovim (The Editor)
*   **Base:** Kickstart.nvim.
*   **Key Plugins:** `blink.cmp` (Completion), `conform.nvim` (Auto-formatting), `neo-tree` (File explorer), `telescope` (Fuzzy finder).
*   **Colorscheme:** Catppuccin Mocha.

## ⌨️ Keybindings Cheat Sheet

| Context | Key | Action |
| :--- | :--- | :--- |
| **Global** | `jk` | Escape (in Insert Mode) |
| **Zsh** | `Enter` | Magic Enter (Git status or Clear) |
| **Zsh** | `Ctrl+t` | FZF File Search |
| **Zsh** | `Ctrl+r` | FZF History Search |
| **Tmux** | `Ctrl+a` | Prefix |
| **Tmux** | `Ctrl+a` `|` | Split Horizontal |
| **Tmux** | `Ctrl+a` `-` | Split Vertical |
| **Tmux** | `Ctrl+h/j/k/l` | Navigate Panes (Vim style) |
| **Yazi** | `Ctrl+p` | Native QuickLook Preview |
| **Neovim** | `<Space>` | Leader Key |
| **Neovim** | `<Space>sf` | Search Files (Telescope) |
| **Neovim** | `<Space>sg` | Search Grep (Telescope) |

## 🔄 Maintenance

To update the entire system (Brew, Tmux plugins, Vim plugins, Firmware, etc.):

```bash
topgrade
```
