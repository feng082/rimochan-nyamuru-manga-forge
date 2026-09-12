#!/usr/bin/env bash
# ============================================================
# rimochan-nyamuru-manga-forge / forge.sh
#   将 OMNY（漫画分镜 YAML）渲染为完成的原稿 PNG 的驱动脚本
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 用法：
#   ./scripts/forge.sh -n <OMNY 文件> [选项]
#
# 必填：
#   -n, --omny <path>      OMNY 文件（分镜数据）
#
# 常用选项：
#   -p, --pages <N>        页数（省略时读取 OMNY 的 meta.page_count）
#   -o, --out <dir>        输出目录（默认：./out/<OMNY 名称>）
#   -a, --omay <path>      OMAY 文件（默认：omay/standard.omay.yaml）
#   -r, --ref <path>       参考图；可重复指定（建议最多 3 张）
#   -m, --memo <text>      作品专属补充指令（画风、注意事项等）
#   -h, --help             显示本帮助
#
# 示例：
#   ./scripts/forge.sh -n my.omny.yaml -r chars/hero.png -r chars/rival.png \
#       -m "画风为蜡笔画；第 1 格背景请使用夕阳"
#
# 前提：
#   - 已安装并登录 codex CLI（所用方案支持图像生成）
#   - `codex --version` 能正常执行
#
# 工作方式（详情见 docs/pitfalls.md）：
#   page1 通过 `codex exec -i <refs>` 创建新会话；
#   page2 起通过 `codex exec resume --last` 继续同一会话。
#   复用会话使角色设计、背景与画风可跨页保持一致。
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
[[ -z "$OMNY" ]] && { echo "错误：必须提供 -n <OMNY 文件>" >&2; exit 1; }
[[ -f "$OMNY" ]] || { echo "错误：找不到 OMNY：$OMNY" >&2; exit 1; }
[[ -z "$OMAY" ]] && OMAY="$HERE/omay/standard.omay.yaml"
[[ -f "$OMAY" ]] || { echo "错误：找不到 OMAY：$OMAY" >&2; exit 1; }

BASENAME="$(basename "$OMNY")"; BASENAME="${BASENAME%%.*}"
[[ -z "$OUT" ]] && OUT="$HERE/out/$BASENAME"
mkdir -p "$OUT"
LOG="$OUT/forge.log"; : > "$LOG"

# 未指定 -p 时，从 OMNY 推断页数
if [[ -z "$PAGES" ]]; then
  PAGES=$(grep -oE 'page_count:[[:space:]]*[0-9]+' "$OMNY" | head -1 | grep -oE '[0-9]+' || true)
  [[ -z "$PAGES" ]] && PAGES=$(grep -cE '^[[:space:]]*-[[:space:]]*page:[[:space:]]*[0-9]+' "$OMNY" || true)
  [[ -z "$PAGES" || "$PAGES" == "0" ]] && { echo "错误：无法判断页数；请通过 -p 指定" >&2; exit 1; }
fi

command -v codex >/dev/null || { echo "错误：找不到 codex CLI；请查看 docs/setup.md" >&2; exit 1; }

REF_ARGS=()
for r in "${REFS[@]:-}"; do
  [[ -z "$r" ]] && continue
  [[ -f "$r" ]] || { echo "警告：找不到参考图，已跳过：$r" >&2; continue; }
  REF_ARGS+=(-i "$r")
done

OMAY_BODY="$(cat "$OMAY")"
OMNY_BODY="$(cat "$OMNY")"

echo "=== 开始渲染：$BASENAME / ${PAGES} 页 / refs=${#REF_ARGS[@]} ===" | tee -a "$LOG"

# ------------------------------------------------------------
# 🚨 强制产出区块（没有它，模型可能只做声明。参见 docs/pitfalls.md）
# ------------------------------------------------------------
forcing_block() {
  cat <<EOS
🚨**请立即实际调用图像生成工具，生成一张 ${1} 的图片**。
不要只做计划或声明；请在最后单独输出一行生成 PNG 的绝对路径。
不需要阅读文档。
EOS
}

# ------------------------------------------------------------
# page1：新会话（传入完整 OMAY、完整 OMNY 与参考图）
# ------------------------------------------------------------
echo "[$(date +%H:%M:%S)] ===== page1 =====" >> "$LOG"
cat <<PROMPT | codex exec "${REF_ARGS[@]}" >> "$LOG" 2>&1
$(forcing_block "page1")

现在请逐页绘制一部**共 ${PAGES} 页的漫画**。
我会提供**两份文件**：① OMAY（作画、演出与版式规则），② OMNY（分镜数据）。
**请遵循 OMAY 的规则绘制 OMNY 中的内容。**

【执行方式】
- 将全部 ${PAGES} 页绘制为“每页 1 张独立图像”；禁止拼成一张图或跨页展开。
- **先只绘制 page1**，随后再继续请求 page2 及以后页面。
- 所有台词必须准确使用 OMNY 中写明的简体中文，并确保清晰易读。
- **气泡必须带尾巴，尾端指向说话者嘴边**（caption 和 handwritten 不带尾巴）。
- 页眉左上角写作品标题，右上角写“1/${PAGES}”。

${MEMO:+【本作品补充说明】
$MEMO
}
===== ① OMAY（作画与版式规则） =====
$OMAY_BODY

===== ② OMNY（分镜数据；共 ${PAGES} 页） =====
$OMNY_BODY
PROMPT
echo "[$(date +%H:%M:%S)] page1 完成" >> "$LOG"

# ------------------------------------------------------------
# page2…N：resume 同一会话，保证角色设计与画风一致
# ------------------------------------------------------------
for ((p=2; p<=PAGES; p++)); do
  echo "[$(date +%H:%M:%S)] ===== page$p =====" >> "$LOG"
  codex exec resume --last "$(forcing_block "page$p")

继续。请按照刚才提供的 OMAY 规则和 OMNY 分镜，**只绘制一张 page${p}**。
角色设计、背景内装、画风和小物设计都必须**与之前页面保持一致**。
**气泡尾巴必须指向说话者的嘴边**；页眉右上角写“${p}/${PAGES}”。
${MEMO:+
（再次列出作品备注）$MEMO}" >> "$LOG" 2>&1
  echo "[$(date +%H:%M:%S)] page$p 完成" >> "$LOG"
done

echo "=== 渲染完成，开始回收 ===" | tee -a "$LOG"
"$HERE/scripts/collect.sh" --log "$LOG" --out "$OUT" --pages "$PAGES"
