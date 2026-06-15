#!/usr/bin/env python3
"""Validate repo wiring that tends to drift during shell refactors."""

from __future__ import annotations

import argparse
import os
import re
import sys
import tomllib
from pathlib import Path


REQUIRED_EXECUTABLES = (
    "scripts/bootstrap-pixi.sh",
    "scripts/dispatch.sh",
    "scripts/pixi-local",
    "scripts/pixi-local.in",
    "scripts/pixi-use-current-platform.sh",
    "scripts/probe-host.sh",
    "scripts/probe-xqilla.sh",
    "scripts/build-xqilla.sh",
    "scripts/build-clhep.sh",
    "scripts/build-geant4.sh",
    "scripts/build-genfit.sh",
    "scripts/build-muse.sh",
    "scripts/ccmake-muse.sh",
    "scripts/install-configured-muse.sh",
    "scripts/stack-shell.sh",
)

REQUIRED_CONFIGS = (
    "configs/paths.sh",
    "configs/build.sh",
    "configs/sources.sh",
    "configs/muse.sh",
    "configs/source.toml",
)

REQUIRED_WORKFLOWS = (
    ".github/workflows/ci.yml",
    ".github/workflows/full-stack.yml",
)

STALE_REFERENCES = (
    "scripts/muse-cmake-args.sh",
)

TEXT_SUFFIXES = {".md", ".py", ".sh", ".toml", ".txt", ".yaml", ".yml"}
IGNORED_DIRS = {".git", ".install", ".local", ".pixi", "__pycache__"}
BASH_SCRIPT_PATTERN = re.compile(r"(?:^|[;&|]\s*)bash\s+([A-Za-z0-9_./-]+)")


def repo_root(start: Path) -> Path:
    for path in (start, *start.parents):
        if (path / "pixi.toml").is_file() and (path / "scripts").is_dir():
            return path
    raise ValueError(f"could not locate repo root from {start}")


def load_pixi_tasks(root: Path) -> dict[str, object]:
    with (root / "pixi.toml").open("rb") as handle:
        data = tomllib.load(handle)
    tasks = data.get("tasks", {})
    if not isinstance(tasks, dict):
        raise ValueError("pixi.toml [tasks] must be a table")
    return tasks


def task_command(task: object) -> str | None:
    if isinstance(task, str):
        return task
    cmd = task.get("cmd") if isinstance(task, dict) else None
    return cmd if isinstance(cmd, str) else None


def task_dependencies(task: object) -> list[str]:
    if not isinstance(task, dict):
        return []
    deps = task.get("depends-on", [])
    if isinstance(deps, str):
        return [deps]
    return deps if isinstance(deps, list) and all(isinstance(dep, str) for dep in deps) else ["<invalid depends-on>"]


def bash_script_references(tasks: dict[str, object]):
    for name, task in tasks.items():
        cmd = task_command(task)
        if not cmd:
            continue
        for match in BASH_SCRIPT_PATTERN.finditer(cmd):
            yield name, match.group(1)


def iter_text_files(root: Path):
    for path in root.rglob("*"):
        if any(part in IGNORED_DIRS for part in path.parts):
            continue
        if path.is_file() and path.suffix in TEXT_SUFFIXES:
            yield path


def validate_repo(root: Path) -> list[str]:
    errors: list[str] = []

    for label, paths in (("config file", REQUIRED_CONFIGS), ("workflow", REQUIRED_WORKFLOWS)):
        errors.extend(f"missing {label}: {path}" for path in paths if not (root / path).is_file())

    for relpath in REQUIRED_EXECUTABLES:
        script = root / relpath
        if not script.is_file():
            errors.append(f"missing executable script: {relpath}")
        elif not os.access(script, os.X_OK):
            errors.append(f"script is not executable: {relpath}")

    template = root / "scripts/pixi-local.in"
    generated = root / "scripts/pixi-local"
    if template.is_file() and generated.is_file():
        if template.read_bytes() != generated.read_bytes():
            errors.append("scripts/pixi-local differs from scripts/pixi-local.in")

    try:
        tasks = load_pixi_tasks(root)
    except (OSError, tomllib.TOMLDecodeError, ValueError) as exc:
        errors.append(f"could not load pixi.toml tasks: {exc}")
        tasks = {}

    errors.extend(
        f"pixi task {task!r} references missing script: {script}"
        for task, script in bash_script_references(tasks)
        if not (root / script).is_file()
    )

    for task_name, task in tasks.items():
        for dep in task_dependencies(task):
            errors += (
                [f"pixi task {task_name!r} has invalid depends-on value"]
                if dep == "<invalid depends-on>"
                else [f"pixi task {task_name!r} depends on unknown task: {dep}"] if dep not in tasks else []
            )

    for relpath in STALE_REFERENCES:
        needle = relpath.encode()
        for path in iter_text_files(root):
            scanned_relpath = path.relative_to(root).as_posix()
            if scanned_relpath in {relpath, "scripts/python/validate_repo_contract.py"}:
                continue
            try:
                if needle in path.read_bytes():
                    errors.append(f"stale reference to {relpath}: {scanned_relpath}")
            except OSError as exc:
                errors.append(f"could not read {scanned_relpath}: {exc}")

    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="repository root; defaults to nearest pixi.toml parent",
    )
    args = parser.parse_args(argv)

    root = args.root.resolve() if args.root else repo_root(Path.cwd().resolve())
    errors = validate_repo(root)

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"repo contract OK: {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
