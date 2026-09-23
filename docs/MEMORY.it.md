# Memoria e piattaforma

Indirizzi esadecimali. Nessuna modifica al layout geometrico qualificato.

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

## Plus/4 nativo, TED

CPU 7501/8501 e 64 KB stock, BASIC 3.5. Runtime RAM senza KERNAL, ROM
disabilitata via $FF3F. Clock veloce TED abilitato, soggetto alle contese del
display: non 2 MHz continui. Tastiera tramite $FD30/$FF08, non CIA C64.

Matrici comuni $D800–$DBFF (luminanza/attributi), $DC00–$DFFF (tinte/UI).
$FF14=$D8, $FF13=$58 mantiene font e clock veloce; $FF12 sceglie bitmap.
00 usa $FF15=$00; 11 usa $FF16=$67; 01 usa tinta alta+lum bassa=$29;
10 usa tinta bassa+lum alta=$48. Quattro colori fissi, non la prova a nove.
Entrambi i buffer condividono questi attributi inizializzati una volta.

Il blocco $FD00–$FEFF e i registri $FF00–$FF1F non sono RAM bitmap
scrivibile. Init li salta. Lo split basso rilegge dalla bitmap bassa sempre
azzerata, dopo la riga attiva finale. Scritture $FF12 alla riga 187,
cicli master 97–105; l'ingresso alla STA può precedere lo stall TED.
Testo righe carattere 0–2, margine nero 3–4, viewport 5–22, margine 23–24.
PAL/NTSC rilevato da TED, split preservato per entrambi.

Helper nativo 1.611 byte, 838 liberi nel suo slot. PRG 54.784 byte inclusi
loader e gap. Nessuna espansione RAM, non supportato C16 da 16 KB.

## Contratti comuni

UI tre righe, ultimo blocco 24 byte di ogni screen/matrice protetto da guardie.
Niente sprite o modifica dei loro puntatori. Nessun output generato nell'SDK.
Le label/listing di ogni build sono la mappa autorevole; non considerare ogni
buco della tabella libero. Modifiche al layout richiedono nuovi test.
