#!/usr/bin/env python3
"""Audit a built executable for dependencies from forbidden system prefixes."""

from __future__ import annotations

import argparse
import glob
import os
import re
import subprocess
import sys
from pathlib import Path


DEFAULT_CANDIDATES = (
    ".local/bin/muse/bin/g4PSI",
    ".local/bin/muse/bin/*",
    ".install/muse/bin/g4PSI",
    ".install/muse/bin/*",
)

DEFAULT_FORBIDDEN = r"(/opt/homebrew|/usr/local|/home/linuxbrew|/sw/|/opt/local|spack)"


def expand_candidates(patterns: list[str], root: Path) -> list[Path]:
    candidates: list[Path] = []
    seen: set[Path] = set()
    for pattern in patterns:
        for value in sorted(glob.glob(str(root / pattern))) or [str(root / pattern)]:
            path = Path(value)
            if path not in seen:
                seen.add(path)
                candidates.append(path)
    return candidates


def select_candidate(patterns: list[str], root: Path) -> Path | None:
    return next((path for path in expand_candidates(patterns, root) if path.is_file() and os.access(path, os.X_OK)), None)


def runner_os(explicit: str | None = None) -> str:
    if explicit:
        return explicit
    env_value = os.environ.get("RUNNER_OS")
    if env_value:
        return env_value
    if sys.platform == "darwin":
        return "macOS"
    if sys.platform.startswith("linux"):
        return "Linux"
    return sys.platform


def dependency_command(candidate: Path, platform_name: str) -> list[str]:
    commands = {"macOS": ["otool", "-L", str(candidate)], "Linux": ["ldd", str(candidate)]}
    try:
        return commands[platform_name]
    except KeyError as exc:
        raise ValueError(f"unsupported platform for dependency audit: {platform_name}") from exc


def command_output(command: list[str]) -> str:
    result = subprocess.run(
        command,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if result.returncode != 0:
        command_text = " ".join(command)
        raise RuntimeError(
            f"dependency command failed with exit code {result.returncode}: {command_text}\n{result.stdout}"
        )
    return result.stdout


def forbidden_dependency_lines(output: str, forbidden_pattern: str) -> list[str]:
    forbidden = re.compile(forbidden_pattern)
    return [line.rstrip() for line in output.splitlines() if forbidden.search(line)]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path.cwd(),
        help="repository root used to resolve candidate paths",
    )
    parser.add_argument(
        "--candidate",
        action="append",
        default=[],
        help="candidate executable path relative to root; can be provided multiple times",
    )
    parser.add_argument(
        "--candidate-glob",
        action="append",
        default=[],
        help="candidate executable glob relative to root; can be provided multiple times",
    )
    parser.add_argument(
        "--forbidden-regex",
        default=DEFAULT_FORBIDDEN,
        help="regular expression for forbidden dependency paths",
    )
    parser.add_argument(
        "--platform",
        choices=("Linux", "macOS"),
        default=None,
        help="override platform detection",
    )
    args = parser.parse_args(argv)

    root = args.root.resolve()
    patterns = args.candidate + args.candidate_glob or list(DEFAULT_CANDIDATES)
    candidate = select_candidate(patterns, root)

    if candidate is None:
        print("error: could not find installed executable to audit", file=sys.stderr)
        for pattern in patterns:
            print(f"checked: {pattern}", file=sys.stderr)
        return 2

    platform_name = runner_os(args.platform)
    command = dependency_command(candidate, platform_name)
    print(f"Auditing {candidate}")
    print(f"Running {' '.join(command)}")

    try:
        deps = command_output(command)
    except (OSError, RuntimeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    print(deps, end="" if deps.endswith("\n") else "\n")

    forbidden_lines = forbidden_dependency_lines(deps, args.forbidden_regex)
    if forbidden_lines:
        print("error: runtime dependency leaked from forbidden system prefix", file=sys.stderr)
        for line in forbidden_lines:
            print(line, file=sys.stderr)
        return 2

    print("runtime dependency audit OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
