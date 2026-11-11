# linux-tools

Arch Linux / Ubuntu 常用软件、开发工具与 AI Skills 一键安装。

两个安装组，自动识别系统；仅安装程序和默认配置。支持 **Arch Linux x86_64** 与 **Ubuntu 24.04 GNOME amd64**。Intel 和 AMD 的常见 64 位电脑均适用。ARM、其他发行版和其他 Ubuntu 版本会停止并提示尚未适配，不会误装 x86 安装包。

## 一行安装

使用有 sudo 权限的普通用户运行，不要在整个命令前加 sudo。需要 Bash、curl、tar 和网络连接。没有 curl 时，Ubuntu 先执行 `sudo apt-get update && sudo apt-get install -y curl`；Arch 先执行 `sudo pacman -Syu --needed curl`。

**应用软件 + Skills：**

```bash
curl -fsSL https://raw.githubusercontent.com/IT-coder-Yy/linux-tools/main/install-apps-skills.sh -o install-apps-skills.sh && bash install-apps-skills.sh
```

**终端工具 + Shell + 开发包 + 容器数据库 + 输入支持 + DSH 插件：**

```bash
curl -fsSL https://raw.githubusercontent.com/IT-coder-Yy/linux-tools/main/install-tools.sh -o install-tools.sh && bash install-tools.sh
```

每组都能单独运行；只安装第一组时，也会准备 git 和可用的 Node.js。两组都运行即可覆盖本仓库清单。sudo、AUR 构建审查可能需要交互确认；“一行命令”不表示完全无人值守。

## 下载后本地运行

从 GitHub 的 **Code → Download ZIP** 下载，或使用本地安装包。解压后进入目录执行：

```bash
bash install-apps-skills.sh
bash install-tools.sh
```

根目录只有这两个安装脚本，均为独立文件，自动选择 Arch / Ubuntu 安装方式；公共函数、包名映射和 Skills 来源直接写在各自脚本中。不需要 `lib/`、`manifests/` 或额外入口，也不从 `CATALOG.md` 解析命令；该文件只负责说明名称和用途。

