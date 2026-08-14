# ToraMutton's dotfiles

> Personal dotfiles for an Arch Linux + Hyprland + Caelestia desktop and a Windows 11 + GlazeWM desktop.
>
> Arch configurations are managed with GNU Stow. This repository is a record of my actual environment rather than a drop-in rice for arbitrary machines.

Arch Linux / Hyprland を中心に、普段使っている環境設定を管理している dotfiles リポジトリです。

現在の Arch 環境は **Hyprland の Lua 設定 + Caelestia Shell** を軸に構成しています。

> [!WARNING]
> このリポジトリにはモニター名、解像度、個人用スクリプト、SSH 接続名、アプリの起動コマンドなど、私の環境固有の値が含まれています。
>
> 内容を確認せず、そのまま Stow しないでください。

---

## Overview

| Target              | Stack                                      |
| ------------------- | ------------------------------------------ |
| Arch Linux          | Hyprland + Caelestia Shell + Fcitx5 / Mozc |
| Hyprland config     | Lua                                        |
| Desktop shell       | Caelestia Shell                            |
| Windows 11          | GlazeWM + Zebar                            |
| Editor              | Zed                                        |
| Dotfiles deployment | GNU Stow                                   |

---

# Arch Linux Desktop

現在の Arch デスクトップは、Hyprland に個別ツールを横付けするというより、

```text
Hyprland
   ↕
Caelestia Shell
   ↕
Dynamic colour scheme
   ↕
Wallpaper
```

を一つのデスクトップ環境として噛み合わせる方針で構成しています。

## Design

### Hyprland is managed in Lua

Hyprland の設定は `.conf` ではなく Lua で管理しています。

```text
arch/hypr/.config/hypr/
├── hyprland.lua
└── lua/
    ├── appearance.lua
    ├── autostart.lua
    ├── input.lua
    ├── keybinds.lua
    ├── monitors.lua
    ├── windowrules.lua
    └── workspaces.lua
```

`hyprland.lua` 自体は各モジュールを読み込むだけにして、役割ごとに設定を分割しています。

旧 `.conf` 系設定は廃止済みです。

---

### Caelestia Shell

Caelestia は **Shell / CLI のみ利用**しています。

Caelestia の full dotfiles は導入せず、Hyprland 側は自分で管理しています。

```text
arch/caelestia/.config/caelestia/
├── cli.json
├── shell.json
└── assets/
    └── session/
        └── spinningcat.gif
```

主に以下を Caelestia に任せています。

- Bar
- Launcher
- Dashboard
- Sidebar
- Notifications
- Session / Power menu
- Lock screen
- Screenshot / Screen recording UI
- Wallpaper
- Dynamic colour scheme
- Idle / DPMS management

そして当然、

```text
Session Menu
    ↓
spinningcat.gif
```

も重要な構成要素です。🐈

---

## Appearance

Hyprland 側では、Caelestia の UI を邪魔しない範囲でウィンドウそのものの質感を調整しています。

| Item                | Value / behaviour        |
| ------------------- | ------------------------ |
| Inner gap           | `6`                      |
| Outer gap           | `14`                     |
| Border              | `2px`                    |
| Rounding            | `12`                     |
| Blur                | size `10`, passes `3`    |
| Layout              | `dwindle`                |
| Window animation    | spring + `popin 87%`     |
| Workspace animation | spring + `slidefade 20%` |
| Layer animation     | disabled                 |

Window / Workspace animation は Hyprland 側で spring animation を使用しています。

一方で Caelestia の Launcher / Dashboard / Sidebar などは Caelestia 内部の animation に任せるため、Hyprland の layer animation は無効化しています。

---

## Dynamic colour scheme

壁紙を起点に、Caelestia と Hyprland の色が連動します。

```text
Wallpaper
   ↓
Caelestia dynamic colour scheme
   ↓
Caelestia Shell UI
   ↓
~/.config/hypr/scheme/current.lua
   ↓
Hyprland window borders
```

Hyprland の active border は dynamic palette の `primary` / `tertiary` を利用し、inactive border は `outlineVariant` を利用します。

```lua
active_border = {
    colors = {
        "rgba(" .. scheme.primary .. "ee)",
        "rgba(" .. scheme.tertiary .. "ee)",
    },
    angle = 45,
}

inactive_border = "rgba(" .. scheme.outlineVariant .. "aa)"
```

`arch/hypr/.config/hypr/scheme/current.lua` は runtime-generated file のため Git 管理していません。

Caelestia CLI の theme integration は Hyprland のみ有効にしており、GTK / Qt / terminal / Zed などへ一括適用しない構成です。

---

## Monitor layout

この設定は現在のデュアルモニター構成に固定されています。

