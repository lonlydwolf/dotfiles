# ==================================================
# Prompt
# ==================================================
#
# A block of context above a bare caret, shaped like the tip of `jj log`:
#
#   ○ main+1  what the parent change does              go 1.27   user
#   @ mttw M1 ◌ +4 −1  repo/path
#   ❯
#
# Starship reports the pieces (the `block` profiles in starship.toml), one jj
# call reports the parent, and this file lays them out. A prompt is built once
# and kept in variables, so redraws, vi-mode switches and window resizes start
# no process. A finished line collapses to "› command".
#
# Written against Starship 1.27. An older one that lacks the profiles or the jj
# modules leaves the path alone in the block.
#
# Settings, and what each one decides:
#
#   identity  always | away       OS logo and user: always, or only when remote or root
#   lang      arrival | detected  language: on entering a project, or wherever detected
#   outcome   live | keep         failures and long runs: until the next Enter, or kept
#
# The defaults:

typeset -gA _tip_opt=(identity always lang arrival outcome live)

# A shell counts as remote when it carries SSH's variables. Sessions that
# outlive their connection, or never had one, can say so: TIP_REMOTE=1 or 0.

if (( ! $+commands[starship] )); then
    PROMPT='%~ %(?.%F{green}.%F{red})❯%f '
    return
fi

# Starship's init records the status and run time of each command and redraws
# the prompt when the vi mode changes. Its own PROMPT is replaced below.
eval "$(starship init zsh)"
setopt promptsubst
RPROMPT=''

# --------------------------------------------------
# State
# --------------------------------------------------

# Catppuccin Mocha, as in starship.toml.
typeset -gA _tip_c=(
    text '#cdd6f4' dim '#7f849c' faint '#585b70' mauve '#cba6f7' green '#a6e3a1'
    peach '#fab387' red '#f38ba8' yellow '#f9e2af' blue '#89b4fa' sapphire '#74c7ec'
)

# The pieces of the block, as gathered, and the block as laid out.
typeset -g _tip_parent='' _tip_desc='' _tip_node='' _tip_node_short=''
typeset -g _tip_lang='' _tip_who='' _tip_out='' _tip_block=''
typeset -g _tip_ins='' _tip_cmd='' _tip_root='' _tip_kind='' _tip_key=$'\x01'
typeset -gi _tip_loud=0

# The caret is chosen by zsh as it draws, from the keymap in force.
typeset -g _TIP_PROMPT='${_tip_block}${${${KEYMAP:-viins}:#vicmd}:+$_tip_ins}${${(M)KEYMAP:#vicmd}:+$_tip_cmd} '

# @, its parent, and the line from the parent back to its nearest bookmarked
# ancestor. A merge is followed through its first parent only, so the rows
# after @ are one line of history and their number is the distance. None of
# it depends on the working copy, so jj is told not to snapshot. It is also
# told not to wrap, so that each change stays one row.
typeset -g _tip_line='first_ancestors(first_parent(@))'
typeset -ga _tip_jj=(
    command jj --ignore-working-copy --no-pager --color=never
    --config ui.log-word-wrap=false log --no-graph
    -r "@ | first_parent(@) | (heads($_tip_line & bookmarks())::first_parent(@) & $_tip_line)"
    -T 'if(immutable, "I", "M") ++ if(conflict, "C", "") ++ if(root, "R", "") ++ "\x1f" ++ local_bookmarks.map(|b| b.name()).join(" ") ++ "\x1f" ++ description.first_line() ++ "\n"'
)

# --------------------------------------------------
# Helpers
# --------------------------------------------------

# Milliseconds → REPLY: 6.1s, 48s, 3′12″, 1h02′
_tip_duration() {
    local -i ms=$1 h m s
    if (( ms < 10000 )); then
        REPLY="$(( ms / 1000 )).$(( ms % 1000 / 100 ))s"
    elif (( ms < 60000 )); then
        REPLY="$(( ms / 1000 ))s"
    elif (( ms < 3600000 )); then
        (( m = ms / 60000, s = ms % 60000 / 1000 ))
        REPLY="${m}′${(l:2::0:)s}″"
    else
        (( h = ms / 3600000, m = ms % 3600000 / 60000 ))
        REPLY="${h}h${(l:2::0:)m}′"
    fi
}

