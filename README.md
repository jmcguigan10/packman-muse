# MUSE local build stack

This repository bootstraps a repo-local Pixi environment and builds the MUSE
simulation stack into repo-local install prefixes. Pixi owns the compiler,
ROOT, Xerces-C, GSL, Boost, OpenSSL, and other binary base libraries. The
source-built stack installs under `.local/bin`.

## First clone

From a fresh clone, run these commands from the repository root:

```bash
bash scripts/bootstrap-pixi.sh
./scripts/pixi-local install
./scripts/pixi-local run -e batch build-stack
```

That is the complete default build. It builds, in order:

1. XQilla
2. CLHEP
3. Geant4
4. GenFit
5. MUSE/g4PSI

The build downloads source archives, clones source repositories, downloads
Geant4 data, and installs all source-built outputs under `.local/bin`.

## Requirements

You need:

- `curl` available on the host to download the local Pixi executable.
- Network access for Pixi packages and source downloads.
- GitHub SSH access for the MUSE/GenFit source repositories.
- On macOS, an installed Apple developer toolchain/SDK. The project uses the
  Pixi compiler, but the compiler still targets the system macOS SDK.

The GenFit and MUSE source URLs are SSH URLs. Before the first full build,
verify your key works:

```bash
ssh -T git@github.com
```

On macOS the build scripts use `/usr/bin/ssh` for Git so that normal Keychain
SSH behavior works.

WSL2 on Windows is supported through Ubuntu and is tested in CI. Keep the
checkout inside the WSL filesystem, for example under `~/code`, rather than
under `/mnt/c`, then use the same commands as Linux:

```bash
bash scripts/bootstrap-pixi.sh
./scripts/pixi-local install
./scripts/pixi-local run -e batch build-stack
```

## What bootstrap creates

`scripts/bootstrap-pixi.sh` installs Pixi locally and installs
`scripts/pixi-local` from the committed `scripts/pixi-local.in` template.

Important generated paths:

```text
.local/bin/pixi          local Pixi executable
.local/pixi-home/       Pixi home
.local/pixi-cache/      Pixi package cache
.pixi/envs/batch/       Pixi environment
.install/src/           downloaded/cloned source trees
.install/build/         build directories
.install/state/         build stamp files
.install/logs/          log directory
.local/bin/xqilla/      XQilla install prefix
.local/bin/clhep/       CLHEP install prefix
.local/bin/geant4/      Geant4 install prefix
.local/bin/genfit/      GenFit install prefix
.local/bin/muse/        MUSE install prefix
.local/bin/shared/      MUSE shared data install
```

Use `./scripts/pixi-local`, not a global `pixi`, for this repo. The wrapper
keeps `PIXI_HOME` and `PIXI_CACHE_DIR` inside the repository.

## Platform selection

`scripts/pixi-local` automatically runs
`scripts/pixi-use-current-platform.sh` before `install`, `lock`, `run`,
`shell`, `add`, `remove`, `update`, or `upgrade`.

That helper detects the current machine and rewrites `pixi.toml` to use only
the current Pixi platform:

```text
Linux x86_64   -> linux-64
Linux arm64    -> linux-aarch64
macOS x86_64   -> osx-64
macOS arm64    -> osx-arm64
```

It also keeps the Pixi C and C++ compiler dependencies under the active target
platform. This avoids solving and installing compiler toolchains for machines
you are not currently building on.

To disable the automatic platform rewrite for one command:

```bash
PIXI_AUTO_PLATFORM=0 ./scripts/pixi-local install
```

## Running commands after build

To enter the prepared runtime environment:

```bash
./scripts/pixi-local run -e batch stack-shell
```

Or run one command inside it:

```bash
./scripts/pixi-local run -e batch bash scripts/stack-shell.sh g4PSI path/to/macro.mac
```

RadGen modes are selected with command-line flags, not macro commands:

```bash
./scripts/pixi-local run -e batch bash scripts/stack-shell.sh g4PSI --rad2 path/to/macro.mac
./scripts/pixi-local run -e batch bash scripts/stack-shell.sh g4PSI --rad3 path/to/macro.mac
```

