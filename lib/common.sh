#!/usr/bin/env bash
# 被安装入口加载；不在当前电脑上主动执行安装。
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# 共享给加载本文件的 install.sh 和 stages.sh。
# shellcheck disable=SC2034
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
    python3 "$ROOT/lib/resolve.py" github "$TMP/release.json" "$repo" "$pattern" > "$TMP/asset.txt"
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

link_skill() {
    local source=$1 target=$2
    [[ -d $source ]] || { echo "Skills 上游目录不存在：$source" >&2; return 1; }
    if [[ -e $target || -L $target ]]; then
        echo "保留已有 Skill：$target"
    else
        ln -s "$source" "$target"
    fi
}
