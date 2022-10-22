#! /bin/sh

mads -o:bootcode/bootcode.bin bootcode/bootcode.s

cat dat/sd-720-atr-header.dat bootcode/bootcode.bin > bootcode.atr

dd if=atr/formatted+dupr.atr \
   of=bootcode.atr \
   oflag=append conv=notrunc status=none \
   bs=1 skip=400

