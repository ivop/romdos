#! /bin/sh

OUTPUT=romdos-xl-osb.rom

# Start with ROMDOS ROM     (4kB)

cat roms/rdos_v0-1_crc-5c72e.bin > "$OUTPUT"

# Append zeroes where selftest would live       (2kB)

dd if=/dev/zero \
   of="$OUTPUT" \
   oflag=append conv=notrunc status=none \
   bs=1 count=2048

# Append Rev. B OS      (10kB)

cat roms/revbntsc.rom >> "$OUTPUT"

