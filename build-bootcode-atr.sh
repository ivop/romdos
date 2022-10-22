#! /bin/sh

OUTPUT=romdos-bootcode-dupr.atr

mads -o:bootcode/bootcode.bin bootcode/bootcode.s

cat dat/sd-720-atr-header.dat bootcode/bootcode.bin > "$OUTPUT"

dd if=atr/formatted+dupr.atr \
   of="$OUTPUT" \
   oflag=append conv=notrunc status=none \
   bs=1 skip=400

diff -s atr/formatted+dupr.atr "$OUTPUT"
