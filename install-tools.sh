#!/usr/bin/env bash
# 独立安装脚本：自动识别 Arch Linux / Ubuntu 24.04，无需同目录的其他文件。
set -Eeuo pipefail
SCRIPT_FILE=$(realpath -- "${BASH_SOURCE[0]}")
DATA=${XDG_DATA_HOME:-$HOME/.local/share}/linux-tools
BIN=$HOME/.local/bin
export PATH="$BIN:$HOME/.cargo/bin:$PATH"

detect_platform() {
    local os=$1 version=$2 arch=$3
    [[ $arch == x86_64 ]] || { echo "暂不支持 $arch；本版支持 Intel / AMD 的 x86_64 电脑。" >&2; return 1; }
    case "$os:$version" in
        arch:*) printf 'arch\n' ;;
        ubuntu:24.04) printf 'ubuntu\n' ;;
        *) echo "尚未适配 $os $version；支持 Arch Linux 和 Ubuntu 24.04。" >&2; return 1 ;;
    esac
}

download() {
    curl --fail --location --show-error --retry 2 --connect-timeout 20 \
        --proto '=https' --proto-redir '=https' "$1" --output "$2"
}

apt_install() { sudo apt-get install -y -- "$@"; }

arch_install() { yay -S --needed -- "$@"; }

github_asset() {
    local repo=$1 pattern=$2 output=$3 url digest
    local -a asset
    download "https://api.github.com/repos/$repo/releases/latest" "$TMP/release.json"
    python3 - "$TMP/release.json" "$repo" "$pattern" > "$TMP/asset.txt" <<'PY'
import fnmatch, json, sys
from pathlib import Path
path, repo, pattern = sys.argv[1:]
assets = [a for a in json.loads(Path(path).read_text()).get("assets", [])
          if fnmatch.fnmatchcase(a["name"], pattern)]
if len(assets) != 1:
    raise SystemExit(f"{repo}: 期望一个 {pattern}，实际找到 {len(assets)} 个")
asset = assets[0]
url = asset["browser_download_url"]
if not url.startswith(f"https://github.com/{repo}/releases/download/"):
    raise SystemExit("安装包来源与指定的 GitHub 仓库不符")
print(url)
print(asset.get("digest") or "")
PY
    mapfile -t asset < "$TMP/asset.txt"
    url=${asset[0]}; digest=${asset[1]:-}
    download "$url" "$output"
    if [[ $digest == sha256:* ]]; then
        printf '%s  %s\n' "${digest#sha256:}" "$output" | sha256sum -c -
    fi
}

github_deb() {
    local repo=$1 pattern=$2
    github_asset "$repo" "$pattern" "$TMP/package.deb"
    [[ $(dpkg-deb -f "$TMP/package.deb" Architecture) == amd64 ]] || return 1
    chmod a+r "$TMP/package.deb"
    sudo apt-get install -y -- "$TMP/package.deb"
}

