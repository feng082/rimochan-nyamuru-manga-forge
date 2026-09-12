#!/usr/bin/env bash
# ============================================================
# rimochan-nyamuru-manga-forge / collect.sh
#   将 codex 生成的图像回收为 page1.png、page2.png、……
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 用法：
#   ./scripts/collect.sh --log <forge.log> --out <输出目录> [--pages N]
#
# 为什么需要专用脚本：
#   codex 将图像放在 ~/.codex/generated_images/<UUID>/。
#   多个 codex 并行时，按“最新目录”回收会混淆，因此
#   **必须从日志中出现的本次 UUID 目录回收**。
#   （参见 docs/pitfalls.md）
# ============================================================
set -uo pipefail

LOG=""; OUT=""; PAGES=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)   LOG="$2"; shift 2;;
    --out)   OUT="$2"; shift 2;;
    --pages) PAGES="$2"; shift 2;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

[[ -f "$LOG" ]] || { echo "错误：找不到日志：$LOG" >&2; exit 1; }
[[ -n "$OUT" ]] || { echo "错误：必须提供 --out" >&2; exit 1; }
mkdir -p "$OUT"

GEN_ROOT="${CODEX_IMAGE_DIR:-$HOME/.codex/generated_images}"

# 从日志提取 generated_images/<UUID>（仅回收本会话的图像）
UUIDS=$(grep -oiE 'generated_images[/\\][0-9a-f-]{36}' "$LOG" \
        | grep -oiE '[0-9a-f-]{36}' | sort -u)

if [[ -z "$UUIDS" ]]; then
  echo "⚠️ 日志中没有生成图像的路径。" >&2
  echo "   → 很可能只做了声明（请查看 docs/pitfalls.md 的【陷阱 1】）" >&2
  exit 2
fi

# 按生成顺序（mtime 从旧到新）回收为页序
FILES=()
while IFS= read -r u; do
  d="$GEN_ROOT/$u"
  [[ -d "$d" ]] || continue
  while IFS= read -r f; do FILES+=("$f"); done < <(ls -tr "$d"/*.png 2>/dev/null)
done <<< "$UUIDS"

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "⚠️ UUID 目录中没有 PNG：$UUIDS" >&2
  exit 2
fi

i=1
for f in "${FILES[@]}"; do
  cp "$f" "$OUT/page$i.png"
  i=$((i+1))
done
GOT=$((i-1))

echo "✅ 已回收：$GOT 张 → $OUT"
ls -la "$OUT"/page*.png | awk '{print "   " $9, $5"B"}'

if [[ -n "$PAGES" && "$GOT" != "$PAGES" ]]; then
  cat >&2 <<EOS

⚠️ 页数($PAGES)与图像数量($GOT)不一致。
   ・数量更多 → 作画 AI 可能自行返工（例如同一页绘制两次）
   ・数量更少 → 某一页可能生成失败
   👉 请打开每张 PNG，查看右上角页码（例如“3/10”）后重新排序。
      不能假设图像数量等于页面数量（详见 docs/pitfalls.md 的【陷阱 5】）。
EOS
fi
