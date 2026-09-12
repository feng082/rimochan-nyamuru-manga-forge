# 安装配置

## 1. Codex 原生模式（默认）

将本仓库安装到 Codex 的技能目录：

```bash
# 在仓库父目录执行
cp -r rimochan-nyamuru-manga-forge ~/.codex/skills/manga-forge
```

Windows PowerShell：

```powershell
Copy-Item -Recurse . "$env:USERPROFILE\.codex\skills\manga-forge"
```

然后新建一个 Codex 任务，直接请求：

> 画一部 3 页漫画：……

Codex 会读取 `SKILL.md`，设计或修改 OMNY，并在当前任务中逐页调用图像生成能力。
原生模式不要求单独安装 `codex` CLI；但当前 Codex 环境必须具备图像生成能力。

## 2. 可选：codex CLI 批处理模式

若需要稳定写入 `out/<作品名>/page*.png`、在终端中批量执行或复现同一运行，
可使用 `scripts/forge.sh`。这要求安装 [codex CLI](https://developers.openai.com/codex/cli)，
并登录支持图像生成的方案。

```bash
codex --version   # 能正常执行即可
codex login       # 会打开浏览器
```

验证 CLI 图像生成（仅生成一张图）：

```bash
cat <<'EOF' | codex exec
🚨 请立即实际调用图像生成工具，生成一张蓝天和积雨云的图片。
   不要只做计划或声明；最后请单独输出一行生成 PNG 的绝对路径。
   不需要阅读文档。
EOF
```

若最后一行出现类似 `.../generated_images/<UUID>/xxx.png` 的路径，即配置完成。
若仅输出声明却没有生成图像，请阅读 docs/pitfalls.md 的【陷阱 1】。

生成结果默认保存在 `~/.codex/generated_images/`。如需使用其他位置，可设置环境变量：

```bash
export CODEX_IMAGE_DIR="/path/to/generated_images"
```

## 3. bash（仅 CLI 批处理模式需要）

forge.sh / collect.sh / deliver.sh 是 bash 脚本。

- macOS / Linux：可直接运行。
- **Windows**：可在 Git Bash 中运行。若从 PowerShell 调用，请使用
  `bash ./scripts/forge.sh ...`。

若脚本没有执行权限：

```bash
chmod +x scripts/*.sh
```

## 4. 参考图（可选）

准备角色立绘后，AI 就能按**该角色**绘制。
没有参考图也可运行；作画 AI 会根据分镜中的 `materials.note` 自行设计，
因此**不提供参考图也可用**。

如需准备参考图，请阅读 docs/characters.md。

## 故障排除

| 症状 | 处理方法 |
|---|---|
| Codex 没有启用技能 | 确认仓库位于 `~/.codex/skills/manga-forge`，然后在新任务中重试。 |
| 当前任务不能生成图像 | 检查所用 Codex 环境是否启用了图像生成；也可改用 CLI 批处理模式。 |
| `codex: command not found` | 仅影响 CLI 批处理模式。将 codex CLI 加入 PATH，或改用 Codex 原生模式。 |
| `Not inside a trusted directory` | CLI 执行位置不在 git 仓库内。请在仓库根目录 `git init`，或重新用 `git clone` 获取。 |
| `No prompt provided via stdin.` | CLI 模式把提示词直接写在 `-i` 后面了。请通过 heredoc 传入（见陷阱 2）。 |
| 只做声明却没有图像 | CLI 模式见陷阱 1；原生模式应在同一任务中实际调用图像生成工具。 |
| 找不到 CLI 生成的图像 | 检查 `CODEX_IMAGE_DIR`。路径应出现在 `out/<作品名>/forge.log` 中。 |
| CLI 渲染混入另一部作品的角色 | 见陷阱 3。渲染期间不要运行其他 codex 图像生成任务。 |
