# ToraMutton's dotfiles

> Personal dotfiles for an Arch Linux + Hyprland desktop and a Windows 11 + GlazeWM desktop.
> Arch configurations are deployed with GNU Stow; Windows and Zed files are kept as explicit, manually applied configurations.

個人用の作業環境を記録・再現するための dotfiles リポジトリです。主役は Arch Linux の Hyprland 環境ですが、Windows 11 の GlazeWM + Zebar と、Zed の設定も同居しています。万人向けの「そのまま入れて完成」セットではなく、ハードウェア・ユーザー名・利用サービスに依存する部分を含む実運用の記録です。

> [!WARNING]
> このリポジトリの設定を無確認で適用しないでください。とくに `arch/bash/.bashrc` はシェル終了時に `~/dotfiles` の変更を自動コミットし、未 push のコミットを自動 push します。また、Hyprland のモニター名・壁紙パス・起動コマンド、Git のユーザー情報、Windows のアプリ起動コマンドには個人環境依存の値があります。

## 概要

| 対象 | 内容 |
| --- | --- |
| Arch Linux | Hyprland を中心とした Wayland デスクトップ。設定は GNU Stow のパッケージとして `arch/` に整理。 |
| Windows 11 | GlazeWM のタイル型ウィンドウ管理と、React/Vite で実装した Zebar バー。 |
| エディタ | Zed の Vim モード、保存時フォーマット、UEC SSH 接続、キーマップ。 |

## Arch Linux 環境の特徴

- **Hyprland**: dwindle レイアウト、半透明・ぼかし・角丸、10 ワークスペース、キーボード中心のウィンドウ操作。
- **デュアルモニター前提**: `HDMI-A-1`（縦置き 2560x1440@75）と `DP-2`（2560x1440@180）を固定指定している。ほかの構成では必ず `workspaces.conf` を先に編集する。
- **Waybar**: メディア操作、日時、CPU・温度・メモリ・ネットワーク・音量・トレイ・電源メニューを表示。`playerctl` と Python スクリプトで再生情報を取得する。
- **日本語入力**: Fcitx5 + Mozc。`Zenkaku_Hankaku` / `Ctrl+Space` などで切り替える設定。
- **Bash**: UEC サーバー向け SSHFS マウント関数、WSL2 向け PATH 補正、Zed 起動用設定を含む。
- **外観**: Kitty、Wofi、Wlogout、Cava、Waybar を青緑系の配色で調整。

## ディレクトリ構成

```text
.
├── arch/                         # GNU Stow で $HOME に展開する Arch Linux 用パッケージ
│   ├── bash/                     # ~/.bashrc
│   ├── cava/                     # ~/.config/cava/
│   ├── fcitx5/                   # ~/.config/fcitx5/
│   ├── git/                      # ~/.gitconfig
│   ├── hypr/                     # ~/.config/hypr/
│   ├── kitty/                    # ~/.config/kitty/
│   ├── mimeapps/                 # ~/.config/mimeapps.list
│   ├── mozc/                     # Mozc のユーザーデータを追跡しないための .gitignore のみ
│   ├── waybar/                   # ~/.config/waybar/
│   ├── wlogout/                  # ~/.config/wlogout/
│   └── wofi/                     # ~/.config/wofi/
├── windows/
│   ├── glazewm/config.yaml        # Windows 11 用タイル型 WM 設定
│   └── zebar/                    # Zebar 設定と自作 toratora-bar パック
│       └── toratora-bar/
│           ├── ui/               # React + Vite のソース
│           └── toratora-widget/  # Zebar が読むビルド済み成果物
├── zed/                          # settings.json と keymap.json
├── .bashrc -> arch/bash/.bashrc   # リポジトリ内での参照用 symlink
└── .gitconfig -> arch/git/.gitconfig
```

`arch/` の直下の各ディレクトリが **Stow パッケージ名** です。`nvim` や `ssh` は現在存在しないため、古い README にあったそれらの Stow コマンドは使えません。

## 主要なツールと設定

