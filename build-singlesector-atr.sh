#! /bin/sh

OUTPUT=romdos-singlesector-dupr.atr

mads -o:bootcode/singlesector.bin bootcode/singlesector.s

cat dat/sd-720-atr-header.dat bootcode/singlesector.bin > "$OUTPUT"

dd if=/dev/zero \
   of="$OUTPUT" \
   oflag=append conv=notrunc status=none \
   bs=1 count=256

dd if=atr/formatted+dupr.atr \
   of="$OUTPUT" \
   oflag=append conv=notrunc status=none \
   bs=1 skip=400

