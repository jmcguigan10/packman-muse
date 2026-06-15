from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts/python/validate_repo_contract.py"

spec = importlib.util.spec_from_file_location("validate_repo_contract", MODULE_PATH)
validate_repo_contract = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(validate_repo_contract)


class ValidateRepoContractTests(unittest.TestCase):
    def test_current_repo_contract_passes(self) -> None:
        self.assertEqual(validate_repo_contract.validate_repo(ROOT), [])

    def test_bash_script_references_extracts_scripts_from_tasks(self) -> None:
        tasks = {
            "probe-host": "bash scripts/probe-host.sh",
            "build-xqilla": {
                "cmd": "bash scripts/build-xqilla.sh",
                "depends-on": ["probe-host"],
            },
            "build-stack": {"depends-on": ["build-xqilla"]},
        }

        self.assertEqual(
            list(validate_repo_contract.bash_script_references(tasks)),
            [
                ("probe-host", "scripts/probe-host.sh"),
                ("build-xqilla", "scripts/build-xqilla.sh"),
            ],
        )

    def test_validate_repo_reports_missing_task_script(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            (root / ".github/workflows").mkdir(parents=True)

            for relpath in validate_repo_contract.REQUIRED_EXECUTABLES:
                path = root / relpath
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("#!/usr/bin/env bash\n", encoding="utf-8")
                path.chmod(0o755)

            for relpath in (
                *validate_repo_contract.REQUIRED_CONFIGS,
                *validate_repo_contract.REQUIRED_WORKFLOWS,
            ):
                path = root / relpath
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("", encoding="utf-8")

            (root / "scripts/pixi-local").write_text("wrapper\n", encoding="utf-8")
            (root / "scripts/pixi-local.in").write_text("wrapper\n", encoding="utf-8")
            (root / "pixi.toml").write_text(
                """
                [tasks]
                broken = "bash scripts/missing.sh"
                """,
                encoding="utf-8",
            )

            self.assertIn(
                "pixi task 'broken' references missing script: scripts/missing.sh",
                validate_repo_contract.validate_repo(root),
            )


if __name__ == "__main__":
    unittest.main()