| 分類 | ツール / ファイル | 設定していること |
| --- | --- | --- |
| Wayland デスクトップ | Hyprland | 見た目、入力、キーバインド、ウィンドウルール、モニターとワークスペース、起動時プログラム。 |
| バー / 電源メニュー | Waybar / Wlogout | システム状態・メディア表示、電源操作。Waybar は固定の `hwmon3` 温度センサーを参照。 |
| 入力・ランチャー | Fcitx5 + Mozc / Wofi / `hyprlauncher` | 日本語入力とクリップボード履歴の呼び出し。`hyprlauncher` の設定・導入手順はこのリポジトリにはない。 |
| 端末・シェル | Kitty / Bash | Kitty の透明度と Hack Nerd Font、SSHFS 補助関数、WSL2 向け処理。 |
| 音声・メディア | PipeWire/WirePlumber / playerctl / Cava | `wpctl` による音量制御、MPRIS 再生情報、音声スペクトラム用設定。 |
| Git | Git / Git LFS / GitHub CLI | GitHub の noreply アドレス、`gh auth git-credential`、Git LFS フィルター。 |
| Windows | GlazeWM / Zebar | Alt キー主体のタイル操作、9 ワークスペース、Zebar に CPU・GPU・温度・ネットワーク・音量等を表示。 |
| エディタ | Zed | Vim モード、保存時フォーマット、言語別インデント、UEC SSH 接続、Vim 風キーマップ。 |

## 依存関係

### Arch Linux

Stow に必要な最小ツールは次の 2 つです。

```bash
sudo pacman -S --needed git stow
```

設定を機能させるには、少なくとも以下の実行ファイルに対応するソフトウェアが必要です。ディストリビューション標準リポジトリか AUR かは、利用しているパッケージ管理方法で確認してください（ここでは未検証の一括インストールコマンドを載せません）。

- セッション: `hyprland`, `kitty`, `waybar`, `wlogout`, `wofi`, `mako`, `hyprlock`, `hyprpicker`
- 入力・クリップボード: `fcitx5`, Mozc アドオン, `wl-copy` / `wl-paste`, `cliphist`
- 画面・壁紙: `mpvpaper`, `swww`, `hyprshot`, `swappy`
- 音量・メディア: PipeWire + WirePlumber（`wpctl`）, `playerctl`, `cava`
- システム補助: `brightnessctl`, `dolphin`, `google-chrome-stable`, Python 3, Hack Nerd Font
- 任意の Bash 機能: `sshfs`, `fuse3`, GitHub CLI (`gh`), Git LFS

以下は設定から呼び出されるものの、このリポジトリには導入元や設定本体がありません。

- `hyprlauncher`
- `hyprshutdown`（存在しない場合は設定上 `hyprctl dispatch exit` にフォールバックする）
- `~/scripts/discord-ipc-link.sh`
- `~/Pictures/wallpapers/kaguya.png` と `~/Pictures/wallpapers/moonflower.mp4`
- `antigravity`

> TODO: 上記の未同梱コマンド・個人用スクリプトをリポジトリで管理するか、起動設定から外すかを決める。

### Windows 11

- GlazeWM
- Zebar（`windows/zebar/settings.json` は v3.3.1 のスキーマを参照）
- PowerShell（Zebar が GPU 使用率・温度・VPN 状態の取得に使用）
- Node.js と npm（`toratora-bar` の UI を変更して再ビルドする場合のみ）
- `wt`, `explorer`, `chrome`（GlazeWM のキーバインドから起動する場合）

## 安全な導入手順（Arch Linux）

### 1. クローンして内容を確認する

```bash
git clone https://github.com/ToraMutton/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
find arch -maxdepth 2 -type d | sort
```

### 2. 既存設定を退避する

実際にリンクを作る前に、**必要なものだけ**退避する。`~/.config` 全体を削除・置換してはいけません。

```bash
backup_dir="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir/.config"

for name in hypr kitty waybar wlogout wofi cava fcitx5; do
  [ -e "$HOME/.config/$name" ] && mv "$HOME/.config/$name" "$backup_dir/.config/"
done
[ -e "$HOME/.config/mimeapps.list" ] && mv "$HOME/.config/mimeapps.list" "$backup_dir/.config/"
[ -e "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$backup_dir/"
[ -e "$HOME/.gitconfig" ] && mv "$HOME/.gitconfig" "$backup_dir/"
```

### 3. GNU Stow を dry-run する

`--simulate` は何も変更せず、作成予定のリンクと競合を表示します。エラーが出たら次へ進まず、対象だけを確認・退避してください。

```bash
stow --dir=arch --target="$HOME" --no-folding --simulate \
  bash git hypr kitty waybar wlogout wofi fcitx5 cava mimeapps
```

### 4. 問題なければリンクを作成する

```bash
stow --dir=arch --target="$HOME" --no-folding \
  bash git hypr kitty waybar wlogout wofi fcitx5 cava mimeapps
```

`mozc` は追跡対象の設定ファイルを持たず、ユーザーデータを無視するためだけのディレクトリなので Stow の対象に含めません。

### 5. 適用を確認する

```bash
readlink -f "$HOME/.config/hypr/hyprland.conf"
readlink -f "$HOME/.config/waybar/config.jsonc"
readlink -f "$HOME/.bashrc"
```

### Stow の実際の使い方

`arch/` を Stow ディレクトリ、`$HOME` をリンク先として明示するのがこのリポジトリでの使い方です。