`bin` 是指向 [IT-coder-Yy/archtools](https://github.com/IT-coder-Yy/archtools) 的 **Git 子模块**，在 GitHub 上显示为 `bin @ 提交号` 的目录链接。父仓库只保存 `.gitmodules` 和提交引用，不复制这三个工具的源码。需要同时检出子模块时使用：

```bash
git clone --recurse-submodules https://github.com/IT-coder-Yy/linux-tools.git
```

已有克隆可在仓库目录执行 `git submodule update --init bin`。GitHub ZIP 和本地安装包不打包子模块源码；两个安装脚本仍可独立运行，不要求预先检出 `bin`。

在任意入口末尾加 `--dry-run`，只展示安装范围和阶段；不会联网或修改系统。它不模拟未来的软件下载和依赖解析。

## 安装范围

完整名称和用途见 [软件清单](CATALOG.md)。以原清单 102 个目标为依据；不同平台会合并、映射或跳过特定项目，不代表各安装 102 个系统包。

| 分类 | 内容 |
| --- | --- |
| 应用 | VS Code、FlClash、CC Switch、Snipaste、Typora、微信、QQ、腾讯会议、WPS、向日葵；WPS 两项配套资源随套件安装 |
| Skills | archify、ASu 技能集、女娲及人物技能集、Taste、code-review、grill-me、grilling、to-spec、to-tickets |
| 终端工具 | Codex、Claude Code、DeepSeek Harness、OpenCode、Git/gh/lazygit、lazydocker、tmux、yazi、fzf、监控与文件处理工具等 |
| Shell | Zsh、Fish、Starship、Oh My Zsh、Powerlevel10k、Zsh 自动建议和高亮 |
| 开发 | Python、Node/npm、Rust、Bun、GCC/Make/GDB、uv/pip/pnpm、FastAPI/Uvicorn、TeX Live 中文排版 |
| 容器数据库 | Docker、Compose、Buildx、MySQL 服务端和客户端、Valkey |
| 输入与字体 | Fcitx5 及中文、GTK/Qt 组件，Noto CJK/Emoji、Atkinson Nerd Font |
| DSH 插件 | dsh-client-auto-continue、dsh-lazygit-plugin、dshmarket，安装到默认 web profile |
| Arch 专用 | yay、paru、downgrade、pack/pacr/pacd；KDE 当前会话下另装 Burn My Windows |

### 平台差异

- **Ubuntu GNOME 跳过 KWin 特效**，也跳过 yay/paru/downgrade/pack/pacr/pacd；不额外安装 KDE。Arch 仅在检测到当前 KDE/KWin 会话时安装该特效。
- **Typora 改用官方正常发行渠道**，不沿用原 `typora-free-bin` 包；许可证或试用按软件自身规则处理。
- Ubuntu 的 WPS 官方 deb 已包含中文和文档类型资源，不照搬 Arch 的两个拆分包名。
- Ubuntu 使用 `docker compose`；Arch 的 Compose 包由发行版提供。
- FastAPI 与 Uvicorn 使用 `uv tool install --with 'fastapi[standard]' uvicorn` 安装在同一隔离环境；项目仍应通过自己的依赖文件管理框架版本。
- Node 满足 DSH 当前的 `>=24.9` 要求时复用，否则安装官方 Node 24 系列并核对 SHA-256。Ubuntu 的 Bun 使用 baseline 构建以兼容没有 AVX2 的 CPU。
- Go、CMake 未作为独立安装目标加入。AUR 构建可能按软件需要安装额外编译依赖。

### Skills 安装方式

使用 `git clone --depth 1` 拉取 [应用安装脚本](install-apps-skills.sh) 内 `skill_sources` 列出的完整上游仓库，然后把选中的目录链接到 `${CODEX_HOME:-$HOME/.codex}/skills`。仓库源码保存在 `${XDG_DATA_HOME:-$HOME/.local/share}/linux-tools/skills-sources`，共享的 assets/references/scripts 会一并保留。

不会把旧电脑上的 Skills 副本打包进本项目，也不会执行这些 Skill 的任务。上游版本会演进；核对时 9 个目标目录对应 32 个 SKILL.md，未来数量和内容可能变化。已有同名 Skill 保留，不覆盖；重启 Codex 后检查可用技能。第一组仅放置技能文件，使用 AI CLI 本体还需安装第二组，或使用已有的 Codex 应用。

## 默认配置与使用

- 不复制旧电脑的 `.zshrc`、输入法词库、代理订阅、API Key、账号、聊天、SSH 密钥、数据库内容、编辑器/浏览器扩展或系统设置。
- Zsh 首次安装时放置 Oh My Zsh 官方默认模板；已有 `.zshrc` 保留。Powerlevel10k、自动建议、高亮和 Starship 只安装，不自动切换主题或默认 Shell。
- Fcitx5 只安装，不自动替换 GNOME 的现有输入法框架；特效、输入法、终端字体要在新系统里自行选用。
- 用户级可执行文件放在 `~/.local/bin`，Rust 工具可能在 `~/.cargo/bin`。新终端若找不到命令，执行 `export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"`；也可按自己的 Shell 启动方式引用 `~/.local/share/linux-tools/env.sh`。
- Ubuntu Wayland 下，xdotool 的 X11 自动化、Snipaste 的全局截图和腾讯会议的共享功能可能受会话限制；脚本不替换显示会话或复制旧的兼容补丁。
- 脚本不迁移服务配置或设置密码，但 **APT/应用安装包可能按默认行为启动 Docker、MySQL、Valkey、SSH 或向日葵服务**。Arch 的后台服务通常仍需按需手动启用。Docker 用户组、登录授权和代理订阅不自动配置。
- Arch 使用完整 `pacman -Syu` 避免局部升级，再通过 AUR 助手安装所需包。TeX Live、字体和部分 AUR 源码构建需要较多磁盘与时间。

## 失败、重试与更新

每个阶段单独记录结果，失败后继续其他阶段；基础依赖阶段失败则停止。任意阶段失败，最终退出码为 1，不会报告全部成功。日志位于 `~/.local/share/linux-tools/logs/`（设置了 XDG_DATA_HOME 时随之变化）。

修复网络或上游问题后可重新执行同一命令。系统包交由包管理器处理；现有 Shell 配置和 Skills 不覆盖。npm、官方 Release 等可能获取新版，这不是严格锁定所有版本的系统镜像。

QQ、腾讯会议、向日葵、Snipaste 使用核对过的官方固定版本链接；WPS 按公开官网按钮解析临时下载地址。上游撤掉旧包或修改页面时会失败。QQ、会议、WPS、向日葵可分别通过 `QQ_DEB_URL`、`WEMEET_DEB_URL`、`WPS_DEB_URL`、`SUNLOGIN_DEB_URL` 指定新的官方 HTTPS deb 地址后重试。DSH 插件若被上游判定不兼容，不自动添加风险豁免。

`pack`、`pacr`、`pacd` 从 `bin` 子模块对应的 [IT-coder-Yy/archtools](https://github.com/IT-coder-Yy/archtools) 获取。子模块记录固定提交；独立安装脚本仍按原有方式临时拉取该仓库当前默认分支，安装三条命令到 `~/.local/bin`，并把配套 AUR 审查提示词放到 `/usr/share/archtools/prompts/aur-review.md`；临时源码随该阶段结束清理。不会在安装过程中执行卸载或降级，也不额外引入 Flatpak。

## 验证与来源

不保留测试目录。可用 `bash -n install-apps-skills.sh && bash -n install-tools.sh` 检查语法，或分别加 `--dry-run` 预览范围。

核对日期：2026-11-11。本次精简核对两个脚本的独立运行、系统分支、内嵌包清单与解析逻辑，并检查 Bash 语法和 ShellCheck。67 个 Ubuntu 显式包在精简前已通过 Ubuntu 24.04 容器的依赖模拟，本次包集合未改变。完整 GUI 安装、登录、截图、输入法与数据库运行效果未在全新实机上逐项验证。

主要官方来源：[VS Code](https://code.visualstudio.com/docs/setup/linux)、[Typora](https://support.typora.io/Typora-on-Linux/)、[Snipaste](https://www.snipaste.com/download.html)、[微信](https://linux.weixin.qq.com/)、[QQ](https://im.qq.com/linuxqq/index.shtml)、[腾讯会议](https://source.meeting.qq.com/download-center.html)、[WPS](https://linux.wps.cn/)、[向日葵](https://sunlogin.oray.com/)、[Node.js](https://nodejs.org/dist/latest-v24.x/)、[uv](https://docs.astral.sh/uv/getting-started/installation/)、[ngrok](https://ngrok.com/download/linux)。其他下载使用清单所列作者的 GitHub Releases、官方发行版软件源或对应语言包管理器。
