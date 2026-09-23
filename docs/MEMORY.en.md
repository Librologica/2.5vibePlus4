# Memory and platform

Hexadecimal addresses. Qualified geometry layout preserved.

| Range | Allocation |
|---|---|
| 0000–0001 | CPU I/O port |
| 0002–00EC | Renderer, navigation, IRQ state/scratch |
| 0100–01FF | CPU stack |
| 0200–07FF | Lookup RAM after temporary loader completes |
| 0801–2E73 auto / 0801–2C71 interactive | Low program; 140 / 654 bytes before 2F00 |
| 2F00–3BFF | Ray, edge, refinement and projection workspace |
| 3C00–3FFF | 32×32 solid map |
| 4400–57FF | Geometry/lookups/fill masks/navigation data |
| 5800–5FFF | 2 KB explicit-pattern UI font |
| 6000–7FFF | Low bitmap window; prefix also contains navigation data |
| 6660–7C9F | Active low viewport: 4,608 bytes |
| 8000–AFFF | Renderer tables/data |
| B000–B990 | Native init/helpers + specialized ceiling fill |
| B991–C3FF | Inherited geometry tables/data |
| C480–C536 | Cold bitmap clear helper |
| C600–CBFF | Projection/door tables, copy helper and owners |
| E660–FC9F | Active high viewport: 4,608 bytes |
| FFFA–FFFF | Private vectors |

## Native Plus/4, TED

7501/8501 CPU and stock 64 KB, BASIC 3.5. RAM-only runtime without KERNAL,
ROM disabled through $FF3F. TED fast clock enabled but display-contended,
not continuous 2 MHz. Keyboard uses $FD30/$FF08, not C64 CIA.

Shared matrices $D800–$DBFF (luminance/attributes), $DC00–$DFFF (hues/UI).
$FF14=$D8; $FF13=$58 preserves font/fast clock; $FF12 selects bitmap.
00 uses $FF15=$00; 11 uses $FF16=$67; 01 uses upper hue/lower luminance=$29;
10 uses lower hue/upper luminance=$48. Four fixed colors, not the nine-color
experiment. Both buffers share these once-initialized attributes.

$FD00–$FEFF and $FF00–$FF1F are not writable bitmap RAM. Init skips them.
The bottom split fetches the always-cleared low bitmap margin after the last
active row. $FF12 writes occur on line 187, master cycles 97–105; STA entry
can precede a TED stall. Text character rows 0–2, black gap 3–4, viewport
5–22, bottom margin 23–24. TED detects PAL/NTSC; both splits are preserved.

Native helper 1,611 bytes, 838 free in its slot. PRG 54,784 bytes including
loader/gaps. No RAM expansion; 16-KB C16 is not supported.

## Shared contracts

Three-row UI; final 24 bytes of each screen/matrix protected by guards.
No sprites or sprite-pointer modification. No generated output in SDK.
Each build's labels/listing are authoritative; not every table gap is free
space. Layout changes require new qualification.
