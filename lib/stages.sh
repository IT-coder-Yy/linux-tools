#!/usr/bin/env bash

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

app_vscode() {
    if [[ $DISTRO == arch ]]; then arch_install visual-studio-code-bin
    else install_deb https://update.code.visualstudio.com/latest/linux-deb-x64/stable vscode; fi
}
app_flclash() {
    if [[ $DISTRO == arch ]]; then arch_install flclash
    else github_deb chen08209/FlClash 'FlClash-*-linux-amd64.deb'; fi
}
app_cc_switch() {
    if [[ $DISTRO == arch ]]; then arch_install cc-switch-bin
    else github_deb farion1231/cc-switch 'CC-Switch-*-Linux-x86_64.deb'; fi
}
app_snipaste() {
    if [[ $DISTRO == arch ]]; then arch_install snipaste; return; fi
    apt_install libfuse2t64
    download https://download.snipaste.com/archives/Snipaste-2.11.3-x86_64.AppImage "$TMP/Snipaste.AppImage"
    install -Dm755 "$TMP/Snipaste.AppImage" "$DATA/snipaste/Snipaste.AppImage"
    ln -sfn "$DATA/snipaste/Snipaste.AppImage" "$BIN/snipaste"
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/linux-tools-snipaste.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Snipaste
Exec="$DATA/snipaste/Snipaste.AppImage"
Terminal=false
Categories=Graphics;
EOF
}
app_typora() {
    if [[ $DISTRO == arch ]]; then arch_install typora; return; fi
    download https://downloads.typora.io/typora.gpg "$TMP/typora.gpg"
    sudo install -Dm644 "$TMP/typora.gpg" /etc/apt/keyrings/typora.gpg
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/typora.gpg] https://downloads.typora.io/linux ./' | sudo tee /etc/apt/sources.list.d/typora.list >/dev/null
    sudo apt-get update
    apt_install typora
}
app_wechat() {
    if [[ $DISTRO == arch ]]; then arch_install wechat-bin
    else install_deb https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb wechat; fi
}
app_qq() {
    if [[ $DISTRO == arch ]]; then arch_install linuxqq
    else install_deb "${QQ_DEB_URL:-https://qqdl.gtimg.cn/qqfile/QQNT/9.9.37/beta/816b3c79/linuxqq_3.2.35-54395_amd64.deb}" qq; fi
}
app_wemeet() {
    if [[ $DISTRO == arch ]]; then arch_install wemeet-bin
    else install_deb "${WEMEET_DEB_URL:-https://updatecdn.meeting.qq.com/cos/72e0e0023e1d1e6d4123fba28821aea1/TencentMeeting_0300000000_3.26.10.401_x86_64_default.publish.deb}" wemeet; fi
}
app_wps() {
    if [[ $DISTRO == arch ]]; then arch_install wps-office-cn wps-office-mui-zh-cn wps-office-mime-cn; return; fi
    local url=${WPS_DEB_URL:-}
    if [[ -z $url ]]; then
        download https://linux.wps.cn/ "$TMP/wps.html"
        url=$(python3 "$ROOT/lib/resolve.py" wps "$TMP/wps.html")
    fi
    install_deb "$url" wps
}
app_sunlogin() {
    if [[ $DISTRO == arch ]]; then arch_install sunloginclient
    else install_deb "${SUNLOGIN_DEB_URL:-https://dw.oray.com/sl/linux/awesun_16.6.0.32198_amd64.deb}" sunlogin; fi
}

skills() {
    local sources="$DATA/skills-sources" dest="${CODEX_HOME:-$HOME/.codex}/skills" repo path name
    mkdir -p "$sources" "$dest"
    while IFS=$'\t' read -r repo path name; do
        [[ -n $repo && $repo != \#* ]] || continue
        clone_once "$repo" "$sources/${repo//\//--}"
        link_skill "$sources/${repo//\//--}/$path" "$dest/$name"
    done < "$ROOT/manifests/skills.tsv"
}

system_packages() {
    local -a packages
    mapfile -t packages < <(sed '/^#/d; /^$/d' "$ROOT/manifests/tools-$DISTRO.txt")
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
    for name in pack pacr pacd; do
        if [[ -e $BIN/$name ]]; then echo "保留已有 $BIN/$name"
        else install -Dm755 "$ROOT/bin/$name" "$BIN/$name"; fi
    done
    if [[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]] && { command -v kwin_wayland >/dev/null || command -v kwin_x11 >/dev/null; }; then
        arch_install kwin-effects-burn-my-windows-git
    else
        echo '跳过 Burn My Windows：未检测到当前 KDE/KWin 桌面。'
    fi
}
