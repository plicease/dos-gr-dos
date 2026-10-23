# GR-DOS — Source Provenance (M0)

**Status:** M0 inventory, living document  
**Upstream:** https://github.com/microsoft/MS-DOS at `2d04cacc5322951f187bb17e017c12920ac8ebe2` (2024-04-25)

## Vendored source

`v4.0/` is an unmodified copy of upstream `v4.0/` (commit `964aee7`). The git tree hash `c76f5199c39b0bcd5ec848afc249a188a2ac7e1c` matches upstream exactly. `.gitattributes` disables line-ending conversion for it.

Upstream history is a single squashed commit, so there is no earlier published state of `v4.0` to compare against.

- **License:** `v4.0/LICENSE` is MIT, "Copyright (c) IBM and Microsoft Corporation". Upstream's repository root `LICENSE` names Microsoft alone; `v4.0` carries its own.
- **GR-DOS license:** the root `LICENSE` (MIT, Graham Ollis) covers GR-DOS's own scripts, patches and documentation (decision 8). It does not relicense `v4.0`. The JWasm patches in `patches/jwasm` modify JWasm, which is under the Sybase Open Watcom Public License.
- **Branding:** `patches/branding` (decision 7) changes two COMMAND messages in `MESSAGES/USA-MS.MSG` to say GR-DOS. It is applied to a copy of `v4.0/src` at build time, so every edit committed to `v4.0` still leaves the M1 build identical.
- **Not vendored:** `v1.25`, `v2.0` (unrelated versions) and `v4.0-ozzie` (Multitasking DOS 4 beta binaries and PDFs, not the source used here).

## Tree contents

1,281 files under `v4.0/src`: 584 `.ASM`, 241 `.INC`, 88 `.H`, 60 `.C`, 49 `.SKL` message skeletons, 51 `.LNK` link response files, 74 makefiles.

| Directory | Files | Builds |
|---|---|---|
| `BOOT` | 3 | Boot sector (`msboot.bin`) |
| `BIOS` | 39 | `IO.SYS` |
| `DOS` | 86 | `MSDOS.SYS` |
| `INC` | 90 | Shared includes, plus objects linked into `MSDOS.SYS` |
| `CMD` | 526 | `COMMAND.COM` and external commands |
| `DEV` | 201 | Device drivers |
| `MESSAGES` | 2 | `USA-MS.MSG` message source and its index |
| `MAPPER` | 66 | `mapper.lib`, used by C utilities |
| `MEMM` | 79 | `EMM386.SYS` |
| `SELECT` | 80 | `SELECT` installer |
| `H`, `LIB` | 23 | C headers, library objects |
| `TOOLS` | 81 | Historical build tool binaries, MS C headers and runtime libraries |

## Encoding and line endings

- **Line endings.** 1,215 of 1,223 text files use LF only; 3 use CRLF; 5 have no line breaks. Upstream evidently normalised CRLF to LF. DOS-hosted tools may need CRLF restored by the build scripts.
- **CP437 intact.** 110 files contain raw non-ASCII bytes that are not valid UTF-8, i.e. CP437 survived (mostly `DEV/KEYBOARD`, `CMD/MODE`, `DEV/DISPLAY`, `CMD/FDISK`).
- **Damaged.** 20 files were converted to UTF-8 with original bytes replaced by U+FFFD (`EF BF BD`). The original bytes are unrecoverable from these files alone:
  - `SELECT/`: `COLORS.ASM`, `DATA.MAC`, `INPUT.ASM`, `PANELS.ASM`, `ROUTINES.ASM`, `SCROLL.ASM`, `SELECT0.ASM`–`SELECT7.ASM`, `SELECT2A.ASM`, `SELECT5A.ASM`, `SELECT9.ASM`, `USA.INF`
  - `MAPPER/GETMSG.ASM`
  - `DEV/DISPLAY/INT10COM.INC`

**MVP impact:** none of the damaged files are on the path to the boot sector, `IO.SYS`, `MSDOS.SYS` or `COMMAND.COM`. `MAPPER` is linked only by C utilities (FDISK, BACKUP, RESTORE, REPLACE, JOIN, SUBST); `SELECT` and `DISPLAY.SYS` are outside MVP.

## Build system

`SETENV.BAT` puts `src\TOOLS` on `PATH` and sets `COUNTRY=usa-ms`; `NMAKE` at `src` walks `messages, mapper, boot, bios, dos, cmd, dev, select, memm`. Inference rules live in `TOOLS/TOOLS.INI`:

| Rule | Tool |
|---|---|
| `.asm.obj` | `masm -Mx -t -I. -I$(inc) -I$(dos)` |
| `.c.obj` | `cl -AS -Os -Zp -I. -I$(hinc)` |
| `.skl.cl1` | `nosrvbld` |
| `.skl.ctl` | `buildmsg` |
| `.msg.idx` | `buildidx` |
| `.exe.com` | `reloc` |

### Tools in `TOOLS/`

