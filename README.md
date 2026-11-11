<div align="center">

<h1>linux-tools</h1>

<p><strong>两份脚本，装好常用 Linux 工作环境。</strong></p>

<p>自动识别系统，按需安装应用软件、开发工具与 AI Skills。</p>

<p>
  <img src="https://img.shields.io/badge/Arch_Linux-Rolling-1793D1?logo=archlinux&amp;logoColor=white" alt="Arch Linux Rolling">
  <img src="https://img.shields.io/badge/Ubuntu-24.04_LTS-E95420?logo=ubuntu&amp;logoColor=white" alt="Ubuntu 24.04 LTS">
  <img src="https://img.shields.io/badge/CPU-x86__64-617F91" alt="Intel / AMD x86_64">
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&amp;logoColor=white" alt="Bash scripts">
</p>

<p><a href="#安装与配置">开始安装</a> · <a href="CATALOG.md">软件清单</a> · <a href="https://github.com/IT-coder-Yy/archtools">archtools</a></p>

</div>

## 功能

- **两个独立入口**：应用软件与 Skills 一组，终端工具、Shell、开发包等一组。每个脚本都能单独下载运行。
- **自动选择安装方式**：识别 Arch Linux 或 Ubuntu 24.04，使用对应的包管理器和软件发行渠道。
- **直接获取 Skills**：从上游仓库拉取完整目录，保留脚本、模板和引用资源；已有同名技能不会被覆盖。
- **引用 archtools**：通过 `bin` 子模块链接 `pack`、`pacr`、`pacd` 所在仓库，安装时从该仓库获取工具。
- **使用默认配置**：安装软件本体，不迁移旧电脑的账号、密钥、聊天记录、数据库或浏览器与编辑器扩展。
- **分阶段记录结果**：记录每一步的完成或失败状态，保留日志，修复问题后可重新运行。

## 安装与配置

需要 **Bash、curl、tar、网络连接**，以及一个**有 sudo 权限的普通用户**。脚本会按需调用 sudo，不要在整个安装命令前加 sudo。

| 系统 | 架构 | 桌面说明 |
| --- | --- | --- |
| **Arch Linux** | x86_64，Intel / AMD | KDE/KWin 当前会话下可安装 Burn My Windows；其他桌面跳过该特效。 |
| **Ubuntu 24.04 LTS** | amd64，Intel / AMD | 按默认 GNOME 环境适配，不额外安装 KDE。 |

ARM、其他发行版和其他 Ubuntu 版本尚未适配，脚本检测到后会停止。缺少 curl 时，Ubuntu 使用 `sudo apt-get update && sudo apt-get install -y curl`，Arch 使用 `sudo pacman -Syu --needed curl`。

### 1. 选择安装组

**应用软件 + Skills**

```bash
curl -fsSL https://raw.githubusercontent.com/IT-coder-Yy/linux-tools/main/install-apps-skills.sh -o install-apps-skills.sh && bash install-apps-skills.sh
```

包含 VS Code、FlClash、CC Switch、Snipaste、Typora、微信、QQ、腾讯会议、WPS、向日葵，以及 archify、ASu、女娲、Taste、代码审查和需求拆解等 Skills。该脚本也会准备 git 和可用的 Node.js。

**终端工具 + Shell + 开发环境**

```bash
curl -fsSL https://raw.githubusercontent.com/IT-coder-Yy/linux-tools/main/install-tools.sh -o install-tools.sh && bash install-tools.sh
```

包含 Codex、Claude Code、DeepSeek Harness、OpenCode、Git 工具、终端工具、Shell 及插件、语言运行时、TeX Live、Docker、MySQL、Valkey、Fcitx5、字体和 DSH 插件。Arch 还会安装相应的包管理工具。

两组都运行即可覆盖本仓库的安装范围。完整名称、分类和用途见 [CATALOG.md](CATALOG.md)；其中 102 个清单目标会按平台合并、映射或跳过，不代表每个系统都安装 102 个独立软件包。

### 2. 了解默认设置

| 项目 | 安装后的行为 |
| --- | --- |
| **Shell 与提示符** | 新建 Zsh 配置时使用 Oh My Zsh 官方默认模板；保留已有 `.zshrc`。Powerlevel10k、Starship、自动建议和高亮只安装，不自动选用，也不切换默认 Shell。 |
| **输入法与字体** | 安装 Fcitx5、中文组件及字体；输入法框架、终端字体需要自行选用，不自动替换 GNOME 的现有设置。 |
| **AI Skills** | 安装到 `${CODEX_HOME:-$HOME/.codex}/skills`，已有同名目录保留。重启 Codex 后查看；AI CLI 本体在第二组安装。 |
| **Python 工具** | 使用 uv 的隔离环境安装 Ruff、FastAPI / Uvicorn，不通过全局 pip 改动系统 Python；项目依赖仍由项目自行管理。 |
| **账号与服务** | 登录、代理订阅、Docker 用户组和数据库密码由使用者配置；安装包可能按默认行为启动 Docker、MySQL、Valkey、SSH 或向日葵服务。 |