Current pinned MUSE source has a RadGen bug where `--rad2` can crash during
physics initialization because `G4NuclearStopping* nucStopping` is left
uninitialized in `g4PSI/RadGen/src/g4PSIEmStandardPhysics.cc`. Until that fix
is merged upstream, use a patched MUSE checkout/branch for Rad2 work.

The runtime environment puts local source-built prefixes first, then the Pixi
environment. It also sets `COOKERHOME` so g4PSI can find the installed MUSE
shared data at `.local/bin/.muse/shared`.

## Script organization

Top-level files under `scripts/` are public command entrypoints used by Pixi
tasks and README examples. Keep those filenames stable.

Source-only defaults live in `configs/*.sh`. These files should only assign
overridable variables such as source URLs, pinned SHAs, install-prefix names,
and CMake defaults.

Reusable shell functions live under `scripts/lib/`:

```text
core/          logging, paths, stamps, checksums
platform/      platform detection, toolchain, Pixi manifest rewrite
build/         downloads, Git checkout, CMake/library discovery, runtime env
pixi/          Pixi bootstrap and wrapper helpers
components/    XQilla, CLHEP, Geant4, GenFit, MUSE, probes
```

The main environment loader is `scripts/env.sh`. It sources configs and libs,
sets up the repo-local Pixi/source-built environment, then exposes component
functions to the top-level entrypoints.

## Build control

The task graph is defined in `pixi.toml`.

Useful commands:

```bash
./scripts/pixi-local run -e batch probe-host
./scripts/pixi-local run -e batch build-xqilla
./scripts/pixi-local run -e batch probe-xqilla
./scripts/pixi-local run -e batch build-clhep
./scripts/pixi-local run -e batch build-geant4
./scripts/pixi-local run -e batch build-genfit
./scripts/pixi-local run -e batch build-muse
./scripts/pixi-local run -e batch build-stack
```

For interactive MUSE configuration, do not run raw `ccmake` against the MUSE
source tree. Use the wrapper so CMake receives the same local Pixi/source-built
paths as `build-muse`:

```bash
./scripts/pixi-local run -e batch ccmake-muse
```

If you change anything in `ccmake`, build and install that configured tree with:

```bash
./scripts/pixi-local run -e batch install-configured-muse
```

`build-muse` recreates `.install/build/muse` from the pinned defaults. Use it
for the standard reproducible build, not for preserving manual `ccmake` edits.

If a previous configure picked up Homebrew, Spack, `/usr/local`, or `~/.muse`,
discard that polluted cache first:

```bash
./scripts/pixi-local run -e batch bash scripts/ccmake-muse.sh --fresh
```

Build stamps live in `.install/state`. If a stage already has a stamp, the
script skips it. To force one stage to rebuild, remove that stage's stamp and
its build directory. For example:

```bash
rm -f .install/state/muse.done
rm -rf .install/build/muse
./scripts/pixi-local run -e batch build-muse
```

To remove all local build/install outputs managed by the task:

```bash
./scripts/pixi-local run -e batch clean-local
```

`clean-local` removes `.install` and the source-built prefixes under
`.local/bin`, but it leaves the local Pixi executable, Pixi home/cache, and
`.pixi` environment alone.

## Dependency isolation

The intended dependency order is:

```text
source-built prefixes in .local/bin/*
then the Pixi env in .pixi/envs/<env>
then system runtime only where unavoidable
```

On macOS, `/usr/lib/libSystem.B.dylib` and the Apple SDK are expected system
dependencies. Homebrew, `/usr/local`, Spack, and `~/.muse` should not be used
by the MUSE CMake configuration.

If dependency discovery gets suspicious, inspect the installed binary:

```bash
otool -L .local/bin/muse/bin/g4PSI
otool -l .local/bin/muse/bin/g4PSI | grep -A3 LC_RPATH
```

On Linux, use `ldd`/`readelf` instead.
