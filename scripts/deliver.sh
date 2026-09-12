#!/usr/bin/env bash
# ============================================================
# rimochan-nyamuru-manga-forge / deliver.sh
#   将通过质检的原稿 PNG 交付到用户指定位置
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 用法：
#   ./scripts/deliver.sh -f <已回收目录> -t <交付目录> [选项]
#
# 必填：
#   -f, --from <dir>       已回收目录（out/<作品名>）
#   -t, --to <dir>         交付目标目录（不存在时创建）
#
# 选项：
#   -n, --omny <path>      同时交付分镜（OMNY），作为可复用资产保留
#   --force                即使交付目录已有同名 page*.png 也允许覆盖
#   -h, --help             显示本帮助
#
# 示例：
#   ./scripts/deliver.sh -f out/my -t ~/Desktop/my -n my.omny.yaml
#
# ⚠️ 仅在完成质检（SKILL.md 的 ⑤）后交付。
#    目标目录存在此前交付结果时脚本会停止，绝不静默覆盖。
# ============================================================
set -uo pipefail

FROM=""; TO=""; OMNY=""; FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--from) FROM="$2"; shift 2;;
    -t|--to)   TO="$2"; shift 2;;
    -n|--omny) OMNY="$2"; shift 2;;
    --force)   FORCE=1; shift;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

[[ -z "$FROM" || -z "$TO" ]] && { echo "错误：必须提供 -f <已回收目录> 与 -t <交付目录>" >&2; exit 1; }
[[ -d "$FROM" ]] || { echo "错误：找不到已回收目录：$FROM" >&2; exit 1; }

shopt -s nullglob
PAGES=("$FROM"/page*.png)
shopt -u nullglob
[[ ${#PAGES[@]} -eq 0 ]] && { echo "错误：$FROM 中没有 page*.png；请先用 forge.sh 渲染" >&2; exit 1; }

mkdir -p "$TO"

# 覆盖保护：不静默破坏此前交付物
if [[ "$FORCE" != "1" ]]; then
  for f in "${PAGES[@]}"; do
    b="$(basename "$f")"
    if [[ -e "$TO/$b" ]]; then
      echo "⚠️ 交付目录中已存在 $b：$TO" >&2
      echo "   如确认可以覆盖，请加 --force 后重新执行" >&2
      exit 3
    fi
  done
fi

for f in "${PAGES[@]}"; do
  cp "$f" "$TO/"
done

if [[ -n "$OMNY" ]]; then
  if [[ -f "$OMNY" ]]; then
    cp "$OMNY" "$TO/"
  else
    echo "警告：找不到 OMNY，已跳过：$OMNY" >&2
  fi
fi

echo "✅ 已交付：${#PAGES[@]} 张 → $TO"
ls -la "$TO"/page*.png | awk '{print "   " $9, $5"B"}'
[[ -n "$OMNY" && -f "$TO/$(basename "$OMNY")" ]] && echo "   $TO/$(basename "$OMNY")（分镜）"
exit 0
