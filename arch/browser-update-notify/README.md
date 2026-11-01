# browser-update-notify

ブラウザ(既定: `google-chrome` と `chromium`)に**更新が来ているかを確認して、Caelestia の通知で知らせるだけ**の仕組みです。

パッケージのインストール・更新は一切しません。`pacman -Sy` も `-Syu` も `sudo` も使わないので、部分アップグレードも起きません。更新するかどうかの判断と実行は、いつも通り自分で行います。

> 通知は「新しいバージョンが出ている」ことしか教えてくれません。脆弱性が含まれるか、重大かどうかは、バージョン差分からは分からないので、通知文でも断定していません。

## 全体像

```text
systemd --user timer ──(ログイン3分後 / その後6時間ごと)──▶ browser-update-notify check
                                                              │
        ┌─────────────────────────────────────────────────────┤
        ▼                                                     ▼
 公式リポジトリ: checkupdates                         AUR: paru -Qua (無ければ yay -Qua)
        └──────────────┬──────────────────────────────────────┘
                       ▼
        監視対象(packages.conf)だけに絞って old → new を取得
                       ▼
   前回通知した内容と比較 ──新しい更新あり──▶ notify-send ──▶ Caelestia の通知
                       ▼
        $XDG_STATE_HOME/browser-update-notify/state.json に記録
```

### 更新確認のしかた

- 公式リポジトリは `checkupdates` を使います。終了コード 2(更新なし)は正常として扱います。
- `checkupdates`(`pacman-contrib`)が入っていない環境では、同じ仕組みをスクリプト内で再現します。sync DB を**一時ディレクトリにコピーしてそこだけ更新**するので、`/var/lib/pacman/sync` は変更されません。`fakeroot` が必要で、pacman 7 の sandbox は fakeroot 下で動かないため `--disable-sandbox` を付けています(`checkupdates` 自体の挙動と同じ考え方です)。
- AUR は `paru -Qua`、`paru` が無ければ `yay -Qua` です。
- インストールされていない監視対象は無視します。リポジトリ由来のものが無ければ公式側の確認を、AUR 由来のものが無ければ AUR 側の確認を省きます。

### 「更新なし」と「取得失敗」の区別

| 状況 | ログ | 終了コード | 通知 | 状態ファイル |
|---|---|---|---|---|
| 更新なし | `no updates for watched browsers` | 0 | なし | `last_check.result = ok` |
| 更新あり(新規) | `updates available: ...` | 0 | あり | 通知済みとして記録 |
| 更新あり(通知済み) | `already notified ...` | 0 | なし | 変更なし |
| 取得失敗(ネットワーク等) | `error: could not fetch updates (...)` | **75** | なし | `result = error`、`last_success` は更新しない |
| 通知失敗 | `warning: ...` | 0 | 失敗 | 通知済みにしない(次回再試行) |

終了コード 75 は systemd 側で `SuccessExitStatus=75` にしてあるので、ユニットは failed になりません。エラー自体はジャーナルに残ります。リトライはタイマー(6時間後)に任せていて、ループやバックオフはありません。

### 重複通知の防止

`state.json` には「パッケージ名 → 通知した更新先バージョン」を記録します。

- 同じバージョンへの更新は再通知しません。
- 更新先が変わった(例: 157 → 158)り、別のブラウザの更新が増えたりしたら、改めて通知します(そのとき時点の全更新をまとめて表示します)。
- 更新を適用すると、次の確認で古い記録を消します。ただし、取得に失敗した回は消しません(消すと、復旧後に同じ更新を再通知してしまうため)。
- ファイルが壊れていたら `state.json.corrupt` に退避して、空の状態から再開します(このとき1回だけ再通知される可能性があります)。

## ファイル構成

| 場所(リポジトリ内 `arch/browser-update-notify/`) | 展開先 | 役割 |
|---|---|---|
| `.local/bin/browser-update-notify` | `~/.local/bin/` | 本体(Python、標準ライブラリのみ) |
| `.config/systemd/user/browser-update-notify.service` | `~/.config/systemd/user/` | 1回チェックする oneshot |
| `.config/systemd/user/browser-update-notify.timer` | 同上 | ログイン3分後 + 6時間ごと |
| `.config/browser-update-notify/packages.conf` | `~/.config/browser-update-notify/` | 監視対象 |
| `README.md`, `tests/`, `.stow-local-ignore` | (展開されない) | ドキュメントとテスト |

実行時の状態は `~/.local/state/browser-update-notify/`(`$XDG_STATE_HOME` に従います)に置かれ、Git 管理外です。

## 導入

```bash
cd ~/dotfiles
./scripts/stow-arch              # dry-run
./scripts/stow-arch --apply      # 適用(profiles/arch/common.txt に登録済み)

systemctl --user daemon-reload
systemctl --user enable --now browser-update-notify.timer
```

## 運用

### 現在の監視状態を確認する

```bash
browser-update-notify status
```

監視対象とインストール済みバージョン、最後の確認結果(成功か失敗か)、通知済みの更新、通知サーバー、次回のタイマー予定が見られます。

### 手動で更新確認を実行する