- **Microsoft language tools:** `MASM.EXE`, `LINK.EXE`, `LIB.EXE`, `NMAKE.EXE`, `EXE2BIN.EXE`, `EXEPACK.EXE`, `EXEMOD.EXE`, Microsoft C (`CL.EXE`, `C1.EXE`, `C1L.EXE`, `C2.EXE`, `C3.EXE`), with MS C headers in `TOOLS/BLD/INC` and runtime libraries in `TOOLS/BLD/LIB`.
- **DOS build tools, binary only (no source anywhere in the tree):** `BUILDMSG`, `BUILDIDX`, `NOSRVBLD`, `DBOF`, `MENUBLD`, `CONVERT`, `COMPRESS`, `ASC2HLP`, `EXEFIX`.
- **Referenced but absent:** `reloc` (`.exe.com` rule) and `asm87`.

All are inside `v4.0/` and therefore under its MIT license as published. Decision 4 still applies: they may be run under emulation for M1, never in CI.

### Core MVP path

| Component | Steps | Tools needed |
|---|---|---|
| `MESSAGES` | `USA-MS.MSG` → `.IDX` | `BUILDIDX` |
| Boot sector | `BOOT.SKL` → `.CL1`; assemble, link, `exe2bin`, `dbof` → `INC\BOOT.INC` | `NOSRVBLD`, `MASM`, `LINK`, `EXE2BIN`, `DBOF` |
| `IO.SYS` | `MSBIO.SKL` → `.CL1`–`.CL5`; `MSLOAD.COM` + `MSBIO.BIN` (`exe2bin` with load segment `70` from `LOCSCR`) concatenated | `NOSRVBLD`, `MASM`, `LINK`, `EXE2BIN` |
| `MSDOS.SYS` | `MSDOS.SKL` → `.CL1`; objects from `DOS` and `INC`; `exe2bin` | `NOSRVBLD`, `MASM`, `LINK`, `EXE2BIN` |
| `COMMAND.COM` | `COMMAND.SKL` → `.CTL`, `.CL*`; `exe2bin` | `BUILDMSG`, `MASM`, `LINK`, `EXE2BIN` |

**M2 consequence:** Open Watcom replaces `MASM`, `LINK` and `EXE2BIN`, but `BUILDMSG`, `BUILDIDX`, `NOSRVBLD` and `DBOF` have no source and no Watcom equivalent. A Linux-native build needs reimplementations, specified from their inputs (`.SKL`, `.MSG`) and the outputs captured in the M1 reference build.

## Community restorations

All GitHub sources below are forks of microsoft/MS-DOS with the upstream MIT `LICENSE` unchanged. Comparisons were made with CR stripped, since some forks convert line endings.

### hharte/MS-DOS

`1f506100a818cb9b6c2b29aeda8d4d24d094c477` (Howard M. Harte, 2024-04-27), "v4.00: Fix loss of fidelity due to UTF-8 conversion".

- Restores exactly the 20 damaged files to raw CP437, leaving no U+FFFD. Comments are a stated "best effort"; SELECT build outputs are stated to match the original distribution.
- **Defect:** `SELECT/SCROLL.ASM` `WR_PIIND DB '?'`; every other source has `0FEh` (■).
- Later commits add distribution files (`c42c7d0`) and reverse-engineered DOS 4.01 fixes on branch `dos-4.01` (`7e51e42`); neither is in MVP scope.

### lotharsm/MS-DOS, branch `dos-4.00-reconstructed`

hharte's commits plus six by Lothar Serra Mari (2024-04-29 to 05-01):

- `5a4062a`, `0b3b60e`, `d219373`: convert line endings to CRLF only.
- `65fac21`, `a806685`: fix `SETENV.BAT` paths to `tools\bld\lib` / `tools\bld\inc`.
- `500867d`: ecm's patch for `PANELS.ASM`, `SCROLL.ASM`, `USA.INF`, replacing CP437 literals with numeric bytes (e.g. `0DAh`) and box-drawing comments with `#`, making these files ASCII. Fixes `WR_PIIND`. Data bytes otherwise identical to hharte's.
- `d219373` states that, except for `SELECT.DAT`, the binaries match the retail MS-DOS 4.00.

### ecm, hg.pushbx.org/ecm/msdos4 rev `63a05668c5f3`

Original source of lotharsm `500867d`. The repository requires a password, so its license cannot be verified. Because `500867d` was committed by Lothar Serra Mari on ecm's behalf, the fork's MIT license does not clearly cover it. **Not used.** Including it would need ecm's permission.

### chasonr/MS-DOS

`main` (18 commits, Ray Chason, 2024-04-30 to 2025-05-19): an independent restoration plus DOS-hosted build fixes.

