# ⚡️ Custom Sesh Workflows Guide

Your Sesh setup is "Smart". It detects the context of your project and picks the right layout automatically.

## 🧠 How It Works

1.  **Entry Point:** When you connect to a session, `~/.config/sesh/sesh.toml` executes the **Startup Script** (`scripts/startup`).
2.  **The Brain:** The `startup` script checks:
    *   Is this the `dotfiles` session?
    *   Is this a **Coding Project**? (Contains `.git`, `.jj`, `package.json`, etc.)
    *   Or is it just a random folder?
3.  **The Action:** Based on the check, it runs a specific **Workflow Script** (e.g., `workflow_coding`, `workflow_default`).

---

## 🛠 How to Create a New Workflow

### Step 1: Create the Layout Script
Go to your scripts folder:
```bash
cd ~/.config/sesh/scripts
```
Copy an existing workflow to start:
```bash
cp workflow_default workflow_mycustom
```
Edit it (`nvim workflow_mycustom`). Defining windows looks like this:

```bash
# 1. Create the window (starts a shell automatically)
tmux new-window -t "${session}" -n "MyWindow" -c "$root"

# 2. Type a command into it (Optional)
# We use send-keys so the window STAYS OPEN if the command exits!
tmux send-keys -t "${session}:MyWindow" "top" C-m
```

### Step 2: Register it in the "Brain"
Edit the startup script:
```bash
nvim ~/.config/sesh/scripts/startup
```
Add logic to pick your new workflow. For example, if you want a special layout for "python" projects:

```bash
# ... inside the if/else block ...

elif [[ -f "$root/pyproject.toml" ]]; then
    source "$scripts_dir/workflow_mycustom" "$session" "$root"

# ...
```

---

## 💎 Alternative: Tmuxinator (Static Layouts)
For fixed, named projects (like `dotfiles` or a specific work project) where you always want the *exact same* complex setup, use **Tmuxinator**.

1.  Create a config: `~/.config/tmuxinator/myproject.yml`
2.  Sesh will automatically detect it.
3.  Select it in the launcher (`Prefix + K`) under the Tmuxinator section.

*Use Tmuxinator for "Pet Projects". Use Sesh Scripts for "Every Project".*
