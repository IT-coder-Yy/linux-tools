#!/usr/bin/env bash
set -Eeuo pipefail
case "${1:-}" in
    apps) script=install-apps-skills.sh ;;
    tools) script=install-tools.sh ;;
    *) echo '用法：bash linux-tools-install.sh apps|tools [--dry-run]' >&2; exit 1 ;;
esac
shift
download_dir=$(mktemp -d -t linux-tools-download.XXXXXXXX)
trap 'rm -rf -- "$download_dir"' EXIT
curl -fL --retry 2 --connect-timeout 20 --proto '=https' --proto-redir '=https' \
    https://codeload.github.com/IT-coder-Yy/linux-tools/tar.gz/refs/heads/main \
    -o "$download_dir/source.tar.gz"
tar -xzf "$download_dir/source.tar.gz" -C "$download_dir"
bash "$download_dir/linux-tools-main/$script" "$@"
