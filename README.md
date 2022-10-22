Archive of Atari 8-bit ROMDOS/RDOS related ROMs and boot disks, including disassembly and other experiments.

---

### TL;DR

Run with atari800 emulator:

``atari800 -nopatch -nopatchall -xl -xlxe_rom romdos-xl-osb.rom -xl-rev custom -cart roms/basicrevc.bin -cart-type 1 atr/romdos.atr``

Or with ``atr/formatted+dupr.atr``, ``romdos-bootcode-dupr.atr`` or ``romdos-singlesector-dupr.atr``

---

### Longer read

__atr/__
  contains the "original" romdos atr and images formatted by it plus helper files

__bootcode/__
  disassembled and annotated boot code, and newly written experimental single sector boot sector

__dat/__
  contains data files, for example the SD 720 sectors ATR header

__roms/__
  ROM dumps, including the 4kB RDOS V0.1 ROM

__/__
  scripts to generate a new ROM, and ATR images with the original boot code and the experimental boot code