# Visible width of a prompt string → REPLY
_tip_width() {
    setopt localoptions extendedglob
    local s=${(S)1//\%\{*\%\}/}
    s=${(S)s//\%([Bbf]|F\{*\})/}
    s=${(%)s}
    REPLY=${(m)#s}
}

# Nearest repository above $PWD → _tip_root and _tip_kind (jj, git or empty)
_tip_project() {
    local d=$PWD
    _tip_root='' _tip_kind=''
    while [[ $d != / ]]; do
        if [[ -d $d/.jj ]]; then _tip_root=$d _tip_kind=jj; return; fi
        if [[ -e $d/.git ]]; then _tip_root=$d _tip_kind=git; return; fi
        d=${d:h}
    done
}

# --------------------------------------------------
# Building the block
# --------------------------------------------------

# Ask Starship and jj, side by side, and turn their answers into the pieces.
# $1 = 1 to ask for the language too. Expects _tip_project to have run.
_tip_gather() {
    setopt localoptions extendedglob
    local -a f rows me parent anchor
    local fd='' out='' raw plain node here id profile=block
    local -i dist n remote=0
    (( $1 )) && profile=block_lang

    if [[ $_tip_kind == jj ]] && (( $+commands[jj] )); then
        exec {fd}< <($_tip_jj 2>/dev/null)
    fi
    {
        raw=$(starship prompt --profile $profile 2>/dev/null)
        [[ -n $fd ]] && IFS= read -r -d '' -u $fd out
    } always {
        # also when Ctrl-C cuts the wait short
        [[ -n $fd ]] && exec {fd}<&-
    }
    # repository state, path, language, OS, user, host
    f=("${(@ps:\x1f:)${raw#$'\n'}}")
    (( $#f == 6 )) || f=('' '' '' '' '' '')
    here="%F{$_tip_c[text]}${${(%):-%1~}//\%/%%}%f"
    [[ -n $f[2] ]] || f[2]="%F{$_tip_c[text]}${${(%):-%~}//\%/%%}%f"

    # The row of the working copy: node, state, path. Bookmark names and
    # descriptions come from the repository, so (V) spells out any control
    # character in them (^[ for escape) and none reaches the terminal.
    _tip_parent='' _tip_desc=''
    if [[ $_tip_kind == jj && -n $f[1] ]]; then
        plain=${(S)f[1]//\%\{*\%\}/}
        node="%F{$_tip_c[green]}@%f"
        [[ $plain == *' '[MADRC]<->* ]] && node="%F{$_tip_c[peach]}@%f"
        [[ $plain == *' immutable'* ]] && node="%F{$_tip_c[sapphire]}◆%f"
        [[ $plain == *' conflict'* ]] && node="%F{$_tip_c[red]}×%f"
        rows=("${(@f)out}")
        rows=(${rows:#})
        if (( $#rows )); then
            me=("${(@ps:\x1f:)rows[1]}")
            [[ -n $me[2] ]] && node+=" %F{$_tip_c[mauve]}${${(V)me[2]}//\%/%%}%f"
        fi
        _tip_node="$node $f[1]  $f[2]"
        _tip_node_short="$node $f[1]  $here"

        # The row above it: the parent, named by its nearest bookmark and how
        # many changes it sits past it.
        if (( $#rows >= 2 )); then
            parent=("${(@ps:\x1f:)rows[2]}")
            anchor=("${(@ps:\x1f:)rows[-1]}")
            (( dist = $#rows - 2 ))
            _tip_parent="%F{$_tip_c[text]}○%f"
            [[ $parent[1] == I* ]] && _tip_parent="%F{$_tip_c[sapphire]}◆%f"
            [[ $parent[1] == *C* ]] && _tip_parent="%F{$_tip_c[red]}×%f"
            if [[ -n $anchor[2] ]]; then
                _tip_parent+=" %F{$_tip_c[mauve]}${${(V)anchor[2]}//\%/%%}%f"
                (( dist > 0 )) && _tip_parent+="%F{$_tip_c[dim]}+$dist%f"
            fi
            _tip_desc=${(V)parent[3]:-(no description set)}
            [[ $parent[1] == *R* ]] && _tip_desc='root()'
        fi
    elif [[ -n $f[1] ]]; then
        _tip_node="$f[1]  $f[2]"
        _tip_node_short="$f[1]  $here"
    else
        _tip_node=$f[2]
        _tip_node_short=$here
    fi

    # The right edge: language, background jobs, identity.
    _tip_lang=$f[3] _tip_who='' _tip_loud=0
    n=${(%):-%j}
    (( n )) && _tip_lang+="%F{$_tip_c[blue]}&$n%f "
    [[ -n ${SSH_CONNECTION-}${SSH_CLIENT-}${SSH_TTY-} ]] && remote=1
    [[ -n ${TIP_REMOTE-} ]] && remote=$TIP_REMOTE
    id="${f[4]:+$f[4] }${f[5]:-%n}"
    if (( remote )); then
        _tip_who="%B%F{$_tip_c[peach]}$id@${f[6]:-%m}%f%b" _tip_loud=1
    elif (( EUID == 0 )); then
        _tip_who="%F{$_tip_c[red]}$id%f" _tip_loud=1
    elif [[ $_tip_opt[identity] == always ]]; then
        _tip_who="%F{$_tip_c[faint]}$id%f"
    fi
}

# Fit the pieces to the window. No process is started, so this also runs when
# the window is resized. Short of room, the right edge gives way first: the
# quiet identity, then the language. A remote or root identity outlasts both.
_tip_layout() {
    local REPLY left=$_tip_parent desc=$_tip_desc node=$_tip_node right top
    local lang=$_tip_lang who=$_tip_who
    local -a edges
    local -i lw rw room pad cut want=0

    _tip_width $node
    (( REPLY >= COLUMNS )) && node=$_tip_node_short
    if [[ -n $left ]]; then
        (( want = ${(m)#desc} < 24 ? ${(m)#desc} : 24 ))
    else
        left=$node desc=''
    fi
    _tip_width $left; lw=$REPLY

    if (( _tip_loud )); then
        edges=("$lang${lang:+${who:+ }}$who" "$who")
    else
        edges=("$lang${lang:+${who:+ }}$who" "$lang" '')
    fi
    for right in "${edges[@]}"; do
        _tip_width $right; rw=$REPLY
        (( room = COLUMNS - lw - rw - 1 - (rw > 0 ? 2 : 0) - (want > 0 ? 2 : 0) ))
        (( room >= want )) && break
    done

    if [[ -n $desc ]] && (( room >= 8 )); then
        if (( ${(m)#desc} > room )); then
            # by display width: a wide character takes two columns, a
            # combining mark none
            (( cut = room - 1 ))
            while (( ${(m)#desc[1,cut]} > room - 1 )); do (( cut-- )); done
            while (( cut < $#desc && ${(m)#desc[1,cut+1]} < room )); do (( cut++ )); done
            desc="${desc[1,cut]}…"
        fi
        left+="  %F{$_tip_c[dim]}${desc//\%/%%}%f"
        (( lw += 2 + ${(m)#desc} ))
    fi
    top=$left
    (( pad = COLUMNS - lw - rw - 1 ))
    [[ -n $right ]] && (( pad >= 2 )) && top+="${(l:pad:: :):-}$right"

    # outcome of the last command, a blank line, then one or two rows
    _tip_block=$_tip_out$'\n'$top$'\n'
    [[ -n $_tip_parent ]] && _tip_block+=$node$'\n'
}

# Runs before every prompt.
_tip_build() {
    local REPLY note='' sig='' key
    local -i ms=${STARSHIP_DURATION:--1} st=${STARSHIP_CMD_STATUS:-0} lang=0

    # Back from the collapsed "› ". Done first, so that a build cut short by
    # Ctrl-C shows the last block rather than none.
    PROMPT=$_TIP_PROMPT
    RPROMPT=''

    # How the last command ended. A quick success leaves nothing.
    _tip_out=''
    _tip_ins="%F{$_tip_c[green]}❯%f" _tip_cmd="%F{$_tip_c[blue]}❮%f"
    if (( ms >= 0 )); then
        if (( st > 128 && st - 127 <= $#signals )); then sig=${signals[st - 127]}; fi
        if [[ $sig == INT ]]; then
            note="%F{$_tip_c[yellow]}interrupted%f"
        elif (( st != 0 )) && [[ $sig != (TSTP|STOP|TTIN|TTOU) ]]; then
            _tip_ins="%F{$_tip_c[red]}❯%f"
            if (( ${#STARSHIP_PIPE_STATUS} > 1 )); then
                note="%F{$_tip_c[red]}exit ${(j:|:)STARSHIP_PIPE_STATUS}%f"
            else
                note="%F{$_tip_c[red]}exit $st${sig:+ $sig}%f"
            fi
        fi
        if (( ms >= 2000 )); then
            _tip_duration $ms
            [[ -n $note ]] && note+=" %F{$_tip_c[faint]}·%f "
            note+="%F{$_tip_c[dim]}$REPLY%f"
        fi
        if [[ -n $note ]]; then
            if [[ $_tip_opt[outcome] == keep ]]; then
                print -rP -- $note
            else
                _tip_out=$note$'\n'
            fi
        fi
    fi

    # The language is news on the first prompt in a project.
    _tip_project
    key=${_tip_root:-$PWD}
    [[ $_tip_opt[lang] == detected || $key != $_tip_key ]] && lang=1
    _tip_key=$key

    _tip_gather $lang
    _tip_layout
    trap '_tip_interrupt; return 130' INT
}
precmd_functions+=(_tip_build)

# --------------------------------------------------
# Transient prompt
# --------------------------------------------------

# On Enter the whole block, the outcome line included, shrinks to "› ".
_tip_collapse() {
    trap - INT
    PROMPT="%F{$_tip_c[dim]}›%f "
    zle .reset-prompt
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-finish _tip_collapse

# Ctrl-C on a half-typed line does not finish it, so it is collapsed here.
# The trap is set by _tip_build and dropped by _tip_collapse, so it exists
# only while a line is being edited. Left in place it would also run when
# Ctrl-C interrupts a command, and its `return` would end only the innermost
# function and let the rest of the command carry on.
_tip_interrupt() {
    zle && _tip_collapse
    return 0
}

TRAPWINCH() {
    zle || return 0
    _tip_layout
    zle .reset-prompt
}
