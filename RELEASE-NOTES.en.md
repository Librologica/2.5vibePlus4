# 2.5vibePlus4 1.0.0 — release notes

First standalone native mono-portals distribution. Original/new demo 2,
auto/interactive, PRGs and complete sources. Previous baselines preserved;
no new renderer optimization during packaging.

## Measured results

| Map | Run | Standard | FPS | Images / 20 s |
|---|---|---|---:|---:|
| original | auto | PAL | 6.00 | 120 |
| original | auto | NTSC | 5.70 | 114 |
| original | interactive | PAL | 4.50 | 90 |
| original | interactive | NTSC | 4.30 | 86 |
| optimized | auto | PAL | 6.85 | 137 |
| optimized | auto | NTSC | 5.95 | 119 |
| optimized | interactive | PAL | 4.15 | 83 |
| optimized | interactive | NTSC | 4.00 | 80 |

Stock VICE, initial 20-emulated-second window after 2-second warm-up.
Interactive is stationary at start, not a benchmarked manual tour. Values
belong to this package, not recycled prototype figures. 960 native views
compared per SDK: zero bitmap differences against the pose model. Source
and deterministic rebuilds verified. Sampled qualification does not cover
every possible trajectory. Real hardware has not been tested.

Ready for a GitHub repository, not uploaded. Geometry deliberately follows
the MAPS contracts. Complete demo ASM is included as requested; no dumps,
profilers, screenshots, temporary directories or historical experiments.