- `0ecc065`, `f4a7323`: restore all 20 damaged files to raw CP437. Data bytes agree with hharte/ecm, including `WR_PIIND = 0FEh`.
- `.gitattributes` forcing CRLF for `.SKL`, `LOCSCR`, `ZERO.DAT` and others, and `^Z` stripped from 18 `.SKL` files; commit messages state `NOSRVBLD` and `EXE2BIN` fail otherwise.
- Clean targets, `.gitignore`s, rebuilding `4201.CPI`/`4208.CPI` and `STRING.OBJ`/`PRINTF.OBJ` from source, a Ruby floppy-image builder, build instructions for DOSBox/DOSEMU with the bundled tools.
- **Branch `linux-build-2`**: see the review below.

#### Review of `linux-build-2`

Head `d963a6298bc450de12ab305c8f71b9a911060c55` (2025-05-19). 106 commits by Ray Chason on top of chasonr `main` at `cff1c74`, so it includes his restoration. All changes are by the committer in an MIT fork.

What it does:

- **Linux-native build.** GNU makefiles beside the original `MAKEFILE`s, using JWasm (`-Zm -Zg`), Open Watcom `wlink`, `wcl`, `wlib` and `exe2bin`. No GNU makefile invokes a DOS-hosted tool.
- **Tool replacements in Ruby** (`v4.0/src/bldtools/`): `buildmsg.rb` (covers both BUILDMSG and NOSRVBLD), `hexify.rb` (DBOF), `make-com.rb` (CONVERT), `menubld.rb`, `rlencode.rb` (COMPRESS), `asc2hlp.rb`, `exefix.rb`. BUILDIDX is removed from the build.
- **Coverage.** Every directory, including SELECT and EMM386. C utilities are ported to Watcom C (`__watcall`), and `comsubs.lib` is rebuilt from reconstructed sources. Missing, per its README: HIMEM.SYS, GW-BASIC, DOS Shell.

Why GR-DOS does not adopt it wholesale:

- **Language.** Ruby tools; GR-DOS uses Perl (decision 11).
- **Renames.** 1,041 files lowercased, diverging from the vendored tree layout (decision 1).
- **Large source edits.** Ignoring whitespace and CR: DOS +1415/−1213 lines, COMMAND +550/−501, INC +246/−318, BIOS +164/−150, BOOT +11/−2. JWasm does not accept the MASM 5 macros `retz`, `transfer` and `error`, so their uses were hand-expanded into explicit jumps and labels, plus `short` qualifiers and include changes. Code layout is therefore not byte-identical to the Microsoft build.
- **Unverified.** No commit claims comparison against a reference build or a successful boot. Not built or booted during this review (JWasm not installed).

Implications for GR-DOS:

- `wasm` may hit the same MASM 5 macro limitations as JWasm; the `wasm`-preferred ordering in the toolchain section is untested.
- M1 (reference build with the original tools) comes first, providing binaries and intermediate files (`.CL*`, `.CTL`, `BOOT.INC`) to verify any port against.
- M2 ports only the MVP core (BOOT, BIOS, DOS, INC, CMD/COMMAND, MESSAGES) on the vendored tree, keeping original filenames and minimal edits, using linux-build-2 commits as a guide with their hashes cited, and comparing output to M1 by disassembly.
- The Perl replacements for BUILDMSG/NOSRVBLD and DBOF use `buildmsg.rb` and `hexify.rb` as design references, verified against M1 intermediates.

### AndresTraks/MS-DOS-FASM

Ports v1.25 and v2.0 to FASM; does not touch v4.0. Not relevant.

### Agreement

The three independent restorations (hharte, ecm, chasonr) agree on every assembled data byte, apart from hharte's `WR_PIIND` error and comment text. This is inferred from comparing `DB` data, not from assembling.

### Restoration basis for GR-DOS

1. hharte `1f50610`: all 20 damaged files.
2. GR-DOS fix: `SELECT/SCROLL.ASM` `WR_PIIND DB 0FEh`, the value independently restored by chasonr (`0ecc065`, `f4a7323`) and ecm.
3. Build fixes as separate commits: `SETENV.BAT` paths (lotharsm), and chasonr's CRLF / `^Z` handling where the original DOS tools are used (preferably done by build scripts rather than in the tree, per decision 2).

Each applied patch records the source commit hash and author.

## Local environment (M0 survey)

Ubuntu 26.04.1, QEMU 10.2.1, NASM 3.01, GNU Make 4.4.1, DOSBox and DOSBox-X installed. Not installed: mtools (decision 12), 86Box (decision 9), Mercurial. Open Watcom present at `~/opt/watcom` is a rolling build, not the pinned `2026-10-01-Build` (decision 10).

## Open items for M1

- Reference build under DOSBox-X with `TOOLS/` binaries, recording hashes of every intermediate (`.IDX`, `.CL*`, `.CTL`, `BOOT.INC`) as the specification for reimplemented tools.
- Whether `MASM` 5 and `NMAKE` accept LF-only sources or need CRLF restored (chasonr reports `NOSRVBLD` and `EXE2BIN` need CRLF input).
- Capture every intermediate the Perl tool replacements must reproduce (see the `linux-build-2` review).