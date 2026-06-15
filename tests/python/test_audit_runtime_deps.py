from __future__ import annotations

import importlib.util
import os
import stat
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts/python/audit_runtime_deps.py"

spec = importlib.util.spec_from_file_location("audit_runtime_deps", MODULE_PATH)
audit_runtime_deps = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(audit_runtime_deps)


class AuditRuntimeDepsTests(unittest.TestCase):
    def test_select_candidate_prefers_first_executable_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            paths = [root / "bin/first", root / "bin/second"]
            paths[0].parent.mkdir()
            for path in paths:
                path.write_text("#!/bin/sh\n", encoding="utf-8")
            paths[1].chmod(paths[1].stat().st_mode | stat.S_IXUSR)

            self.assertEqual(
                audit_runtime_deps.select_candidate(["bin/first", "bin/*"], root),
                paths[1],
            )

    def test_forbidden_dependency_lines_reports_matching_lines(self) -> None:
        output = """
        libCore.so => /workspace/.pixi/lib/libCore.so
        libssl.so => /usr/local/lib/libssl.so
        /opt/homebrew/lib/libcrypto.dylib
        """

        self.assertEqual(
            audit_runtime_deps.forbidden_dependency_lines(
                output,
                audit_runtime_deps.DEFAULT_FORBIDDEN,
            ),
            [
                "        libssl.so => /usr/local/lib/libssl.so",
                "        /opt/homebrew/lib/libcrypto.dylib",
            ],
        )

    def test_dependency_command_matches_runner_platforms(self) -> None:
        candidate = Path("program")
        cases = {"Linux": ["ldd", "program"], "macOS": ["otool", "-L", "program"]}
        for platform, command in cases.items():
            with self.subTest(platform=platform):
                self.assertEqual(audit_runtime_deps.dependency_command(candidate, platform), command)

    def test_runner_os_prefers_explicit_value(self) -> None:
        old_value = os.environ.get("RUNNER_OS")
        os.environ["RUNNER_OS"] = "Linux"
        try:
            self.assertEqual(audit_runtime_deps.runner_os("macOS"), "macOS")
        finally:
            if old_value is None:
                os.environ.pop("RUNNER_OS", None)
            else:
                os.environ["RUNNER_OS"] = old_value


if __name__ == "__main__":
    unittest.main()
