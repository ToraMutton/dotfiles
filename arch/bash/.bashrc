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

# sol接続用コマンド
sol() {
    # まだマウントされていなければマウントする
    if ! mountpoint -q ~/uec_sol; then
        echo "solに接続中..."
        sshfs uec-sol: ~/uec_sol
    fi
    cd ~/uec_sol
}

# ced接続用コマンド
ced() {
    if ! mountpoint -q ~/uec_ced; then
        echo "cedに接続中..."
        sshfs ced-orange: ~/uec_ced
    fi
    cd ~/uec_ced
}

# 手動切断用エイリアス（ホームに戻ってから切断しないとエラーになるため）
alias unsol="cd ~ && fusermount3 -u ~/uec_sol && echo 'solを切断しました'"
alias unced="cd ~ && fusermount3 -u ~/uec_ced && echo 'cedを切断しました'"

# ウィンドウを閉じた時の自動片付け（エラー出力は /dev/null に捨てて無視）
trap 'fusermount3 -u ~/uec_sol 2>/dev/null; fusermount3 -u ~/uec_ced 2>/dev/null' EXIT

# WSL2起動時、Windowsパスにいたらホームに移動
if [[ "$(pwd)" == /mnt/* ]]; then
    cd ~
fi

# WSL2: Zed CLIへのパスを通す（appendWindowsPath=falseの補完）
if grep -qi "microsoft" /proc/version 2>/dev/null; then
    export PATH="$PATH:/mnt/c/Users/$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')/AppData/Local/Programs/Zed/bin"
fi
