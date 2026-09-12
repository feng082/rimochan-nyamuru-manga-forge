# 安装配置

## 1. codex CLI

作画由 [codex CLI](https://developers.openai.com/codex/cli) 完成。
请登录**支持图像生成功能的方案**。

~~~bash
codex --version   # 能正常执行即可
codex login       # 会打开浏览器
~~~

验证安装（仅生成一张图片）：

~~~bash
cat <<'EOF' | codex exec
🚨 请立即实际调用图像生成工具，生成一张蓝天和积雨云的图片。
   不要只做计划或声明；最后请单独输出一行生成 PNG 的绝对路径。
   不需要阅读文档。
EOF
~~~

若最后一行出现类似 `.../generated_images/<UUID>/xxx.png` 的路径，即配置完成。
若仅输出声明却没有生成图像，请阅读 docs/pitfalls.md 的【陷阱 1】。
上面的请求文本已经包含对应措施，通常可一次成功。

生成结果默认保存在 `~/.codex/generated_images/`。如需使用其他位置，可设置环境变量：

~~~bash
export CODEX_IMAGE_DIR="/path/to/generated_images"
~~~

## 2. Claude Code

将本仓库放入 Claude Code 的技能目录：

~~~bash
# 面向当前用户全局使用
cp -r rimochan-nyamuru-manga-forge ~/.claude/skills/manga-forge

# 或仅用于某个项目
cp -r rimochan-nyamuru-manga-forge <your-project>/.claude/skills/manga-forge
~~~

启动 Claude Code 后，请求“画一部 3 页漫画”之类的需求即可触发。

## 3. bash

forge.sh / collect.sh 是 bash 脚本。

- macOS / Linux：可直接运行。
- **Windows**：可在 Git Bash 中运行（本项目的开发环境也是如此）。若从 PowerShell 调用，请使用
  `bash ./scripts/forge.sh ...`。

若脚本没有执行权限：

~~~bash
chmod +x scripts/*.sh
~~~

## 4. 参考图（可选）

准备角色立绘后，AI 就能按**该角色**绘制。
没有参考图也能运行；作画 AI 会根据分镜中的 `materials.note` 自行设计，
因此**不提供参考图也可用**。

如需准备参考图，请阅读 docs/characters.md。

## 故障排除

| 症状 | 处理方法 |
|---|---|
| `codex: command not found` | codex CLI 未加入 PATH。打开新终端，或用完整路径调用。 |
| `Not inside a trusted directory` | 执行位置不在 git 仓库内（例如通过 ZIP 解压）。在仓库根目录执行 `git init`，或重新用 `git clone` 获取。 |
| `No prompt provided via stdin.` | 把提示词直接写在 `-i` 后面了。请通过 heredoc 传入（见陷阱 2）。 |
| 只做声明却没有图像 | 陷阱 1。forge.sh 已包含处理措施，可以直接重新执行。 |
| 找不到图像 | 检查 `CODEX_IMAGE_DIR`。路径应出现在 `out/<作品名>/forge.log` 中。 |
| 混入另一部作品的角色 | 陷阱 3。渲染期间不要运行其他 codex 调用。 |
