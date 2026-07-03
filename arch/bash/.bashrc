#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.cargo/bin:$PATH"

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

# ウィンドウを閉じた時の自動片付け
trap 'fusermount3 -u ~/uec_sol 2>/dev/null; fusermount3 -u ~/uec_ced 2>/dev/null; fusermount3 -u ~/uec_ied 2>/dev/null' EXIT

# WSL2起動時、Windowsパスにいたらホームに移動
if [[ "$(pwd)" == /mnt/* ]]; then
    cd ~
fi

# WSL2: Zed CLIへのパスを通す（appendWindowsPath=falseの補完）
if grep -qi "microsoft" /proc/version 2>/dev/null; then
    export PATH="$PATH:/mnt/c/Users/Mylot/AppData/Local/Programs/Zed/bin"
fi

# dotfiles自動同期

if grep -qi "microsoft" /proc/version 2>/dev/null; then
    (cd ~/dotfiles && git pull --quiet 2>/dev/null &)
fi

alias zenn-preview='npx zenn preview --host 0.0.0.0'
alias zed='zeditor'
