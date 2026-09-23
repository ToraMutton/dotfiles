#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ===== Environment =====

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ===== Aliases =====

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias zed='zeditor'
alias zenn-preview='npx zenn preview --host 0.0.0.0'

if [[ -x "$HOME/.local/bin/fastfetch-themed" ]]; then
    alias fastfetch="$HOME/.local/bin/fastfetch-themed"
fi

# ===== Prompt =====
# Powerline-style: [ user ][ @host ][  cwd ]
#                  ❯

source "$HOME/.config/bash/palette.bash"

_cap=$'' _sep=$'' _folder=$''

PS1="\[\e[0m\e[38;2;${palette_white}m\]${_cap}"
PS1+="\[\e[48;2;${palette_white}m\e[38;2;${palette_ink}m\] \u "
# Thin gray band between the white and blue segments.
PS1+="\[\e[48;2;${palette_gray}m\e[38;2;${palette_white}m\]${_sep}"
PS1+="\[\e[48;2;${palette_blue}m\e[38;2;${palette_gray}m\]${_sep}"
PS1+="\[\e[38;2;${palette_ink}m\] @\h "
PS1+="\[\e[48;2;${palette_charcoal}m\e[38;2;${palette_blue}m\]${_sep}"
PS1+="\[\e[38;2;${palette_white}m\] ${_folder} \w "
PS1+="\[\e[49m\e[38;2;${palette_charcoal}m\]${_sep}\[\e[0m\]"
PS1+="\n\[\e[38;2;${palette_blue}m\]❯\[\e[0m\] "

unset _cap _sep _folder "${!palette_@}"

# ===== UEC servers (SSHFS) =====
# `<name>` mounts ~/uec_<name> and cd's into it; `un<name>` unmounts it.
# Add a server by adding one entry: [name]=<ssh host>.

declare -A _uec_hosts=(
    [sol]=uec-sol
    [ced]=ced-orange
    [ied]=ied
)

# Mounts made by this shell, cleaned up when it exits.
_uec_mounted=()

_uec_mount() {
    local name=$1 dir="$HOME/uec_$1"
    mkdir -p "$dir"
    if ! mountpoint -q "$dir"; then
        echo "${name}に接続中..."
        sshfs "${_uec_hosts[$name]}": "$dir" || { echo "接続失敗"; return 1; }
        _uec_mounted+=("$dir")
    fi
    cd "$dir"
}

_uec_unmount() {
    local name=$1 dir="$HOME/uec_$1"
    # A shell whose cwd is inside the mount keeps it busy.
    [[ $PWD == "$dir" || $PWD == "$dir"/* ]] && cd ~
    fusermount3 -u "$dir" && echo "${name}を切断しました"
}

# fusermount3 -u refuses busy mounts, so ones still in use elsewhere survive.
_uec_cleanup() {
    local dir
    for dir in "${_uec_mounted[@]}"; do
        fusermount3 -u "$dir" 2>/dev/null
    done
}
trap _uec_cleanup EXIT

for _name in "${!_uec_hosts[@]}"; do
    eval "${_name}() { _uec_mount ${_name}; }"
    eval "un${_name}() { _uec_unmount ${_name}; }"
done
unset _name

# ===== Machine-specific settings =====

_dotfiles_machine_bashrc="$HOME/.config/bash/machines/$(uname -n).bashrc"
if [[ -r "$_dotfiles_machine_bashrc" ]]; then
    source "$_dotfiles_machine_bashrc"
fi
unset _dotfiles_machine_bashrc

# ===== Greeting =====
# Once per Ghostty window/tab. The exported flag keeps nested shells quiet.

if [[ -n ${GHOSTTY_RESOURCES_DIR:-} && -z ${SSH_CONNECTION:-} && -z ${GREETING_SHOWN:-} ]] \
    && [[ -x "$HOME/.local/bin/greeting" ]]; then
    export GREETING_SHOWN=1
    "$HOME/.local/bin/greeting"
fi
