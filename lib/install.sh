#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
group=${1:?}; expected=${2:?}; shift 2
case "$group" in apps|tools) ;; *) echo '安装组必须为 apps 或 tools' >&2; exit 1;; esac
case "${1:-}" in
    --help|-h) echo '用法：bash install-apps-skills.sh [--dry-run] 或 bash install-tools.sh [--dry-run]'; exit 0;;
    --dry-run|'') ;;
    *) echo "未知选项：$1" >&2; exit 1;;
esac
[[ $# -le 1 ]] || { echo '参数过多' >&2; exit 1; }
source /etc/os-release
DISTRO=$(detect_platform "$ID" "${VERSION_ID:-}" "$(uname -m)")
[[ $expected == auto || $expected == "$DISTRO" ]] || { echo "脚本版本 $expected 与本机 $DISTRO 不匹配" >&2; exit 1; }
export DISTRO

stages=(bootstrap node_runtime)
if [[ $group == apps ]]; then
    stages+=(app_vscode app_flclash app_cc_switch app_snipaste app_typora app_wechat app_qq app_wemeet app_wps app_sunlogin skills)
else
    stages+=(system_packages rust_runtime)
    if [[ $DISTRO == ubuntu ]]; then
        stages+=(tool_lazygit tool_lazydocker tool_abtop tool_fastfetch tool_yazi tool_genact tool_tokei tool_starship tool_uv tool_bun tool_ngrok nerd_font)
    fi
    stages+=(python_tools ai_tools dsh_plugins shell_plugins)
    if [[ $DISTRO == arch ]]; then stages+=(arch_extras); fi
fi
printf '系统：%s %s，架构：x86_64，安装组：%s\n' "$ID" "${VERSION_ID:-rolling}" "$group"
if [[ ${1:-} == --dry-run ]]; then
    echo '仅预览清单与执行阶段；不联网、不安装，不解析未来的下载版本或包依赖。'
    printf '%s\n' "${stages[@]}"
    if [[ $group == tools ]]; then cat "$ROOT/manifests/tools-$DISTRO.txt"
    else cat "$ROOT/manifests/apps.tsv" "$ROOT/manifests/skills.tsv"; fi
    exit 0
fi
[[ $EUID != 0 ]] || { echo '请以普通用户运行，脚本会按需调用 sudo。' >&2; exit 1; }
sudo -v
mkdir -p "$DATA/logs"
report="$DATA/logs/$(date +%Y%m%d-%H%M%S)-$group.tsv"
failures=()
for stage in "${stages[@]}"; do
    printf '\n>>> %s\n' "$stage"
    # 单独 Bash 保留 errexit 语义；不要在 if 中直接调用含 set -e 的函数。
    if bash "$ROOT/lib/run-stage.sh" "$stage" 2>&1 | tee -a "${report%.tsv}.log"; then
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
    exit 1
fi
echo '所选安装阶段完成。桌面启动和实际功能仍需在新电脑上验证。'
