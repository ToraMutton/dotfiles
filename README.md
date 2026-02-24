# My Arch Linux Dotfiles

Arch Linuxの環境設定ファイル（dotfiles）をGNU Stowでスマートに管理するためのリポジトリ。

## 🖥️ System Specs
- **OS**: Arch Linux (& Windows11)
- **Machine**: Trapezium-08 (Custom Build)
- **WM**: Hyprland
- **Bar**: Waybar
- **Editor**: AstroNvim
- **Shell**: Bash

## 🚀 Installation
このリポジトリをクローンしてStowでリンクを張るだけで、データが破損しても環境が元通り！

```bash
git clone git@github.com:ToraMutton/dotfiles.git ~/dotfiles
cd ~/dotfiles
mkdir -p ~/.config
stow bash
stow git
```
