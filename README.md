# My Arch Linux Dotfiles

[日本語](#jp) | [English](#en)

---

<a name="jp"></a>
## 概要
Arch Linuxの環境設定ファイル（dotfiles）をGNU Stowでスマートに管理するためのリポジトリ。
このリポジトリをクローンしてStowでリンクを張るだけで、データが破損しても環境が元通り！

## 🖥️ System Specs
| Component | Details |
| :--- | :--- |
| **OS** | Arch Linux (& Windows 11) |
| **Machine** | Trapezium-08 (Custom Build) |
| **WM** | Hyprland |
| **Bar** | Waybar |
| **Editor** | AstroNvim |
| **Shell** | Bash |

## 📦 依存パッケージ
これらの設定を完全に機能させるには、以下のパッケージが必要です。事前にインストールしておいてください。

```bash
# 基本ツールのインストール
sudo pacman -S git stow 

# 必要なソフトウェア (環境に合わせて調整してください)
sudo pacman -S hyprland kitty neovim waybar wlogout
```

## 🚀 インストールとデプロイ

### ⚠️ 注意事項
Stowを実行する際、リンク先に既に同名のディレクトリやファイル（例: `~/.config/kitty`）が存在するとコンフリクトエラーになります。
**必ず事前に既存のバックアップを取るか、削除してから**実行してください。

### 1. リポジトリをクローン
```bash
git clone https://github.com/ToraMutton/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. デプロイ（リンクの作成）
```bash
# ~/.configディレクトリが存在しない場合は作成
mkdir -p ~/.config

# 各モジュールをStowでリンク
stow hypr
stow kitty
stow nvim
stow waybar
stow wlogout
stow mimeapps
```

## 📂 構成
- **hypr**: Hyprlandの設定
- **kitty**: ターミナルエミュレータの設定
- **nvim**: AstroNvimベースのエディタ設定
- **waybar**: ステータスバーのスタイルと設定
- **wlogout**: ログアウトメニューの設定
- **mimeapps**: デフォルトアプリケーションの設定

<br>

---

<a name="en"></a>
## Overview
This is a repository for managing my Arch Linux dotfiles smartly using **GNU Stow**. 
Simply clone this repo and link them with Stow to restore your environment instantly, even if things go south!

## 🖥️ System Specs
| Component | Details |
| :--- | :--- |
| **OS** | Arch Linux (& Windows 11) |
| **Machine** | Trapezium-08 (Custom Build) |
| **WM** | Hyprland |
| **Bar** | Waybar |
| **Editor** | AstroNvim |
| **Shell** | Bash |

## 📦 Dependencies
Make sure you have the following packages installed before deploying the dotfiles.

```bash
# Install core tools
sudo pacman -S git stow 

# Install required software (adjust as needed)
sudo pacman -S hyprland kitty neovim waybar wlogout
```

## 🚀 Installation & Deployment

### ⚠️ Important Note
Before running Stow, ensure that the target directories (e.g., `~/.config/kitty`) do not already exist. 
Stow will throw a conflict error if it finds existing files. **Please backup or remove existing configurations first.**

### 1. Clone the repository
```bash
git clone https://github.com/ToraMutton/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Deploy (Create Symlinks)
```bash
# Create config directory if it doesn't exist 
mkdir -p ~/.config

# Deploy each module
stow hypr
stow kitty
stow nvim
stow waybar
stow wlogout
stow mimeapps
```

## 📂 Structure
- **hypr**: Hyprland configuration
- **kitty**: Terminal emulator settings
- **nvim**: AstroNvim-based editor config
- **waybar**: Status bar styles & config
- **wlogout**: Logout menu configuration
- **mimeapps**: Default applications config
