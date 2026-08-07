# セットアップ

## 1. codex CLI

作画は [codex CLI](https://developers.openai.com/codex/cli) が担当します。**画像生成が使えるプラン**でログインしてください。

```bash
codex --version   # 通ればOK
codex login       # ブラウザが開きます
```

動作確認（1枚だけ生成してみる）:

```bash
cat <<'EOF' | codex exec
🚨 いま画像生成ツールを実際に呼び出して、青い空と入道雲の画像を1枚生成してほしい。
   計画や宣言だけで終わらせず、生成したPNGの絶対パスを最後に1行で出力してほしい。
   ドキュメントは読まなくていい。
EOF
```

最後の行に `.../generated_images/<UUID>/xxx.png` のようなパスが出れば準備完了です。
**宣言だけで終わった場合**は `docs/pitfalls.md` の【罠1】を読んでください（この依頼文はすでに対策済みなので、通常は一発で通ります）。

生成物の置き場所は既定で `~/.codex/generated_images/` です。違う場所なら環境変数で指定できます:

```bash
export CODEX_IMAGE_DIR="/path/to/generated_images"
```

## 2. Claude Code

このリポジトリをスキルとして配置します。

```bash
# ユーザー全体で使う
cp -r rimochan-nyamuru-manga-forge ~/.claude/skills/manga-forge

# または特定プロジェクトだけ
cp -r rimochan-nyamuru-manga-forge <your-project>/.claude/skills/manga-forge
```

Claude Code を起動して「3ページの漫画を描いて」のように頼めば発動します。

## 3. bash

`forge.sh` / `collect.sh` は bash スクリプトです。

- macOS / Linux — そのまま動きます
- **Windows** — Git Bash で動きます（開発環境がこれです）。PowerShell からは
  `bash ./scripts/forge.sh ...` のように呼んでください

実行権限が付いていない場合:

```bash
chmod +x scripts/*.sh
```

## 4. リファレンス画像（任意）

キャラの立ち絵を用意すると、そのキャラで描いてくれます。無くてもネームの `materials.note` を手がかりに作画AIが想像で描くので、**無しでも動きます**。

用意する場合は `docs/characters.md` を読んでください。

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `codex: command not found` | codex CLI が PATH に入っていない。新しいシェルを開くか、フルパスで呼ぶ |
| `Not inside a trusted directory` | 実行場所が git リポジトリの外（ZIPダウンロードで配置した場合など）。リポジトリ直下で `git init` するか、`git clone` で取得し直す |
| `No prompt provided via stdin.` | `-i` の後にプロンプトを直書きしている。heredoc で渡す（罠2） |
| 宣言だけで画像が出ない | 罠1。`forge.sh` は対策済みなので、そのまま再実行してよい |
| 画像が見つからない | `CODEX_IMAGE_DIR` を確認。`out/<作品名>/forge.log` にパスが出ているはず |
| 別作品のキャラが混ざる | 罠3。焼いている最中に他の codex を走らせないこと |
