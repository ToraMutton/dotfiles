#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ===== UEC Server SSHFS Settings =====

_uec_mount() {
    local name="$1"
    local host="$2"
    local dir="$HOME/uec_$name"
    mkdir -p "$dir"
    if ! mountpoint -q "$dir"; then
        echo "${name}に接続中..."
        sshfs "$host": "$dir" || { echo "接続失敗"; return 1; }
    fi
    cd "$dir"
}

sol() { _uec_mount sol uec-sol; }
ced() { _uec_mount ced ced-orange; }
ied() { _uec_mount ied ied; }

# 手動切断
alias unsol="cd ~ && fusermount3 -u ~/uec_sol && echo 'solを切断しました'"
alias unced="cd ~ && fusermount3 -u ~/uec_ced && echo 'cedを切断しました'"
alias unied="cd ~ && fusermount3 -u ~/uec_ied && echo 'iedを切断しました'"

# fastfetch
if [[ -x "$HOME/.local/bin/fastfetch-themed" ]]; then
    alias fastfetch="$HOME/.local/bin/fastfetch-themed"
fi

# ウィンドウを閉じた時の自動片付け
trap '
    fusermount3 -u ~/uec_sol 2>/dev/null
    fusermount3 -u ~/uec_ced 2>/dev/null
    fusermount3 -u ~/uec_ied 2>/dev/null
' EXIT

# WSL2起動時、Windowsパスにいたらホームに移動
if [[ "$(pwd)" == /mnt/* ]]; then
    cd ~
fi

# WSL2: Zed CLIへのパスを通す（appendWindowsPath=falseの補完）
if grep -qi "microsoft" /proc/version 2>/dev/null; then
    _dotfiles_win_cmd="$(command -v cmd.exe || true)"
    [[ -n "$_dotfiles_win_cmd" ]] || _dotfiles_win_cmd="/mnt/c/Windows/System32/cmd.exe"
    if [[ -x "$_dotfiles_win_cmd" ]] && command -v wslpath >/dev/null 2>&1; then
        _dotfiles_win_appdata="$("$_dotfiles_win_cmd" /D /C 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')"
        if [[ -n "$_dotfiles_win_appdata" && "$_dotfiles_win_appdata" != '%LOCALAPPDATA%' ]]; then
            _dotfiles_zed_bin="$(wslpath -u "${_dotfiles_win_appdata}\\Programs\\Zed\\bin" 2>/dev/null)"
            [[ -d "$_dotfiles_zed_bin" ]] && export PATH="$PATH:$_dotfiles_zed_bin"
        fi
    fi
    unset _dotfiles_win_cmd _dotfiles_win_appdata _dotfiles_zed_bin
fi

alias zenn-preview='npx zenn preview --host 0.0.0.0'
alias zed="zeditor"
export PATH=$PATH:/opt/rocm/bin
