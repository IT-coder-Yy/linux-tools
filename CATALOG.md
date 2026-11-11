# 软件与 Skills 清单

共 102 个原始迁移目标；作用见下表，平台差异和安装方式以 README 为准。

只安装默认配置，不恢复旧账号、系统设置或个人配置。

## 应用软件

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| VS Code | visual-studio-code-bin | 代码编辑器 |
| FlClash | flclash | 代理客户端 |
| CC Switch | cc-switch-bin | 切换 AI 工具配置 |
| Snipaste | snipaste | 截图与贴图 |
| Typora | typora | Markdown 编辑器 |
| 微信 | wechat-bin | 聊天与文件传输 |
| QQ | linuxqq | 聊天与文件传输 |
| 腾讯会议 | wemeet-bin | 视频会议 |
| WPS Office | wps-office-cn | 文字、表格与演示文稿 |
| 向日葵 | sunloginclient | 远程控制 |
| WPS 简体中文资源 | wps-office-mui-zh-cn | WPS 简体中文界面 |
| WPS 文件类型资源 | wps-office-mime-cn | WPS 文档类型识别 |
## 终端工具

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| abtop | abtop | 终端 AI Agent 监视器 |
| opencode | opencode | 开源 AI 编程代理 |
| Claude Code | @anthropic-ai/claude-code | AI 编程命令行 |
| Codex CLI | @openai/codex | OpenAI 编程命令行 |
| DeepSeek Harness | @deepseek-ai/dsh | DeepSeek 编程代理命令行 |
| git | git | 分布式版本管理 |
| lazygit | lazygit | Git 终端图形界面 |
| GitHub CLI | gh | GitHub 仓库、Issue、PR 命令行管理 |
| lazydocker | lazydocker | Docker 终端管理界面 |
| tmux | tmux | 终端会话复用 |
| yazi | yazi | 终端文件管理器 |
| fzf | fzf | 命令行模糊查找 |
| btop | btop | 终端 CPU、内存、磁盘与网络资源监控 |
| htop | htop | 交互式进程监视器 |
| fastfetch | fastfetch | 终端系统信息展示 |
| tokei | tokei | 按编程语言统计代码行数 |
| aria2 | aria2 | 支持 HTTP、FTP、BT 等协议的下载器 |
| wget | wget | 命令行网络下载工具 |
| zip | zip | 创建 ZIP 压缩包 |
| unrar | unrar | 解压 RAR 文件 |
| vim | vim | Vim 终端文本编辑器 |
| nano | nano | 终端文本编辑器 |
| neovim | neovim | Neovim 编辑器 |
| less | less | 终端分页阅读文本 |
| genact | genact | 生成模拟终端活动输出 |
| smartmontools | smartmontools | 读取硬盘 S.M.A.R.T. 健康信息 |
| xdotool | xdotool | X11 窗口和输入自动化 |
| ruff | ruff | Python 静态检查与格式化工具 |
| ripgrep | ripgrep | 快速全文搜索工具 |
| ffmpeg | ffmpeg | 音视频转码、录制和处理工具 |
| imagemagick | imagemagick | 图像转换与处理工具 |
| openssh | openssh | SSH 远程登录、文件传输工具 |
| Vercel CLI | vercel | Vercel 项目开发与部署命令行 |
| ngrok | ngrok | 为本地服务建立网络隧道 |
| paru | paru | Arch/AUR 软件安装助手 |
| yay-bin | yay-bin | Arch/AUR 软件安装助手 |
| downgrade | downgrade | 从缓存或 Arch 历史归档回退软件包 |
| [pack](https://github.com/IT-coder-Yy/archtools) | pack | 从 bin 子模块对应仓库安装；基于 fzf 搜索、审查和安装包 |
| [pacr](https://github.com/IT-coder-Yy/archtools) | pacr | 从 bin 子模块对应仓库安装；基于 fzf 卸载包 |
| [pacd](https://github.com/IT-coder-Yy/archtools) | pacd | 从 bin 子模块对应仓库安装；基于 fzf 降级包 |
## Shell与插件

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| zsh | zsh | 交互式 Shell |
| fish | fish | 带交互提示的 Shell |
| starship | starship | 跨 Shell 提示符工具 |
| Oh My Zsh | oh-my-zsh | Zsh 框架及内置 git 插件 |
| Powerlevel10k | powerlevel10k | 终端提示符主题 |
| Zsh 自动建议 | zsh-autosuggestions | 输入命令时提供历史建议 |
| Zsh 语法高亮 | zsh-syntax-highlighting | 命令输入语法着色 |
## 开发环境与包

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| python | python | Python 编程语言运行时 |
| nodejs | nodejs | JavaScript 运行时 |
| rust | rust | Rust 编译工具链 |
| Bun | bun | JavaScript 运行时与包管理、执行工具 |
| gcc | gcc | C/C++ 编译器 |
| make | make | 按 Makefile 执行构建 |
| gdb | gdb | 原生程序调试器 |
| base-devel | base-devel | Arch 软件构建工具集合 |
| uv | uv | Python 依赖、虚拟环境及工具管理 |
| python-pip | python-pip | Python 包管理器 |
| npm | npm | Node.js 包管理器 |
| pnpm | pnpm | JavaScript 包管理器 |
| python-fastapi | python-fastapi | Python Web API 框架 |
| uvicorn | uvicorn | Python ASGI 服务运行器 |
| texlive-meta | texlive-meta | TeX Live 排版套件元包 |
| texlive-langchinese | texlive-langchinese | TeX Live 中文排版支持 |
## 容器与数据库

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| docker | docker | 容器引擎 |
| docker-compose | docker-compose | 多容器应用编排工具 |
| Docker Buildx | docker-buildx | 扩展容器镜像构建能力 |
| mysql | mysql | MySQL 数据库服务端 |
| mysql-clients | mysql-clients | MySQL 客户端工具 |
| valkey | valkey | 内存键值数据库，兼容 Redis 使用场景 |
## 桌面增强与输入支持

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| Burn My Windows | kwin-effects-burn-my-windows-git | KWin 窗口动画特效 |
| Fcitx5 | fcitx5 | 输入法框架 |
| Fcitx5 中文组件 | fcitx5-chinese-addons | 中文拼音等输入支持 |
| Fcitx5 设置工具 | fcitx5-configtool | 图形化调整输入法 |
| Fcitx5 GTK 适配 | fcitx5-gtk | 让 GTK 应用使用输入法 |
| Fcitx5 Qt 适配 | fcitx5-qt | 让 Qt 应用使用输入法 |
| Noto CJK | noto-fonts-cjk | 显示中文、日文、韩文 |
| Noto Emoji | noto-fonts-emoji | 显示 Emoji |
| Atkinson Nerd Font | otf-atkinsonhyperlegiblemono-nerd | 终端文字和提示符图标 |
## AI应用插件

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| dsh-client-auto-continue | dsh-client-auto-continue | 网络等非人为中断后发送继续提示 |
| dsh-lazygit-plugin | dsh-lazygit-plugin | DeepSeek Web 可视化 Git 工作台 |
| dshmarket | dshmarket | DeepSeek Web 插件市场 |
## Skills

| 名称 | 标识 | 作用 |
| --- | --- | --- |
| archify | archify | 架构图与流程图 |
| asu-skills | asu-skills | 求职、简历和项目导学工具集 |
| code-review | code-review | 从指定提交、分支或标签起审查代码变更，分别核对仓库规范与需求规格。 |
| grill-me | grill-me | 需求与方案追问 |
| grilling | grilling | 计划与决策压力测试 |
| nuwa-skill | nuwa-skill | 人物思维框架与相关技能 |
| taste | taste | 前端设计指导 |
| to-spec | to-spec | 把当前对话整理成需求规格，并按技能流程发布到项目任务系统。 |
| to-tickets | to-tickets | 把方案、规格或对话拆成可推进的任务，并记录任务之间的阻塞关系。 |

## 逐个 Skills

| 名称 | 用途 |
| --- | --- |
| archify | 生成架构图、流程图及相关可视化。 |
| contributor | 辅助开源项目贡献。 |
| evidence-recap | 将项目交付过程整理为可核验的证据链。 |
| great-resume | 提升简历经历与项目表述。 |
| interview | 预测面试问题、模拟追问与复练。 |
| job-apply | 辅助填写求职申请。 |
| job-match | 对照岗位要求分析经历匹配度。 |
| make-resume | 制作与修改可编辑简历。 |
| offer | 管理求职投递与面试进度。 |
| project-guide | 项目源码导学及项目面试准备。 |
| code-review | 从指定提交、分支或标签起审查代码变更，分别核对仓库规范与需求规格。 |
| grill-me | 通过追问完善需求与方案。 |
| grilling | 对计划、决策或想法进行压力测试。 |
| huashu-nuwa | 研究人物或主题，生成可复用的思维框架技能。 |
| andrej-karpathy-perspective | 使用 andrej-karpathy 的思维框架辅助分析。 |
| elon-musk-perspective | 使用 elon-musk 的思维框架辅助分析。 |
| feynman-perspective | 使用 feynman 的思维框架辅助分析。 |
| ilya-sutskever-perspective | 使用 ilya-sutskever 的思维框架辅助分析。 |
| mrbeast-perspective | 使用 mrbeast 的思维框架辅助分析。 |
| munger-perspective | 使用 munger 的思维框架辅助分析。 |
| naval-perspective | 使用 naval 的思维框架辅助分析。 |
| paul-graham-perspective | 使用 paul-graham 的思维框架辅助分析。 |
| steve-jobs-perspective | 使用 steve-jobs 的思维框架辅助分析。 |
| sun-yuchen-perspective | 使用 sun-yuchen 的思维框架辅助分析。 |
| taleb-perspective | 使用 taleb 的思维框架辅助分析。 |
| trump-perspective | 使用 trump 的思维框架辅助分析。 |
| x-mastery-mentor | X / Twitter 内容运营指导。 |
| zhang-yiming-perspective | 使用 zhang-yiming 的思维框架辅助分析。 |
| zhangxuefeng-perspective | 使用 zhangxuefeng 的思维框架辅助分析。 |
| design-taste-frontend | 指导前端页面设计与实现。 |
| to-spec | 把当前对话整理成需求规格，并按技能流程发布到项目任务系统。 |
| to-tickets | 把方案、规格或对话拆成可推进的任务，并记录任务之间的阻塞关系。 |