| 操作 | コマンド |
| --- | --- |
| 作成予定を確認 | `stow --dir=arch --target="$HOME" --no-folding --simulate hypr` |
| 1 パッケージを適用 | `stow --dir=arch --target="$HOME" --no-folding hypr` |
| 複数を適用 | `stow --dir=arch --target="$HOME" --no-folding hypr waybar kitty` |
| リンクを外す | `stow --dir=arch --target="$HOME" --no-folding --delete hypr` |
| リンクを張り直す | `stow --dir=arch --target="$HOME" --no-folding --restow hypr` |

## 競合と個人環境への注意

- Stow は既存の通常ファイルを上書きしない。競合時は削除せず、退避してから `--simulate` を再実行する。
- `hypr/workspaces.conf` のモニター名・解像度・配置はこの PC 固有。`hyprctl monitors` の結果に合わせて編集する。
- Waybar の `temperature.hwmon-path` は `/sys/class/hwmon/hwmon3/temp1_input` 固定。環境によっては温度表示が壊れるため、`/sys/class/hwmon/` を確認して変更する。
- `mimeapps.list` は HTTP/HTTPS を `google-chrome.desktop` に関連付ける。Chrome を使わない場合は適用前に変更する。
- `.bashrc` の `trap ... EXIT` は SSHFS を unmount し、`~/dotfiles` の変更を Git commit/push する。不要なら **Stow する前に** 該当部分を削除または無効化する。
- `.gitconfig` には個人の GitHub noreply メールアドレス、Git LFS、`gh` の認証ヘルパー、エディタ `nano` が設定されている。共有 PC や別アカウントにはそのまま適用しない。
- Zed の SSH 接続先（`uec-sol`, `ced-orange`, `ied`）は、別途 `~/.ssh/config` にホスト定義と認証情報があることを前提にする。このリポジトリは `arch/ssh/` を意図的に追跡しない。
- `errors.log` は現時点で空ファイル。Zebar のログ保存先・運用方法はリポジトリから確定できない。

## Windows 設定の導入

Windows 側は Stow で展開しません。GlazeWM を起動して既定の設定を生成した後、既存ファイルをバックアップしてからコピーします。GlazeWM の既定設定パスは `%USERPROFILE%\.glzr\glazewm\config.yaml` です。

```powershell
$repo = Join-Path $HOME 'dotfiles'
$dest = Join-Path $HOME '.glzr\glazewm\config.yaml'
$backup = "$dest.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"

New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
if (Test-Path $dest) { Copy-Item $dest $backup }
Copy-Item "$repo\windows\glazewm\config.yaml" $dest
```

Zebar は `windows/zebar/` に設定・パック・ビルド済みウィジェットを含みます。Zebar 側のインポート先・配布手順はこのリポジトリ内で自動化されていないため、既存の Zebar 設定をバックアップしたうえで、アプリの現在の設定ディレクトリと照合して手動で配置してください。

`toratora-bar` を編集した場合だけ、次で成果物を更新します。

```bash
cd windows/zebar/toratora-bar/ui
npm ci
npm run build
```

> TODO: Zebar の設定・パックを Windows のどのパスへ配置するか、およびインポート手順をこのリポジトリで明文化する。

## Zed 設定

`zed/settings.json` と `zed/keymap.json` は Stow パッケージではありません。Zed の OS ごとの設定ディレクトリへコピーする前に、既存の設定とマージしてください。特に `ssh_connections` はローカルの SSH ホスト名に依存します。

> TODO: Linux / Windows それぞれで採用する Zed 設定配置先と、安全な同期方法を決める。

## スクリーンショット

現時点でリポジトリにスクリーンショットはありません。追加する場合は、ルートに `assets/screenshots/` を作成し、用途が分かる名前で保存します。

```text
assets/screenshots/
├── arch-hyprland-overview.png
├── windows-glazewm-zebar.png
└── zebar-toratora-bar.png
```

README から参照する画像は、例えば `![Arch Linux desktop](assets/screenshots/arch-hyprland-overview.png)` の形式で配置します。実機の通知・ユーザー名・ファイルパスなど、公開したくない情報を写さないようにしてください。

## ライセンス・利用上の注意

このリポジトリには現時点で `LICENSE` ファイルがありません。したがって、再配布・改変・商用利用の条件は明示されていません。

設定を参考にする場合は自己責任で、個人情報・認証情報・マシン固有のパスを自分の環境に合わせて置き換えてください。フォント、アイコン、各アプリケーション、Zebar の依存パッケージにはそれぞれのライセンスが適用されます。

> TODO: このリポジトリに適用するライセンスを選び、`LICENSE` ファイルを追加する。