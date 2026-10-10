# Meltype fcitx5 addon patch

[Meltype](https://github.com/yksr-melt/Meltype) の fcitx5 アドオン（`/usr/lib/fcitx5/meltype.so`）を、候補一覧が使いやすくなるよう修正してビルドし直すためのファイルです。

ホームディレクトリ向けの GNU Stow パッケージではありません。Meltype 本体（`/opt/meltype`）は Meltype の `install.sh --fcitx5` で導入し、アドオンだけをこのディレクトリの `build.sh` で置き換えます。

## Structure

```text
system/meltype-fcitx5/
├── candidate-list.patch        # Meltype v1.1.0 の linux/fcitx5 への修正
├── verify-candidate-list.cpp   # 修正を確かめる fcitx5 testfrontend のテスト
├── build.sh                    # 取得・パッチ・ビルド・検証 (--apply で配置)
└── README.md
```

## What the patch fixes

| 症状 | 原因 | 修正 |
| --- | --- | --- |
| 候補が横一列に並ぶ | 候補一覧に向きを指定していないため、Classic UI の既定（横）になる。Mozc は自分で縦を指定している | `setLayoutHint(Vertical)` |
| 10 番目以降の候補を選んでもページが変わらず、選択のハイライトも消える | 選択位置を `setGlobalCursorIndex()` で設定するだけで、表示ページを動かしていない | `setPage(selected / 9)` |
| Arch の fcitx5 5.1.22 でビルドできない | そのヘッダーが C++20 を必要とするのに、Ubuntu 向けに C++17 を指定している | `CXX_STANDARD 20` |

Caelestia の配色連動テーマ（`arch/caelestia/fcitx5-theme`）は配色と画像だけを決めるもので、これらの症状の原因ではありません。Meltype の候補一覧にも同じテーマが使われます。

## Usage

```sh
system/meltype-fcitx5/build.sh          # ビルドと検証だけ (変更しない)
system/meltype-fcitx5/build.sh --apply  # 加えてバックアップを取り、sudo で配置する
fcitx5 -rd                              # アドオンは再読込できないので Fcitx5 を再起動する
```

検証テストは一時ディレクトリを `HOME` にして実行するため、Meltype の学習データ（`~/.local/share/Meltype`）には触れません。元のアドオンは初回の `--apply` で `${XDG_STATE_HOME:-~/.local/state}/meltype-fcitx5/meltype.so.before-patch` に保存されます。戻すときは、それを `sudo install -m 0755` で `/usr/lib/fcitx5/meltype.so` に戻して Fcitx5 を再起動します。

Meltype を更新すると、そのインストーラーがアドオンを上書きするため、この修正は消えます。新しい版に合わせるときは `MELTYPE_REF=v1.2.0 system/meltype-fcitx5/build.sh` のように試し、パッチが当たらなければ上流の変更を確認してから `candidate-list.patch` を作り直してください。既定のタグ `v1.1.0` は、確認したコミットを指していることも確かめます。

## Mozc との使い分け（rigel-14）

`arch/fcitx5-rigel-14` の設定で、Meltype を既定にし、Mozc は予備としてグループに残しています。Meltype は変換用の Mozc を同梱しているため、`fcitx5-mozc` には依存しません。

| キー | 動作 |
| --- | --- |
| 半角/全角 | Meltype 内の英数 ⇔ 日本語（Fcitx5 の切り替えキーからは外している） |
| Control+Space | 入力メソッドのオン/オフ（keyboard-jp との切り替え） |
| 変換 (Henkan) | 入力メソッドをオンにする |
| Control+変換 | Meltype ⇔ Mozc（keyboard-jp は飛ばす） |