Skills 源码保存在 `${XDG_DATA_HOME:-$HOME/.local/share}/linux-tools/skills-sources`，再链接到技能目录。安装时不执行 Skill 中描述的任务，也不打包旧电脑的技能副本。当前来源见 [安装脚本中的 `skill_sources`](install-apps-skills.sh)。

### 3. 开始使用

用户级命令放在 `~/.local/bin`，Rust 工具可能在 `~/.cargo/bin`。若新终端找不到命令，执行：

```bash
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
```

需要长期生效时，将这行加入所用 Shell 对应的启动文件；它适用于 Bash / Zsh。Fish 可使用 [`fish_add_path ~/.local/bin ~/.cargo/bin`](https://fishshell.com/docs/current/cmds/fish_add_path.html)。

安装过程可能需要 sudo 或 AUR 审查确认。Arch 会先执行完整的 `pacman -Syu`；TeX Live、字体和部分源码构建需要较多磁盘空间与时间。

## 本地运行

也可以克隆仓库后运行。带上 `--recurse-submodules` 会同时检出 `bin` 引用的 archtools：

```bash
git clone --recurse-submodules https://github.com/IT-coder-Yy/linux-tools.git
cd linux-tools
```

先查看安装范围，再按需安装：

```bash
bash install-apps-skills.sh --dry-run
bash install-tools.sh --dry-run

bash install-apps-skills.sh
bash install-tools.sh
```

`--dry-run` 只列出范围和阶段，不联网、不安装，也不模拟下载或依赖解析。已有克隆可执行 `git submodule update --init bin` 补齐子模块；GitHub ZIP 不包含子模块源码，但两个安装脚本仍可独立运行。

### 日志与重试

日志和结果表保存在 `${XDG_DATA_HOME:-$HOME/.local/share}/linux-tools/logs`。基础依赖阶段失败会停止；其他阶段失败后继续执行余下步骤。任意阶段失败，最终退出码都会为非零。

修复网络或上游问题后，重新执行同一个安装命令即可。包管理器负责已有软件，Shell 配置和同名 Skills 会保留。软件和 Skills 可能随上游更新，这不是锁定所有版本的系统镜像。

QQ、腾讯会议、WPS、向日葵的官方下载地址变化时，可分别设置 `QQ_DEB_URL`、`WEMEET_DEB_URL`、`WPS_DEB_URL`、`SUNLOGIN_DEB_URL` 后重试。DSH 插件被上游判定不兼容时，脚本不会自动添加风险豁免。

### 平台差异

- Ubuntu 跳过 KWin 特效和 yay、paru、downgrade、pack、pacr、pacd 等 Arch 专用工具，使用 `docker compose` 调用 Compose。
- Typora 使用官方发行渠道，试用或许可证按软件自身规则处理；Ubuntu 的 WPS 中文和文件类型资源随官方 deb 安装。
- Ubuntu Wayland 下，xdotool 的 X11 自动化、Snipaste 全局截图和腾讯会议共享可能受会话限制；脚本不会替换显示会话。
- Go、CMake 不作为独立安装目标；构建软件时，包管理器仍可能按需安装编译依赖。

## 项目结构

```text
linux-tools/
├── install-apps-skills.sh   # 应用软件与 AI Skills，自动识别系统
├── install-tools.sh         # 终端、Shell、开发环境、数据库与输入支持
├── CATALOG.md               # 软件名称、分类与用途
├── bin/                     # Git 子模块 → IT-coder-Yy/archtools
├── .gitmodules              # 子模块路径与仓库地址
└── README.md                # 安装与使用说明
```

`bin` 在 GitHub 上显示为 `bin @ 提交号`，指向 [IT-coder-Yy/archtools](https://github.com/IT-coder-Yy/archtools)，父仓库只记录引用。子模块固定到一个提交；独立安装脚本则拉取该仓库当前默认分支，将三条命令安装到 `~/.local/bin`，并安装配套 AUR 审查提示词。无需提前初始化 `bin`，也不额外引入 Flatpak。

安装脚本已通过语法、静态检查和独立预览验证，Ubuntu 24.04 的系统包清单通过了依赖模拟；完整 GUI 软件、登录和实际功能尚未在全新实机上逐项验证。不在仓库中保留测试文件。
