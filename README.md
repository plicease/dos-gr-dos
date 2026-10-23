# GR-DOS

GR-DOS is a fork of the MS-DOS 4.00 source that Microsoft published under
the MIT license. It is built on Linux with open tools, booted in QEMU, and
tested in GitHub Actions.

Today the build produces the boot sector, IO.SYS, MSDOS.SYS and COMMAND.COM,
and a bootable 1.44 MB floppy image. Apart from the GR-DOS branding of the
banner and `VER` (`patches/branding`), the binaries are byte-identical to
the original MASM/LINK build. See
[`docs/00-mvp.md`](docs/00-mvp.md) for the plan and its status.

## Building

You need:

- Perl 5.42 as `perl` on `PATH`;
- a C compiler, make, git, curl and xz;
- mtools and `qemu-system-i386`.

```sh
make          # build into build/linux, fetching JWasm and Open Watcom into build/tools
make check    # build without the branding and compare with the MS-DOS 4.00 reference build
make test     # boot the image in QEMU and check a scripted session
make dist     # collect the image, binaries and checksums in build/linux/dist
```

The image is `build/linux/gr-dos.img`. To boot it:

```sh
qemu-system-i386 -drive file=build/linux/gr-dos.img,if=floppy,format=raw -boot a
```

Releases are created from `VERSION` by CI and include the image.

## Documentation

- [`docs/00-mvp.md`](docs/00-mvp.md): goals, decisions, milestones.
- [`docs/provenance.md`](docs/provenance.md): the source, restorations and
  licenses.
- [`docs/m1-reference-build.md`](docs/m1-reference-build.md): the original
  build run under DOSBox-X, used as the reference.
- [`docs/m2-jwasm.md`](docs/m2-jwasm.md): the Linux build with JWasm and
  `wlink`.
- [`docs/m3-boot.md`](docs/m3-boot.md): the boot image and smoke test, and the
  86Box check on an 8088 and a V20.

## License

GR-DOS's own scripts, patches and documentation are MIT, see
[`LICENSE`](LICENSE). The MS-DOS 4.00 source in `v4.0` keeps its own MIT
license, [`v4.0/LICENSE`](v4.0/LICENSE). MS-DOS is a trademark of
Microsoft. GR-DOS is an independent project, not endorsed by Microsoft or
IBM.
