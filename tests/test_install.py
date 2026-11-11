"""离线检查分支、下载解析与用户文件保留；不安装任何软件。"""
import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("resolve", ROOT / "lib/resolve.py")
resolve = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resolve)


def bash(code, *args, check=True):
    return subprocess.run(
        ["bash", "-c", 'source "$1/lib/common.sh"; shift; ' + code, "test", str(ROOT), *args],
        capture_output=True, text=True, check=check,
    )


class InstallTests(unittest.TestCase):
    def test_platforms(self):
        self.assertEqual(bash('detect_platform "$@"', "arch", "", "x86_64").stdout.strip(), "arch")
        self.assertEqual(bash('detect_platform "$@"', "ubuntu", "24.04", "x86_64").stdout.strip(), "ubuntu")
        for args in [("ubuntu", "22.04", "x86_64"), ("ubuntu", "26.04", "x86_64"), ("arch", "", "aarch64"), ("debian", "12", "x86_64")]:
            self.assertNotEqual(bash('detect_platform "$@"', *args, check=False).returncode, 0)

    def test_asset_match_and_origin(self):
        asset = {"name": "thing-linux-amd64.deb", "browser_download_url": "https://github.com/owner/repo/releases/download/v1/a.deb", "digest": "sha256:abc"}
        self.assertEqual(resolve.github_asset({"assets": [asset]}, "owner/repo", "*-linux-amd64.deb")[1], "sha256:abc")
        for data in [{"assets": []}, {"assets": [asset, asset]}, {"assets": [{**asset, "browser_download_url": "https://other.example/a.deb"}]}]:
            with self.assertRaises(ValueError):
                resolve.github_asset(data, "owner/repo", "*-linux-amd64.deb")

    def test_wps_public_button_protocol(self):
        html = "var secrityKey = 'public123'; downLoad('https://wps-linux-personal.wpscdn.cn/d/wps_amd64.deb')"
        url = resolve.wps_url(html, 12345)
        self.assertIn("?t=12345&k=", url)
        self.assertEqual(len(url.rsplit("=", 1)[1]), 32)
        with self.assertRaises(ValueError):
            resolve.wps_url("download page changed", 1)

    def test_existing_skill_not_overwritten_and_resources_retained(self):
        with tempfile.TemporaryDirectory() as temporary:
            temp = Path(temporary)
            source, target = temp / "source", temp / "existing"
            source.mkdir(); (source / "references").mkdir()
            target.mkdir(); (target / "SKILL.md").write_text("user content")
            bash('link_skill "$1" "$2"', str(source), str(target))
            self.assertEqual((target / "SKILL.md").read_text(), "user content")
            link = temp / "fresh"
            bash('link_skill "$1" "$2"', str(source), str(link))
            self.assertTrue((link / "references").is_dir())
            self.assertNotEqual(bash('link_skill "$1/missing" "$2/new"', str(source), str(temp), check=False).returncode, 0)

    def test_wrong_deb_architecture_cannot_reach_apt(self):
        code = '''
TMP=$1
download() { :; }
dpkg-deb() { echo arm64; }
sudo() { echo UNEXPECTED_INSTALL; }
install_deb https://example.com/file.deb test
'''
        result = bash(code, "/tmp", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("UNEXPECTED_INSTALL", result.stdout)

    def test_gnome_does_not_install_kwin(self):
        code = '''
source "$ROOT/lib/stages.sh"
BIN=$1; mkdir -p "$BIN"
arch_install() { echo UNEXPECTED_KWIN; }
XDG_CURRENT_DESKTOP=GNOME
arch_extras
'''
        with tempfile.TemporaryDirectory() as temporary:
            result = bash(code, temporary)
            self.assertNotIn("UNEXPECTED_KWIN", result.stdout)
            self.assertIn("跳过", result.stdout)
            self.assertTrue((Path(temporary) / "pack").is_file())

    def test_failure_does_not_fall_through(self):
        # 与 run-stage 相同的 Bash 调用边界，避免 if/function 吞掉 errexit。
        result = bash('set -e; sample() { false; echo WRONG_SUCCESS; }; sample', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("WRONG_SUCCESS", result.stdout)

    def test_manifests_and_entrypoints(self):
        rows = [line.split("\t") for line in (ROOT / "manifests/skills.tsv").read_text().splitlines() if line and not line.startswith("#")]
        self.assertEqual(len(rows), 9)
        self.assertEqual(len({row[2] for row in rows}), 9)
        for group in ["apps-skills", "tools"]:
            for suffix in ["", "-arch", "-ubuntu"]:
                self.assertTrue((ROOT / f"install-{group}{suffix}.sh").is_file())

    def test_shell_syntax(self):
        files = list(ROOT.rglob("*.sh")) + list((ROOT / "bin").iterdir())
        for path in files:
            subprocess.run(["bash", "-n", str(path)], check=True, capture_output=True)


if __name__ == "__main__":
    unittest.main()
