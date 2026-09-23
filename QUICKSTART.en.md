# Quickstart — 2.5vibePlus4

Extract the ZIP. No other 3Dvibe64 checkout is required. To play, use the
four demos/ PRGs without building. Select xplus4, Commodore Plus/4 / TED, stock machine
and PAL/NTSC video standard.

Plus/4: 64 KB, not a 16-KB C16. BASIC 3.5 PRG at $1001, SYS 4109.

Hardware: load as BASIC at its native address, then RUN. For example
`LOAD"name",8` with a compatible device; check your loader procedure. Do not
force the C64 $0801 address. Hardware operation is not yet qualified.

```sh
python -B build.py --scene examples/demo2-original.json --validate-only
python -B build.py --scene examples/demo2-original.json --run auto --out ../2.5vibePlus4-original-auto
python -B build.py --scene examples/demo2-original.json --run interactive --out ../2.5vibePlus4-original-interactive
python -B build.py --scene examples/demo2-optimized.json --run auto --out ../2.5vibePlus4-optimized-auto
python -B build.py --scene examples/demo2-optimized.json --run interactive --out ../2.5vibePlus4-optimized-interactive
```

Output directories must be new and outside SDK. Build emits PRG, ASM,
labels, listing, log and scene; intermediates stay in output. Validation-only
requires no assembler and writes nothing. No GraphicsMode, FOV, palette,
viewport or camera-override options are exposed.
