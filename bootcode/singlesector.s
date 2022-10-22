
; ----------------------------------------------------------------------------

; Single sector boot code for RDOS/ROMDOS v0.1
; October 2022 by Ivo van Poorten

; ----------------------------------------------------------------------------

    opt h-          ; no XEX header

    org $0700

; ----------------------------------------------------------------------------

DOSINI      = $0C
SAVMSC      = $58
ROMDOSROM   = $C000

; ----------------------------------------------------------------------------

; BOOT SECTOR starts here

BFLAG
boot_flag
    dta $00         ; unused

BRCNT
boot_record_count
    dta 1         ; 1 boot sector

BLDADR
boot_loader_address
    dta a($0700)    ; where the bootcode is loaded

BIWTARR
boot_initialization_address
    dta a(ROMDOSROM + $0CB0)        ; somewhere in ROM :)

XBCONT
boot_jmp_boot_continuation_vector
    jmp boot_continuation

; variables for RDOS/MyDOS

    dta $03,$DF,$01,$04,$0B

density
   dta $01      ; $01 = SD, $02 = DD

buffer_index
    dta $FD      ; $fd for DD disks, $7d for SD disks

; drives info
    dta $01,$00,$00,$00,$00,$00,$00,$00
    dta $52,$D2,$D2,$D2,$D2,$D2,$D2,$D2

    dta $4C,$06,$08             ; looks like jmp but unused
    dta $00,$00,$00,$00

command_mirror
    dta 'W'                 ; write

; ----------------------------------------------------------------------------

boot_continuation
    ldx #7

compare_ram_to_part_of_rom
    lda ROMDOSROM,x
    cmp compare,x
    bne no_romdos

    dex
    bne compare_ram_to_part_of_rom

; ROMDOS ROM is present

    lda #<$CCB0
    ldy #>$CCB0
    sta DOSINI
    sty DOSINI+1
    clc
    rts

; --------------------------------

; No ROMDOS present

no_romdos
    ldy #textlen-1

show
    lda text,y
    sta (SAVMSC),y
    dey
    bpl show

    jmp *


; first eight bytes of ROMDOS v0.1 ROM
compare
    dta $4C, $8C, $C0, $4C, $2D, $C0, $44, $4F

text
    .sb "NO ROMDOS ROM FOUND!"
textlen = * - text

    .align $0780, 0
