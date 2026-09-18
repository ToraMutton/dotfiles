# rigel-14 graphical login

`rigel-14` 専用の **greetd + Hyprland + Quickshell** グラフィカルログイン構成です。

ホームディレクトリ向けの GNU Stow パッケージではありません。`/etc/greetd` は root 所有の実体ファイルとして管理し、このディレクトリの内容を `install.sh` で複製します。

## Structure

```text
system/rigel-14/greetd/
├── config.toml   # greetd: VT1 で専用 Hyprland セッションを起動
├── hyprland.lua  # greeter 専用の最小 Hyprland 構成
├── shell.qml     # Quickshell ログイン UI
├── install.sh    # dry-run / backup 付きインストーラー
└── README.md
```

## Dependencies

- `greetd`
- `hyprland`（Lua 設定と `start-hyprland` を含む）
- `quickshell-git`（`Quickshell.Services.Greetd` と `Quickshell.Io` を含む）
- `qt6-declarative`
- `qt6-imageformats`
- `qt6-shadertools`
- `qt6-svg`

`greetd-regreet` は稼働中のフォールバック用として残していますが、この UI の実行には使用しません。

## Local assets

壁紙とアバターは著作物なので、このリポジトリには含めません。実機側で次のパスへ配置してください。

```text
/usr/share/backgrounds/rigel-14/login-background.jpg
/usr/share/pixmaps/rigel-14/avatar.jpeg
```

どちらも `greeter` ユーザーから読める必要があります。現在の背景画像は `2880x1800`、内蔵ディスプレイは `eDP-1` の `2560x1600@90`、scale `1.6` を前提としています。

## Install

最初の実行は検査だけで、ファイルやサービスを変更しません。

```bash
cd ~/dotfiles/system/rigel-14/greetd
bash ./install.sh
```

内容を確認後、root 所有のコピーを配置します。

```bash
sudo bash ./install.sh --apply
```

適用時は既存の設定を `/var/backups/rigel-14-greetd/<UTC timestamp>/` に退避し、次を enable にします。

- `greetd.service`
- `getty@tty2.service`（復旧用）

スクリプトは greetd の起動・再起動や OS の再起動を行いません。

## Validate before reboot

```bash
sudo Hyprland --verify-config --config /etc/greetd/hyprland.lua
sudo -u greeter test -r /etc/greetd/rigel-greeter/shell.qml
sudo -u greeter test -r /usr/share/backgrounds/rigel-14/login-background.jpg
sudo -u greeter test -r /usr/share/pixmaps/rigel-14/avatar.jpeg
systemctl is-enabled greetd.service getty@tty2.service
```

実運用へ投入するときだけ再起動します。

```bash
sudo systemctl reboot
```

## Recovery

GUI が起動しない場合は `Ctrl + Alt + F2` で TTY2 に入り、greetd を無効化して再起動します。

```bash
sudo systemctl disable greetd.service
sudo systemctl reboot
```

その後、インストール時に表示されたバックアップから `config.toml`、`hyprland.lua`、`shell.qml` を戻せます。

## Behaviour

- パスワード認証後に `/usr/bin/start-hyprland` を直接起動
- 認証失敗後は入力欄へ戻り、再試行可能
- 再起動・電源断は 5 秒以内の二段階クリック
- 通常ユーザーでのプレビュー中は認証・電源操作を実行しない
- ログアウト後は同じ greeter へ即時復帰
- 指紋認証は未導入（将来タスク）
- ハイバネート復帰時は既存セッションを復元し、greetd を経由しない

`NO_AT_BRIDGE=1`、`QT_ACCESSIBILITY=0`、`QT_LINUX_ACCESSIBILITY_ALWAYS_ON=0` は greeter セッションだけに設定しています。これによりログイン後に greeter の AT-SPI / D-Bus / PipeWire 系ユーザープロセスが残留するのを防ぎます。

## Day 8 validated state

2026-09-18 に以下を実機で確認済みです。

- 正しいパスワード / 誤ったパスワードからの再試行
- ログアウト → greeter → 再ログイン
- TTY2 への退避と GUI 復帰
- 再起動後の自動起動
- UI からの再起動 / 電源断
- ACPI S4 ハイバネート復帰
- ELAN タッチパッド暴走の再発なし
- ログイン後の greeter セッション・プロセス残留なし
- failed units: `0`

検証時の主要ファイル SHA-256:

```text
d2492aeead9f8812d3d991ac4707482a5df041791fbd57cc090cc41987ffbf7c  /etc/greetd/config.toml
da998966f3e41809fef86b4ef283d64c29f201a42062ab7f648bee7a1baf3870  /etc/greetd/hyprland.lua
7270dc89abcaeb93619c6ef8c2132c41c6f477fb333ce7077ab7473695f188bd  /etc/greetd/rigel-greeter/shell.qml
```
