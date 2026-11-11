#!/usr/bin/env python3
"""只解析公开下载元数据，不执行网页中的 JavaScript。"""
import fnmatch
import hashlib
import json
import re
import sys
import time
from pathlib import Path
from urllib.parse import urlsplit


def github_asset(data, repo, pattern):
    assets = [a for a in data.get("assets", []) if fnmatch.fnmatchcase(a["name"], pattern)]
    if len(assets) != 1:
        raise ValueError(f"{repo}: 期望一个 {pattern}，实际找到 {len(assets)} 个")
    asset = assets[0]
    url = asset["browser_download_url"]
    if not url.startswith(f"https://github.com/{repo}/releases/download/"):
        raise ValueError("安装包来源与指定的 GitHub 仓库不符")
    return url, asset.get("digest") or ""


def wps_url(html, timestamp):
    # 与 WPS 公开下载按钮相同的 URL 算法；每次从官网读取公开参数。
    urls = set(re.findall(r"https://wps-linux-personal\.wpscdn\.cn/[^\s'\"<>]+_amd64\.deb", html))
    key = re.search(r'var\s+secrityKey\s*=\s*[\"\x27]([a-zA-Z0-9]+)[\"\x27]', html)
    if len(urls) != 1 or key is None:
        raise ValueError("WPS 官网下载格式已变化，请更新解析器或设置 WPS_DEB_URL")
    url = urls.pop()
    digest = hashlib.md5((key[1] + urlsplit(url).path + str(timestamp)).encode()).hexdigest()
    return f"{url}?t={timestamp}&k={digest}"


if __name__ == "__main__":
    mode, path, *args = sys.argv[1:]
    content = Path(path).read_text()
    if mode == "github":
        print(*github_asset(json.loads(content), *args), sep="\n")
    elif mode == "wps":
        print(wps_url(content, int(time.time())))
    else:
        raise SystemExit("未知解析模式")