| Output     | Mode            | Position    |
| ---------- | --------------- | ----------- |
| `HDMI-A-1` | `2560x1440@75`  | 左 / 縦置き |
| `DP-2`     | `2560x1440@180` | 右 / メイン |

Caelestia の Bar はメインモニター側で利用し、`HDMI-A-1` では非表示にしています。

別環境へ適用する場合は、最初に以下を確認してください。

```text
arch/hypr/.config/hypr/lua/monitors.lua
arch/hypr/.config/hypr/lua/workspaces.lua
```

---

## Caelestia configuration

現在の主な設定です。

### Bar

- メインモニターのみ表示
- Workspace active trail 有効
- Window icons 表示
- Network status 表示
- Battery / Bluetooth / Mic など不要な status icon は非表示
- Workspace scroll 有効
- Volume scroll 有効

### Launcher

- `SUPER + Space`
- Vim keybinds 有効
- 最大表示件数: 9
- Wallpaper 最大表示件数: 9
- Fuzzy search は無効

### Dashboard

- Hover で表示
- Performance information 表示
- Battery information 非表示
- Network information 表示

### Utilities

Quick Toggles は次の3つを使用しています。

- Settings
- Game Mode
- Do Not Disturb

Wi-Fi / Bluetooth / Mic / VPN toggle は非表示です。

### Idle

```text
15 min → Lock
20 min → DPMS off
```

さらに、

- Audio playback 中は idle を inhibit
- Sleep 前に lock
- Automatic suspend は使用しない

というデスクトップ PC 向け構成です。

---

# Keybinds

`SUPER` を main modifier としています。

| Key                    | Action                              |
| ---------------------- | ----------------------------------- |
| `SUPER + Space`        | Caelestia Launcher                  |
| `SUPER + X`            | Session / Power menu                |
| `SUPER + L`            | Lock                                |
| `SUPER + SHIFT + L`    | Suspend                             |
| `SUPER + S`            | Freeze + region picker → clipboard  |
| `SUPER + SHIFT + S`    | Region screenshot                   |
| `SUPER + ALT + S`      | Current output screenshot           |
| `SUPER + R`            | Screen recording                    |
| `SUPER + Q`            | Kitty                               |
| `SUPER + E`            | Dolphin                             |
| `SUPER + Z`            | Zed                                 |
| `SUPER + F`            | Google Chrome                       |
| `SUPER + 1..0`         | Workspace 1..10                     |
| `SUPER + SHIFT + 1..0` | Move window to workspace and follow |
| `SUPER + V`            | Toggle floating                     |
| `SUPER + P`            | Toggle pseudotiling                 |
| `SUPER + J`            | Toggle dwindle split                |
| `SUPER + W`            | Maximize while keeping gaps / bar   |
| `SUPER + SHIFT + W`    | True fullscreen                     |
| `SUPER + Tab`          | Cycle windows                       |
| `SUPER + grave`        | Toggle special workspace            |

Mouse:

```text
SUPER + Left Mouse   → Move window
SUPER + Right Mouse  → Resize window
SUPER + Scroll       → Change workspace
```

詳細は以下を参照してください。

```text
arch/hypr/.config/hypr/lua/keybinds.lua
```

---

# Autostart

Hyprland 起動時には主に次を開始します。

```text
caelestia shell -d
fcitx5 -d
~/scripts/discord-ipc-link.sh
wl-paste --type text  --watch cliphist store
wl-paste --type image --watch cliphist store
```

`~/scripts/discord-ipc-link.sh` はこのリポジトリには含まれていません。

不要な場合は、

```text
arch/hypr/.config/hypr/lua/autostart.lua
```

から削除してください。

---

# Repository structure

```text
.
├── arch/
│   ├── bash/
│   │   └── .bashrc
│   │
│   ├── caelestia/
│   │   └── .config/caelestia/
│   │
│   ├── fcitx5/
│   │   └── .config/fcitx5/
│   │
│   ├── git/
│   │   └── .gitconfig
│   │
│   ├── hypr/
│   │   └── .config/hypr/
│   │
│   ├── kitty/
│   │   └── .config/kitty/
│   │
│   ├── mimeapps/
│   │   └── .config/mimeapps.list
│   │
│   ├── mozc/
│   │
│   ├── waybar/
│   │
│   ├── wlogout/
│   │
│   └── wofi/
│
├── windows/
│   ├── glazewm/
│   └── zebar/
│
├── zed/
│
├── .bashrc
├── .gitconfig
└── README.md
```

Waybar / Wlogout の設定は過去の構成として残していますが、**現在の Arch セッション UI の中心は Caelestia Shell** です。

Wofi は Caelestia Launcher の代替としてではなく、clipboard history selector から現在も利用しています。

---

# GNU Stow

