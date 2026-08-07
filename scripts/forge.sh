#!/usr/bin/env bash
# ============================================================
# rimochan-nyamuru-manga-forge / forge.sh
#   OMNY（漫画ネームYAML）→ 完成原稿PNG を焼くドライバ
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 使い方:
#   ./scripts/forge.sh -n <OMNYファイル> [オプション]
#
# 必須:
#   -n, --omny <path>      OMNYファイル（ネームデータ）
#
# よく使うオプション:
#   -p, --pages <N>        ページ数（省略時はOMNYの meta.page_count を読む）
#   -o, --out <dir>        出力先ディレクトリ（既定: ./out/<OMNY名>）
#   -a, --omay <path>      OMAYファイル（既定: omay/standard.omay.yaml）
#   -r, --ref <path>       リファレンス画像。複数回指定可（最大3枚推奨）
#   -m, --memo <text>      作品固有の追加指示（画風・気をつけてほしいこと等）
#   -h, --help             このヘルプ
#
# 例:
#   ./scripts/forge.sh -n my.omny.yaml -r chars/hero.png -r chars/rival.png \
#       -m "画風はクレヨン画。1コマ目の背景は夕焼けにしてほしい"
#
# 前提:
#   - codex CLI がインストール済み & ログイン済み（画像生成が使えるプラン）
#   - `codex --version` が通ること
#
# 仕組み（詳しくは docs/pitfalls.md）:
#   page1 は `codex exec -i <refs>` で新規セッションを立ち上げ、
#   page2 以降は `codex exec resume --last` で同じ会話を継続する。
#   同じ会話を使うことでキャラデザ・背景・画風がページ間で一貫する。
# ============================================================
set -uo pipefail

OMNY=""; PAGES=""; OUT=""; OMAY=""; MEMO=""
REFS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--omny)  OMNY="$2"; shift 2;;
    -p|--pages) PAGES="$2"; shift 2;;
    -o|--out)   OUT="$2"; shift 2;;
    -a|--omay)  OMAY="$2"; shift 2;;
    -r|--ref)   REFS+=("$2"); shift 2;;
    -m|--memo)  MEMO="$2"; shift 2;;
    -h|--help)  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -z "$OMNY" ]] && { echo "ERROR: -n <OMNYファイル> は必須なのだ" >&2; exit 1; }
[[ -f "$OMNY" ]] || { echo "ERROR: OMNYが見つからない: $OMNY" >&2; exit 1; }
[[ -z "$OMAY" ]] && OMAY="$HERE/omay/standard.omay.yaml"
[[ -f "$OMAY" ]] || { echo "ERROR: OMAYが見つからない: $OMAY" >&2; exit 1; }

BASENAME="$(basename "$OMNY")"; BASENAME="${BASENAME%%.*}"
[[ -z "$OUT" ]] && OUT="$HERE/out/$BASENAME"
mkdir -p "$OUT"
LOG="$OUT/forge.log"; : > "$LOG"

# ページ数を OMNY から推定（-p 未指定時）
if [[ -z "$PAGES" ]]; then
  PAGES=$(grep -oE 'page_count:[[:space:]]*[0-9]+' "$OMNY" | head -1 | grep -oE '[0-9]+' || true)
  [[ -z "$PAGES" ]] && PAGES=$(grep -cE '^[[:space:]]*-[[:space:]]*page:[[:space:]]*[0-9]+' "$OMNY" || true)
  [[ -z "$PAGES" || "$PAGES" == "0" ]] && { echo "ERROR: ページ数が判定できないのだ。-p で指定してほしいのだ" >&2; exit 1; }
fi

command -v codex >/dev/null || { echo "ERROR: codex CLI が見つからないのだ。docs/setup.md を見てほしいのだ" >&2; exit 1; }

REF_ARGS=()
for r in "${REFS[@]:-}"; do
  [[ -z "$r" ]] && continue
  [[ -f "$r" ]] || { echo "WARN: リファレンスが見つからないので飛ばすのだ: $r" >&2; continue; }
  REF_ARGS+=(-i "$r")
done

OMAY_BODY="$(cat "$OMAY")"
OMNY_BODY="$(cat "$OMNY")"

echo "=== forge start: $BASENAME / ${PAGES}ページ / refs=${#REF_ARGS[@]} ===" | tee -a "$LOG"

# ------------------------------------------------------------
# 🚨 成果物強制ブロック（これが無いと宣言だけで終わる。docs/pitfalls.md 参照）
# ------------------------------------------------------------
forcing_block() {
  cat <<EOS
🚨**いま画像生成ツールを実際に呼び出して、${1}の画像を1枚生成してほしい**。
計画や宣言だけで終わらせず、**生成したPNGの絶対パスを最後に1行で出力**してほしい。
ドキュメントは読まなくていい。
EOS
}

# ------------------------------------------------------------
# page1: 新規セッション（OMAY全文 + OMNY全文 + リファレンスを渡す）
# ------------------------------------------------------------
echo "[$(date +%H:%M:%S)] ===== page1 =====" >> "$LOG"
cat <<PROMPT | codex exec "${REF_ARGS[@]}" >> "$LOG" 2>&1
$(forcing_block "page1")

これから**全${PAGES}ページの漫画**を1ページずつ描いてほしい。
**2つのファイル**を渡す。①OMAY（作画・演出ルールとレイアウト仕様）②OMNY（ネームデータ）。
**OMAYのルールに従ってOMNYの内容を描く**こと。

【進め方】
- 全${PAGES}ページを「1ページ=1枚の独立した画像」として描く。1枚にまとめる/見開きは禁止
- **まず page1 だけ描く**。そのあと続けて page2 以降を依頼する
- セリフは OMNY 記載どおりの日本語で、はっきり読みやすく
- **フキダシには尻尾を付けて、先端を話者の口元へ向ける**（caption・handwritten は尻尾なし）
- ページヘッダーは左上に作品タイトル、右上に「1/${PAGES}」

${MEMO:+【この作品について】
$MEMO
}
===== ① OMAY（作画・レイアウト規則） =====
$OMAY_BODY

===== ② OMNY（ネームデータ・全${PAGES}ページ） =====
$OMNY_BODY
PROMPT
echo "[$(date +%H:%M:%S)] page1 done" >> "$LOG"

# ------------------------------------------------------------
# page2..N: 同じ会話を resume して継続（キャラデザ・画風の一貫性のため）
# ------------------------------------------------------------
for ((p=2; p<=PAGES; p++)); do
  echo "[$(date +%H:%M:%S)] ===== page$p =====" >> "$LOG"
  codex exec resume --last "$(forcing_block "page$p")

つづき。さっき渡したOMAYのルールとOMNYのネームどおりに **page${p} を1枚だけ**描いてほしい。
キャラクターデザイン・背景の内装・画風・小物のデザインは、**前のページと必ず一貫**させること。
**フキダシの尻尾は話者の口元へ**向ける。ヘッダーは右上に「${p}/${PAGES}」。
${MEMO:+
（作品メモ再掲）$MEMO}" >> "$LOG" 2>&1
  echo "[$(date +%H:%M:%S)] page$p done" >> "$LOG"
done

echo "=== forge done. 回収するのだ ===" | tee -a "$LOG"
"$HERE/scripts/collect.sh" --log "$LOG" --out "$OUT" --pages "$PAGES"
