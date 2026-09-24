# rigel-14: B2 後期の Google Drive 同期

`~/Documents/B2/後期` を通常のローカルフォルダとして使い、ログイン中は systemd ユーザータイマーから約 5 分ごとに rclone bisync を実行する。マウントではないので、ネット接続がなくてもローカルのファイルを開ける。初回同期が成功するまでタイマーは有効にしない。

## 初回準備

1. マイドライブ直下の大学用 `B2` と後期フォルダの ID をブラウザの URL で確認する。同期先は後期フォルダの ID で固定する。旧 Windows PC の `Documents` 側は対象外。
2. rclone の専用設定を Git 管理外に作り、本人がブラウザで Google アカウントを認証する。既存の暗号化された `~/.config/rclone/rclone.conf` は使用・変更しない。

   ```bash
   install -d -m 700 ~/.config/rclone-lecture-sync
   RCLONE_CONFIG="$HOME/.config/rclone-lecture-sync/rclone.conf" rclone config
   chmod 600 ~/.config/rclone-lecture-sync/rclone.conf
   ```

   新しい remote 名は `rigel14_lectures`、種類は `drive`、スコープは読み書き可能な `drive` にする。Advanced config の `root_folder_id` には大学用 `B2` の **親フォルダ ID** を入力する。認証時には目的の Google アカウントを選ぶ。認証情報や設定ファイルを dotfiles、Git、同期対象フォルダに置かない。

   rclone の共有 Google Drive client ID は 2026 年中に廃止予定。長期運用には [rclone の公式手順](https://rclone.org/drive/#making-your-own-client-id) で本人用の OAuth Desktop client を作り、client ID と secret をこの専用設定に入力してブラウザで再認証する。secret はチャットにも Git にも貼らない。Google の OAuth アプリを Testing のままにすると付与が短期で失効するため、公式手順の公開設定も確認する。
3. 対象を ID と名前で記録し、接続を確認する。`FOLDER_ID` は `後期` 自体の ID、`FOLDER_NAME` は Drive 上の実名を指定する。

   ```bash
   ~/dotfiles/scripts/rigel-14-lecture-sync set-target FOLDER_ID B2_後期
   rclone --config "$HOME/.config/rclone-lecture-sync/rclone.conf" lsjson rigel14_lectures: --dirs-only
   ```

4. 初回処理を実行する。ローカル既存データは `~/.local/state/rigel-14-lecture-sync/backups/initial-*/local/` にコピーし、Drive 既存データは `B2/.rclone-bisync-backups-後期/initial-*` にコピーする。両方の退避に成功した後だけ、アクセス確認ファイルを置いて dry-run と初回 `--resync-mode newer` を実行する。

   ```bash
   ~/dotfiles/scripts/rigel-14-lecture-sync init
   ```

5. ユニットを配置してタイマーを有効にする。リポジトリのホスト別 profile にこのパッケージが含まれる。ほかの dotfiles を再配置したくない場合は専用パッケージだけ Stow する。

   ```bash
   stow --dir="$HOME/dotfiles/arch" --target="$HOME" --no-folding lecture-sync-rigel-14
   systemctl --user daemon-reload
   systemctl --user enable --now rigel-14-lecture-sync.timer
   ```

## 保護と確認

- 定期実行は対象フォルダの ID とアクセス確認ファイルを検査する。Drive を読めない間は失敗して止まり、次のタイマーで再試行する。`--resilient --recover` は通常の一時エラーや中断からの回復に使う。
- 同時変更は双方の `.conflict*` ファイルとして残す。50% を超える削除は停止し、同期で置き換わる旧版はローカルと Drive のバックアップフォルダに退避する。バックアップは自動削除しない。
- 実行状況: `systemctl --user list-timers rigel-14-lecture-sync.timer`、`systemctl --user status rigel-14-lecture-sync.service`。
- 失敗の詳細: `journalctl --user -u rigel-14-lecture-sync.service -n 100 --no-pager`、`tail -n 100 ~/.local/state/rigel-14-lecture-sync/logs/bisync.log`。接続確認など rclone 実行前の失敗は同じ場所の `runner.log` にも残る。
- `rclone bisync` が再 `--resync` を要求した場合はタイマーを止め、ログと両側のデータ、バックアップを確認してから手動で復旧する。むやみに `--force` や毎回の `--resync` を使わない。

## 動作確認

初回同期後、次を実ファイルで確認する。テスト名には日付などを付けて既存ファイルと区別する。

1. Arch 側で `~/Documents/B2/後期` にテキストを作り、`systemctl --user start rigel-14-lecture-sync.service` の後にスマホの Google Drive アプリまたはブラウザで表示されることを確認する。
2. Drive 側の対象フォルダに別のテキストを作り、サービスを実行して Nautilus の `~/Documents/B2/後期` に現れることを確認する。
3. Wi-Fi を切った状態でローカルのテキストを編集し、サービスが失敗してもファイルが残ることを確認する。再接続してサービスを実行し、Drive 側に反映されることを確認する。
4. ログアウトして再ログインした後、`systemctl --user list-timers` と `journalctl --user -u rigel-14-lecture-sync.service --since today` で自動実行を確認する。

Google ドキュメント形式のファイルは rclone が通常の `.docx` / `.xlsx` / `.pptx` 等に書き出す。形式変換を伴うため、重要な Google ネイティブ文書の移動・改名・編集後は Drive 側を確認する。
