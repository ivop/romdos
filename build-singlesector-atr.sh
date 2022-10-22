#! /bin/sh

mads -o:bootcode/singlesector.bin bootcode/singlesector.s

cat dat/sd-720-atr-header.dat bootcode/singlesector.bin > singlesector.atr

dd if=/dev/zero \
   of=singlesector.atr \
   oflag=append conv=notrunc status=none \
   bs=1 count=256

dd if=atr/formatted+dupr.atr \
   of=singlesector.atr \
   oflag=append conv=notrunc status=none \
   bs=1 skip=400

