use std::process::Command;

// --- Requested Nerd Font Icons -----------------------------------------
const ICON_PARENT: &str = "\u{e725}";       // e725 (Branch Fork Network)
const ICON_BOOKMARK: &str = "\u{e0a0}";     // e0a0
const ICON_DIVERGENT: &str = "󰹹";           // 󰹹
const ICON_CONFLICT: &str = "";            // 
const ICON_MODIFIED: &str = "󰏫";            // 󰏫
const ICON_NO_DESC: &str = "\u{f05a}";       // f05a
const ICON_EMPTY: &str = "";               // Pristine empty state

// --- Truecolor ANSI Escape Sequences (Catppuccin Mocha) ----------------
const COLOR_MAUVE: &str = "\x1b[38;2;203;166;247m";   // Bookmarks
const COLOR_BLUE: &str = "\x1b[38;2;137;180;250m";    // Parent context
const COLOR_GREEN: &str = "\x1b[38;2;166;227;161m";   // Clean / Empty state
const COLOR_PEACH: &str = "\x1b[38;2;250;179;135m";   // Modifications
const COLOR_RED: &str = "\x1b[38;2;243;139;168m";     // Conflicts / Divergence
const COLOR_YELLOW: &str = "\x1b[38;2;249;226;175m";  // Missing description

// CRITICAL FIX: Resets foreground text color ONLY. 
// This leaves Starship's 'bg:surface1' perfectly intact across the entire pill.
const COLOR_RESET_FG: &str = "\x1b[39m";

// Field separator
const SEP: &str = "\x1F";

fn main() {
    let template = format!(
        "change_id.shortest() ++ \"{sep}\" ++ \
         bookmarks.join(\", \") ++ \"{sep}\" ++ \
         if(empty, \"1\", \"0\") ++ \"{sep}\" ++ \
         if(conflict, \"1\", \"0\") ++ \"{sep}\" ++ \
         if(divergent, \"1\", \"0\") ++ \"{sep}\" ++ \
         if(description, \"0\", \"1\") ++ \"{sep}\" ++ \
         parents.map(|p| p.bookmarks().join(\", \")).join(\" | \")",
        sep = SEP
    );

    let output = Command::new("jj")
        .args(["log", "-r", "@", "--no-graph", "-T", &template])
        .output();

    let out = match output {
        Ok(out) if out.status.success() => out,
        _ => std::process::exit(0),
    };

    let full_output = String::from_utf8_lossy(&out.stdout);
    let header = full_output.lines().next().unwrap_or("").trim();

    if header.is_empty() {
        std::process::exit(0);
    }

    let mut fields = header.split(SEP);
    let change_id = fields.next().unwrap_or("");
    let bookmarks = fields.next().unwrap_or("");
    let is_empty = fields.next() == Some("1");
    let has_conflict = fields.next() == Some("1");
    let is_divergent = fields.next() == Some("1");
    let no_description = fields.next() == Some("1");
    let parent_bookmarks = fields.next().unwrap_or("");

    if change_id.is_empty() {
        std::process::exit(0);
    }

    let mut result = String::new();

    // 1. Core Identity (Short Change ID)
    result.push_str(change_id);

    // 2. Location Context (Colorized Anchors)
    if !bookmarks.is_empty() {
        result.push_str(&format!(" {}{}{} {}", COLOR_MAUVE, ICON_BOOKMARK, COLOR_RESET_FG, bookmarks));
    } else if !parent_bookmarks.is_empty() {
        // Updated to use the requested e725 parent icon network coordinate
        result.push_str(&format!(" {}{}{} {}", COLOR_BLUE, ICON_PARENT, COLOR_RESET_FG, parent_bookmarks));
    }

    // 3. Ambient Status Flag Arrays
    let mut states = Vec::new();

    // Conflict / Modification Logic
    if has_conflict {
        states.push(format!("{}{}{}", COLOR_PEACH, ICON_MODIFIED, COLOR_RESET_FG));
        states.push(format!("{}{}{}", COLOR_RED, ICON_CONFLICT, COLOR_RESET_FG));
    } else if is_empty {
        states.push(format!("{}{}{}", COLOR_GREEN, ICON_EMPTY, COLOR_RESET_FG));
    } else {
        states.push(format!("{}{}{}", COLOR_PEACH, ICON_MODIFIED, COLOR_RESET_FG));
    }

    // Divergence Alert
    if is_divergent {
        states.push(format!("{}{}{}", COLOR_RED, ICON_DIVERGENT, COLOR_RESET_FG));
    }

    // Missing Description Notice
    if no_description {
        states.push(format!("{}{}{}", COLOR_YELLOW, ICON_NO_DESC, COLOR_RESET_FG));
    }

    if !states.is_empty() {
        result.push(' ');
        result.push_str(&states.join(" "));
    }

    print!("{}", result);
}