```bash
browser-update-notify check              # 通常と同じ(新しい更新があれば通知も出る)
browser-update-notify check --no-notify  # 検出だけ。通知もしないし、通知済みにもしない
echo $?                                  # 0 = 正常 / 75 = 取得失敗
```

### 通知をテストする

```bash
# 見た目の確認(架空のバージョン、状態ファイルは変更しない)
browser-update-notify notify-test

# 検出〜重複防止までの流れを、モックデータで通しで確認
cat > /tmp/mock.txt <<'EOF'
google-chrome 156.0.1-1 -> 157.0.2-1
chromium 156.0.1-1 -> 157.0.2-1
EOF
browser-update-notify check --mock-updates /tmp/mock.txt   # 通知される
browser-update-notify check --mock-updates /tmp/mock.txt   # 2回目は通知されない
sed -i 's/157.0.2-1/158.0.0-1/' /tmp/mock.txt
browser-update-notify check --mock-updates /tmp/mock.txt   # 更新先が変わったので再通知
browser-update-notify reset                                # テスト用の状態を片付ける
```

モックは pacman/AUR を呼ばず、専用の `mock-state.json` を使うので、本物の通知状態には影響しません。

> Caelestia の通知は折りたたみ表示だと本文が3行ほどで切れます。2つ以上のブラウザがあるときは、通知右上の矢印で展開すると全部読めます。

自動テスト(偽の `pacman` / `paru` / `notify-send` などを PATH に置くだけで、実システムには触れません):

```bash
cd ~/dotfiles/arch/browser-update-notify
python3 -m unittest discover -s tests -v
```

### ログを見る

```bash
journalctl --user -u browser-update-notify.service -e
journalctl --user -u browser-update-notify.service --since today -p warning   # 警告・エラーだけ
```

### タイマーを停止・再開する

```bash
systemctl --user stop browser-update-notify.timer       # 一時停止(次回ログインまで)
systemctl --user disable --now browser-update-notify.timer   # 無効化(ログインしても動かない)
systemctl --user enable --now browser-update-notify.timer    # 再開
systemctl --user list-timers browser-update-notify.timer     # 次回の予定
systemctl --user start browser-update-notify.service         # 今すぐ1回実行(ジャーナルに記録される)
```

### 監視対象のブラウザを追加する

`~/.config/browser-update-notify/packages.conf`(実体は `arch/browser-update-notify/.config/browser-update-notify/packages.conf`)に1行足すだけです。再起動や `daemon-reload` は要りません。

```text
# package-name [表示名]
google-chrome   Google Chrome
chromium        Chromium
vivaldi         Vivaldi
brave-bin       Brave
firefox         Firefox
```

入っていないパッケージは無視されるので、先に書いておいても問題ありません。反映は次回の確認からです。すぐ試すには `browser-update-notify check --no-notify` を実行します。

### 同じ更新をもう一度通知させたい

```bash
browser-update-notify reset
browser-update-notify check
```

### 完全にアンインストールする

```bash
systemctl --user disable --now browser-update-notify.timer
rm -rf ~/.local/state/browser-update-notify       # 状態ファイル

# dotfiles 側を外す
#   1. profiles/arch/common.txt から browser-update-notify の行を削除
#   2. Stow のリンクを外す
cd ~/dotfiles
stow --dir=arch --target="$HOME" --no-folding --delete browser-update-notify
systemctl --user daemon-reload
#   3. 不要なら arch/browser-update-notify/ を削除(コミットは自分で)
```

## トラブルシューティング

- **通知が出ない**: `browser-update-notify status` の `Notification server:` を確認します。`NOT AVAILABLE` なら Caelestia が起動していません。通知に失敗した更新は通知済みにならないので、起動後の次回確認で届きます。
- **`could not fetch updates` が続く**: ネットワーク、ミラー、AUR の障害が考えられます。`status` の `Last success` が古くなっていないか見てください。ログイン直後にネットワークが未接続だった場合は、次回(6時間後)まで待つか、`systemctl --user start browser-update-notify.service` で手動実行します。
- **AUR の判定について**: `paru`/`yay` は「更新なし」と「失敗」のどちらも終了コード 1 を返します。そのため、終了コード 1 かつ出力なしで、エラーメッセージ(`error`、`failed`、`timed out` など)が無い場合だけを「更新なし」と判定しています。エラーメッセージの文言が大きく変わると誤判定の可能性があるので、`status` の最終確認時刻と合わせて見てください。
- **`pacman-contrib` を入れた場合**: 何もしなくても、`checkupdates` があれば自動でそちらを使います。
- VCS パッケージ(`-git`)の `--devel` 判定はしません(`-Qua` のみ)。

## 設計メモ

- `OnStartupSec=3min` はユーザーマネージャの起動(=ログイン)から数えます。シャットダウン中の取りこぼしは、次回ログイン後の確認で拾われます。`OnUnitInactiveSec=6h` は前回の実行終了から数えるので、実行が重なりません。
- 同時実行は `flock` で防ぎ、手動実行とタイマーが重なっても二重通知されません。
- 通知は `notify-send`(freedesktop.org Notifications)だけを使い、Caelestia の内部には触れません。送る前に `busctl` で通知サーバーの存在を確認します。DBus のアドレスなどは systemd のユーザーマネージャが持つ環境をそのまま使い、スクリプト側ではハードコードしません。