github_binary() {
    local repo=$1 pattern=$2 binary=$3
    mkdir -p "$TMP/unpack" "$BIN"
    github_asset "$repo" "$pattern" "$TMP/archive"
    tar -xf "$TMP/archive" -C "$TMP/unpack"
    local -a files
    mapfile -t files < <(find "$TMP/unpack" -type f -name "$binary")
    [[ ${#files[@]} == 1 ]] || { echo "压缩包中未找到唯一的 $binary" >&2; return 1; }
    install -m755 "${files[0]}" "$BIN/$binary"
}

clone_once() {
    local repo=$1 dest=$2
    if [[ -e $dest ]]; then
        echo "保留已有目录：$dest"
    else
        git clone --depth 1 "https://github.com/$repo.git" "$dest"
    fi
}

bootstrap() {
    mkdir -p "$BIN" "$DATA"
    if [[ $DISTRO == arch ]]; then
        sudo pacman -Syu --needed base-devel git curl python unzip xz fontconfig
        if ! command -v yay >/dev/null; then
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$TMP/yay-bin"
            (cd "$TMP/yay-bin" && makepkg -si)
        fi
    else
        sudo apt-get update
        apt_install ca-certificates curl git python3 unzip xz-utils fontconfig software-properties-common
        sudo add-apt-repository -y universe
        sudo add-apt-repository -y multiverse
        sudo apt-get update
    fi
    printf 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"\n' > "$DATA/env.sh"
}

node_runtime() {
    # DSH 当前要求 Node >=24.9；复用满足要求的安装。
    if command -v node >/dev/null && command -v npm >/dev/null && \
        node -e 'let [a,b]=process.versions.node.split(".").map(Number); process.exit(a>24 || a===24&&b>=9 ? 0:1)'; then
        return
    fi
    download https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt "$TMP/SHASUMS256.txt"
    local filename
    filename=$(awk '$2 ~ /^node-v24\.[0-9]+\.[0-9]+-linux-x64\.tar\.xz$/ {print $2}' "$TMP/SHASUMS256.txt")
    [[ -n $filename && $filename != *$'\n'* ]] || return 1
    download "https://nodejs.org/dist/latest-v24.x/$filename" "$TMP/$filename"
    (cd "$TMP" && awk -v f="$filename" '$2==f' SHASUMS256.txt | sha256sum -c -)
    mkdir -p "$DATA/node"
    tar -xJf "$TMP/$filename" -C "$DATA/node" --strip-components=1
    for name in node npm npx; do ln -sfn "$DATA/node/bin/$name" "$BIN/$name"; done
}

package_list() {
    local -a packages
    case $DISTRO in
        arch) packages=(
            # CLI / TUI
            abtop
            git
            lazygit
            github-cli
            lazydocker
            tmux
            yazi
            fzf
            btop
            htop
            fastfetch
            tokei
            aria2
            wget
            zip
            unrar
            vim
            nano
            neovim
            less
            genact
            smartmontools
            xdotool
            ripgrep
            ffmpeg
            imagemagick
            openssh
            ngrok
            paru
            yay-bin
            downgrade
            # Shell
            zsh
            fish
            starship
            # 开发环境与包；Node/npm 在独立阶段检查与安装
            python
            python-pip
            rust
            bun
            gcc
            make
            gdb
            base-devel
            uv
            texlive-meta
            texlive-langchinese
            # 容器与数据库
            docker
            docker-compose
            docker-buildx
            mysql
            mysql-clients
            valkey
            # 输入与字体
            fcitx5
            fcitx5-chinese-addons
            fcitx5-configtool
            fcitx5-gtk
            fcitx5-qt
            noto-fonts-cjk
            noto-fonts-emoji
            otf-atkinsonhyperlegiblemono-nerd
        ) ;;
        ubuntu) packages=(
            # CLI / TUI；其余 CLI 由官方发行包或语言包管理器安装
            git
            gh
            tmux
            fzf
            btop
            htop
            aria2
            wget
            zip
            unrar
            vim
            nano
            neovim
            less
            smartmontools
            xdotool
            ripgrep
            ffmpeg
            imagemagick
            openssh-client
            openssh-server
            # Shell
            zsh
            fish
            # 开发环境；Node/npm、Rust、Bun、uv 在独立阶段安装
            python3
            python3-pip
            python3-venv
            build-essential
            gcc
            make
            gdb
            texlive
            texlive-bibtex-extra
            texlive-extra-utils
            context
            texlive-fonts-recommended
            texlive-font-utils
            texlive-formats-extra
            texlive-games
            texlive-humanities
            texlive-latex-extra
            texlive-fonts-extra
            texlive-luatex
            texlive-metapost
            texlive-music
            texlive-pictures
            texlive-plain-generic
            texlive-pstricks
            texlive-publishers
            texlive-xetex
            texlive-science
            texlive-lang-chinese
            # 容器与数据库
            docker.io
            docker-compose-v2
            docker-buildx
            mysql-server
            mysql-client
            valkey-server
            valkey-tools
            # 输入与字体
            fcitx5
            fcitx5-chinese-addons
            fcitx5-config-qt
            fcitx5-frontend-gtk3
            fcitx5-frontend-gtk4
            fcitx5-frontend-qt5
            fcitx5-frontend-qt6
            fonts-noto-cjk
            fonts-noto-color-emoji
        ) ;;
    esac
    printf "%s\n" "${packages[@]}"
}

system_packages() {
    local -a packages
    mapfile -t packages < <(package_list)
    if [[ $DISTRO == arch ]]; then arch_install "${packages[@]}"
    else apt_install "${packages[@]}"; fi
}

rust_runtime() {
    if command -v cargo >/dev/null && command -v rustc >/dev/null; then return; fi
    download https://sh.rustup.rs "$TMP/rustup.sh"
    sh "$TMP/rustup.sh" -y --profile default --no-modify-path
}

tool_lazygit() { github_binary jesseduffield/lazygit 'lazygit_*_linux_x86_64.tar.gz' lazygit; }

tool_lazydocker() { github_binary jesseduffield/lazydocker 'lazydocker_*_Linux_x86_64.tar.gz' lazydocker; }

tool_abtop() { github_binary graykode/abtop 'abtop-x86_64-unknown-linux-gnu.tar.xz' abtop; }

tool_fastfetch() { github_deb fastfetch-cli/fastfetch 'fastfetch-linux-amd64.deb'; }

tool_yazi() { github_deb sxyazi/yazi 'yazi-x86_64-unknown-linux-gnu.deb'; }

tool_genact() {
    github_asset svenstaro/genact 'genact-*-x86_64-unknown-linux-musl' "$TMP/genact"
    install -Dm755 "$TMP/genact" "$BIN/genact"
}

tool_tokei() { cargo install --locked tokei; }

tool_starship() { github_binary starship/starship 'starship-x86_64-unknown-linux-musl.tar.gz' starship; }

tool_uv() {
    download https://astral.sh/uv/install.sh "$TMP/uv.sh"
    UV_INSTALL_DIR="$BIN" UV_NO_MODIFY_PATH=1 sh "$TMP/uv.sh"
}

tool_bun() {
    # baseline 构建兼容未提供 AVX2 的 Intel / AMD CPU。
    github_asset oven-sh/bun 'bun-linux-x64-baseline.zip' "$TMP/bun.zip"
    unzip -q "$TMP/bun.zip" -d "$TMP/bun"
    install -Dm755 "$TMP/bun/bun-linux-x64-baseline/bun" "$BIN/bun"
    ln -sfn "$BIN/bun" "$BIN/bunx"
}

tool_ngrok() {
    download https://bin.ngrok.com/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz "$TMP/ngrok.tgz"
    tar -xzf "$TMP/ngrok.tgz" -C "$TMP" ngrok
    install -Dm755 "$TMP/ngrok" "$BIN/ngrok"
}

python_tools() {
    uv tool install ruff
    # 框架与服务器放在同一个工具虚拟环境，不改系统 Python。
    uv tool install --with 'fastapi[standard]' uvicorn
}

ai_tools() {
    npm install --global --prefix "$HOME/.local" pnpm vercel opencode-ai @anthropic-ai/claude-code @openai/codex @deepseek-ai/dsh
}

dsh_plugins() {
    dsh plugin --profile web add dsh-client-auto-continue dsh-lazygit-plugin dshmarket
}

shell_plugins() {
    clone_once ohmyzsh/ohmyzsh "$HOME/.oh-my-zsh"
    local custom="$HOME/.oh-my-zsh/custom"
    mkdir -p "$custom/themes" "$custom/plugins"
    clone_once romkatv/powerlevel10k "$custom/themes/powerlevel10k"
    clone_once zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
    clone_once zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
    if [[ ! -e $HOME/.zshrc ]]; then
        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    fi
    echo '使用 Oh My Zsh 默认模板；附加主题和插件已下载，未改变默认 Shell 或覆盖已有 .zshrc。'
}

nerd_font() {
    github_asset ryanoasis/nerd-fonts 'AtkinsonHyperlegibleMono.tar.xz' "$TMP/font.tar.xz"
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/AtkinsonHyperlegibleMono"
    mkdir -p "$dir"
    tar -xf "$TMP/font.tar.xz" -C "$dir"
    fc-cache -f "$dir"
}

arch_extras() {
    # 与 bin 子模块指向同一仓库；单独下载本脚本也能安装。
    git clone --depth 1 https://github.com/IT-coder-Yy/archtools.git "$TMP/archtools"
    for name in pack pacr pacd; do
        install -Dm755 "$TMP/archtools/bin/$name" "$BIN/$name"
    done
    sudo install -Dm644 "$TMP/archtools/share/prompts/aur-review.md" /usr/share/archtools/prompts/aur-review.md
    if [[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]] && { command -v kwin_wayland >/dev/null || command -v kwin_x11 >/dev/null; }; then
        arch_install kwin-effects-burn-my-windows-git
    else
        echo '跳过 Burn My Windows：未检测到当前 KDE/KWin 桌面。'
    fi
}

main() {
    case "${1:-}" in
        --help|-h) echo '用法：bash install-tools.sh [--dry-run]'; return ;;
        --dry-run|'') ;;
        *) echo "未知选项：$1" >&2; return 1 ;;
    esac
    [[ $# -le 1 ]] || { echo '参数过多' >&2; return 1; }
    source /etc/os-release
    DISTRO=$(detect_platform "$ID" "${VERSION_ID:-}" "$(uname -m)")
    export DISTRO
    local -a stages=(bootstrap node_runtime)
    stages+=(system_packages rust_runtime)
    if [[ $DISTRO == ubuntu ]]; then
        stages+=(tool_lazygit tool_lazydocker tool_abtop tool_fastfetch tool_yazi tool_genact tool_tokei tool_starship tool_uv tool_bun tool_ngrok nerd_font)
    fi
    stages+=(python_tools ai_tools dsh_plugins shell_plugins)
    if [[ $DISTRO == arch ]]; then stages+=(arch_extras); fi
    printf '系统：%s %s，架构：x86_64，安装组：tools\n' "$ID" "${VERSION_ID:-rolling}"
    if [[ ${1:-} == --dry-run ]]; then
        echo '仅预览清单与执行阶段；不联网、不安装，不解析未来的下载版本或包依赖。'
        printf '%s\n' "${stages[@]}"
        package_list
        return
    fi
    [[ $EUID != 0 ]] || { echo '请以普通用户运行，脚本会按需调用 sudo。' >&2; return 1; }
    sudo -v
    mkdir -p "$DATA/logs"
    local report stage
    report="$DATA/logs/$(date +%Y%m%d-%H%M%S)-tools.tsv"
    local -a failures=()
    for stage in "${stages[@]}"; do
        printf '\n>>> %s\n' "$stage"
        # 每步用独立 Bash 执行，保留 errexit，并让 stdin 继续连接终端。
        if bash -c '
            set -Eeuo pipefail
            source "$1"
            stage=$2
            TMP=$(mktemp -d -t linux-tools.XXXXXXXX)
            chmod 755 "$TMP"
            trap '\''rm -rf -- "$TMP"'\'' EXIT
            trap '\''printf "安装阶段失败：%s，第 %s 行\n" "$stage" "$LINENO" >&2'\'' ERR
            "$stage"
        ' linux-tools-stage "$SCRIPT_FILE" "$stage" 2>&1 | tee -a "${report%.tsv}.log"; then
            printf '完成\t%s\n' "$stage" | tee -a "$report"
        else
            printf '失败\t%s\n' "$stage" | tee -a "$report"
            failures+=("$stage")
            [[ $stage != bootstrap ]] || break
        fi
    done
    printf '\n报告：%s\n' "$report"
    echo '新终端找不到命令时，运行：export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"'
    echo '输入法、Shell 插件和桌面特效的启用方式见 README；账号请自行登录。'
    if (( ${#failures[@]} )); then
        printf '未完成：%s\n' "${failures[*]}"
        return 1
    fi
    echo '所选安装阶段完成。桌面启动和实际功能仍需在新电脑上验证。'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