Arch 側の dotfiles は GNU Stow で `$HOME` に展開します。

## Clone

```bash
git clone https://github.com/ToraMutton/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## Dry run first

既存設定へいきなりリンクを張らず、先に dry-run することを推奨します。

```bash
stow -d ~/dotfiles/arch -t ~ --simulate \
  bash \
  git \
  hypr \
  caelestia \
  fcitx5 \
  kitty \
  mimeapps \
  wofi
```

## Apply

```bash
stow -d ~/dotfiles/arch -t ~ \
  bash \
  git \
  hypr \
  caelestia \
  fcitx5 \
  kitty \
  mimeapps \
  wofi
```

新しいファイルやディレクトリを Stow package 側へ追加した場合は、必要に応じて restow します。

```bash
stow -R -d ~/dotfiles/arch -t ~ caelestia
```

例えば Caelestia の custom asset を追加した場合、Stow し直さないと `$HOME/.config/caelestia/` 側から見えないことがあります。

---

# ⚠️ Important: Git branch switching changes the live desktop

このリポジトリの Arch 設定は GNU Stow によって `$HOME` 側へ直接リンクされています。

つまり、

```text
Git working tree
      ↓
GNU Stow symlink
      ↓
~/.config/*
      ↓
running desktop
```

という関係になっています。

そのため **Git branch を切り替えると、稼働中の設定ファイルもその場で切り替わります。**

例えば、

```text
hyprland.lua が存在する branch
          ↓
git switch
          ↓
hyprland.lua が存在しない古い branch
```

と移動すると、実行中の Hyprland が設定ファイルを見失うことがあります。

大きな branch 操作を行う場合は、

1. Working tree を clean にする
2. Backup branch を作る
3. 現在稼働中の config が移動先 branch に存在するか確認する
4. 必要なら checkout せず ref / remote branch の操作だけで済ませる

などの対策を推奨します。

---

# Bash notes

`arch/bash/.bashrc` には個人用設定として次が含まれています。

- UEC server 向け SSHFS mount helper
- Shell 終了時の SSHFS unmount
- WSL2 向け PATH 補正
- Zed alias
- Zenn preview alias
- ROCm path

以前存在していた、

```text
shell exit
   ↓
dotfiles auto commit
   ↓
auto push
```

の仕組みは削除済みです。

Git の commit / push は現在すべて手動で行っています。

---

# Dependencies / external commands

このリポジトリは package manifest ではありません。

設定から直接呼び出している主なツールは次の通りです。

### Desktop

- Hyprland with Lua config support
- Caelestia Shell
- Caelestia CLI
- Quickshell

### Input / Clipboard

- Fcitx5
- Mozc
- `wl-copy`
- `wl-paste`
- `cliphist`
- Wofi

### Audio / Media

- PipeWire
- WirePlumber
- `wpctl`
- `playerctl`

### Desktop utilities

- `hyprpicker`
- Kitty
- Dolphin
- Zed (`zeditor`)
- Google Chrome

### Bash helpers

- `sshfs`
- `fuse3`

必要なものだけ、自分の環境に合わせて導入してください。

Wallpaper files はこのリポジトリでは管理していません。

現在は主に、

```text
~/Pictures/Wallpapers
```

を Caelestia の wallpaper directory として使用しています。

---

# Windows 11

`windows/` には Windows 側のデスクトップ設定を保存しています。

主な構成:

- GlazeWM
- Zebar
- React
- Vite

```text
windows/
├── glazewm/
└── zebar/
    └── toratora-bar/
        ├── ui/
        └── toratora-widget/
```

`ui/` には React + Vite の source、`toratora-widget/` には Zebar が使用する build result を保存しています。

Windows 側のファイルは GNU Stow の対象ではありません。

---

# Zed

`zed/` には Zed の設定を保存しています。

主な内容:

- Vim mode
- Custom keymap
- Format on save
- Language-specific settings
- Edit predictions
- UEC server 向け SSH connection entries

SSH host definition や credentials 自体はこの repository では管理していません。

---

# Philosophy

このリポジトリは「設定可能なものを全部設定する」ことを目的にはしていません。

基本方針は、

> **触る理由があるところだけ触る。**

です。

Upstream の default が十分良い部分はそのまま利用し、自分が明確にこだわりたい部分だけを設定します。

特に現在は、

- Hyprland animation
- Window spacing / appearance
- Wallpaper-driven dynamic colours
- Keybinds
- Desktop PC 向け UI
- Caelestia panel configuration

を明示的に調整しています。

その結果、

```text
Arch Linux
+
Hyprland
+
Caelestia Shell
+
Lua
```

を一つのデスクトップ環境として運用しています。

And yes,

**the spinning cat is intentional.** 🐈🌀
