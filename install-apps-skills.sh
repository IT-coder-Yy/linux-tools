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

install_deb() {
    local url=$1 label=$2 file="$TMP/$2.deb" arch
    download "$url" "$file"
    arch=$(dpkg-deb -f "$file" Architecture)
    [[ $arch == amd64 || $arch == all ]] || {
        echo "$label 的安装包架构不匹配" >&2; return 1;
    }
    chmod a+r "$file"
    sudo apt-get install -y -- "$file"
}

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

clone_once() {
    local repo=$1 dest=$2
    if [[ -e $dest ]]; then
        echo "保留已有目录：$dest"
    else
        git clone --depth 1 "https://github.com/$repo.git" "$dest"
    fi
}

link_skill() {
    local source=$1 target=$2
    [[ -d $source ]] || { echo "Skills 上游目录不存在：$source" >&2; return 1; }
    if [[ -e $target || -L $target ]]; then
        echo "保留已有 Skill：$target"
    else
        ln -s "$source" "$target"
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
        # 使用 WPS 公开下载按钮的 URL 算法，不执行网页 JavaScript。
        url=$(python3 - "$TMP/wps.html" <<'PY'
import hashlib, re, sys, time
from pathlib import Path
from urllib.parse import urlsplit
html = Path(sys.argv[1]).read_text()
urls = set(re.findall(r"https://wps-linux-personal\.wpscdn\.cn/[^\s'\"<>]+_amd64\.deb", html))
key = re.search(r'var\s+secrityKey\s*=\s*[\"\x27]([a-zA-Z0-9]+)[\"\x27]', html)
if len(urls) != 1 or key is None:
    raise SystemExit("WPS 官网下载格式已变化，请更新脚本或设置 WPS_DEB_URL")
url = urls.pop()
timestamp = str(int(time.time()))
digest = hashlib.md5((key[1] + urlsplit(url).path + timestamp).encode()).hexdigest()
print(f"{url}?t={timestamp}&k={digest}")
PY
        )
    fi
    install_deb "$url" wps
}

app_sunlogin() {
    if [[ $DISTRO == arch ]]; then arch_install sunloginclient
    else install_deb "${SUNLOGIN_DEB_URL:-https://dw.oray.com/sl/linux/awesun_16.6.0.32198_amd64.deb}" sunlogin; fi
}

skill_sources() {
    cat <<'SKILLS'
tt-a1i/archify	archify	archify
Hisn00w/ASu-skills	.	asu-skills
alchaincyf/nuwa-skill	.	nuwa-skill
Leonxlnx/taste-skill	skills/taste-skill	taste
mattpocock/skills	skills/engineering/code-review	code-review
mattpocock/skills	skills/productivity/grill-me	grill-me
mattpocock/skills	skills/productivity/grilling	grilling
mattpocock/skills	skills/engineering/to-spec	to-spec
mattpocock/skills	skills/engineering/to-tickets	to-tickets
SKILLS
}

skills() {
    local sources="$DATA/skills-sources" dest="${CODEX_HOME:-$HOME/.codex}/skills" repo path name
    mkdir -p "$sources" "$dest"
    while IFS=$'\t' read -r repo path name; do
        [[ -n $repo && $repo != \#* ]] || continue
        clone_once "$repo" "$sources/${repo//\//--}"
        link_skill "$sources/${repo//\//--}/$path" "$dest/$name"
    done < <(skill_sources)
}

main() {
    case "${1:-}" in
        --help|-h) echo '用法：bash install-apps-skills.sh [--dry-run]'; return ;;
        --dry-run|'') ;;
        *) echo "未知选项：$1" >&2; return 1 ;;
    esac
    [[ $# -le 1 ]] || { echo '参数过多' >&2; return 1; }
    source /etc/os-release
    DISTRO=$(detect_platform "$ID" "${VERSION_ID:-}" "$(uname -m)")
    export DISTRO
    local -a stages=(bootstrap node_runtime)
    stages+=(app_vscode app_flclash app_cc_switch app_snipaste app_typora app_wechat app_qq app_wemeet app_wps app_sunlogin skills)
    printf '系统：%s %s，架构：x86_64，安装组：apps-skills\n' "$ID" "${VERSION_ID:-rolling}"
    if [[ ${1:-} == --dry-run ]]; then
        echo '仅预览清单与执行阶段；不联网、不安装，不解析未来的下载版本或包依赖。'
        printf '%s\n' "${stages[@]}"
        skill_sources
        return
    fi
    [[ $EUID != 0 ]] || { echo '请以普通用户运行，脚本会按需调用 sudo。' >&2; return 1; }
    sudo -v
    mkdir -p "$DATA/logs"
    local report stage
    report="$DATA/logs/$(date +%Y%m%d-%H%M%S)-apps-skills.tsv"
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
