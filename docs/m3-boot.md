# M3: Boot image and smoke test

```sh
make          # also builds build/linux/gr-dos.img
make test     # boots a test copy of the image in QEMU and checks the output
```

## Image

`scripts/mkimage` writes a 1.44 MB FAT12 floppy image with mtools
(decisions 5 and 12):

1. The boot sector is the last 512 bytes of `BOOT/MSBOOT.BIN`. The physical
   drive number at offset `24h` is set to `00h`. MSBOOT's default BPB
   describes a hard disk (`80h`), and mformat replaces the geometry but not
   this byte.
2. `mformat -f 1440` is run with that boot sector and no volume label. A
   label would take the first directory entry, where the boot sector
   expects `IO.SYS`.
3. `IO.SYS` and `MSDOS.SYS` are copied first, then marked system, hidden and
   read-only. `COMMAND.COM` and any other files follow.
4. `scripts/check-image` checks the boot signature and the drive number. It
   checks that `IO.SYS` and `MSDOS.SYS` are the first two directory entries
   and have the system attribute. It also checks that `IO.SYS` starts at the
   first data cluster, that `MSDOS.SYS` follows it, and that both are
   contiguous and match the built files.

The image is reproducible. File times come from `SOURCE_DATE_EPOCH`, and
the volume serial number is that time in hex. The default is the time of
the last git commit.

## Smoke test

`make test` builds a second image with `tests/smoke/autoexec.bat` (made
CRLF) and `HELLO.COM` added. `HELLO.COM` is built from
`tests/hello/hello.asm` with Open Watcom `wasm` and `wlink`, independently
of the DOS tree (decision 14). It prints the DOS version that INT 21h
function 30h reports and exits with errorlevel 7.

`scripts/smoke-test` boots the image in headless `qemu-system-i386`, with
COM1 written to a file (decision 13). `AUTOEXEC.BAT` reports to `AUX`. The
test covers:

- `VER`;
- `DIR`;
- creating a file with `ECHO`, copying it with `COPY` and reading it with
  `TYPE`;
- `DEL` and `MD`;
- running `HELLO.COM` and testing its exit code with `IF ERRORLEVEL`;
- the GR-DOS banner, with the Microsoft copyright line, from a second
  `COMMAND` that reads `EXIT` from a file (the first `COMMAND` writes its
  banner to the screen, which the test does not capture).

QEMU is stopped when the line `GRDOS-TEST-END` arrives, or after 60 seconds.
Each regular expression in `tests/smoke/expect` must then match a line of
the output, in order. The output is saved in
`build/linux/tests/smoke/serial.txt`:

```text
GRDOS-TEST-BEGIN

GR-DOS Version 4.00

 Volume in drive A has no label
 Volume Serial Number is 6ADB-7673
 Directory of  A:\

COMMAND  COM     37540 10-23-26   3:00p
AUTOEXEC BAT       383 10-23-26   3:00p
HELLO    COM        58 10-23-26   3:00p
        3 File(s)    1347584 bytes free
        1 File(s) copied
hello
GRDOS-DEL-OK
GRDOS-MD-OK
GRDOS-HELLO DOS 4.00
GRDOS-ERRORLEVEL-7


GR-DOS Version 4.00
             (C)Copyright Microsoft Corp 1981-1988

A>EXIT
GRDOS-TEST-END
```

CI installs mtools and QEMU from the `ubuntu-24.04` runner's packages. It
records their versions in `BUILDINFO` and ships the image, the binaries,
`SHA256SUMS` and the logs as artifacts.

## 86Box check (decision 9)

The 8086/V20 check is a manual step in 86Box, since the machine ROMs are not
redistributable. `scripts/86box-vm` sets up a VM: it copies the image into
the VM directory and writes an `86box.cfg` for an Xi 8088 board with 640 KB,
CGA and a 3.5" 1.44 MB drive, at 4.77 MHz:

```sh
make
vm=$(scripts/86box-vm --cpu necv20 "$HOME/.local/share/86Box/Virtual Machines/gr-dos-xi8088")
86Box -R ROMDIR -P "$vm"
```

Run it again with `--cpu 8088` for the Intel 8088. Answer the date and time
prompts, then use the prompt (`VER`, `DIR`, `COPY`, `TYPE`, `MD`, `DEL`).
The Xi 8088 BIOS reports an invalid NVRAM checksum on the first boot and
loads its defaults, which is harmless.

Two things to avoid:

- **XT floppy controllers.** The IBM PC/XT boards and GLaBIOS in 86Box have
  an XT floppy controller, which cannot read a 1.44 MB disk ("Disk Boot
  Fail"), as on real hardware. The Xi 8088 has an AT-style controller.
- **An unreadable config.** If 86Box cannot use the config, for example
  because `-P` was given an unquoted path with a space in it, it starts with
  its defaults, an IBM PC with 64 KB and ROM BASIC, and saves them over
  `86box.cfg` on exit. Run `scripts/86box-vm` again after that.

### Result

2026-10-23, the image from commit `a3a1ba8`, 86Box Linux AppImage build
9001 with Xi 8088 BIOS 0.9.9:

| CPU | Result |
|---|---|
| NEC V20, 4.77 MHz | Boots to the prompt; GR-DOS banner with the Microsoft copyright line; `VER` shows `GR-DOS Version 4.00`; checked interactively. |
| Intel 8088, 4.77 MHz | The same. |
