#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
source "$ROOT/lib/stages.sh"
stage=${1:?缺少安装阶段}
TMP=$(mktemp -d -t linux-tools.XXXXXXXX)
chmod 755 "$TMP"
trap 'rm -rf -- "$TMP"' EXIT
trap 'printf "安装阶段失败：%s，第 %s 行\n" "$stage" "$LINENO" >&2' ERR
"$stage"
