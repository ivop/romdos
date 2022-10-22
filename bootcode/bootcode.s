
; ----------------------------------------------------------------------------

; Dissassembly of RDOS/ROMDOS boot code (first three sectors)
; October 2022 by Ivo van Poorten
; Tools used: atari800, frida, dis6502, vim and mads

; ----------------------------------------------------------------------------

    opt h-          ; no XEX header

    org $0700

; ----------------------------------------------------------------------------

DIRSECTOR   = $0169         ; 361

; ----------------------------------------------------------------------------

; OS Equates

DOSINI  = $0C
ICAX5Z  = $2E

FMZSPG  = $43

ZBUFP   = FMZSPG
ZDRVA   = FMZSPG + 2

DDEVIC  = $0300
DCOMND  = $0302
DSTATS  = $0303
DBUFLO  = $0304
DBUFHI  = $0305
DTIMLO  = $0306
DBYTLO  = $0308
DBYTHI  = $0309
DAUX1   = $030A
DAUX2   = $030B
SIOV    = $E459

; ----------------------------------------------------------------------------

; Other Equates

CARTLEFT    = $A000
ROMDOSROM   = $C000
CARTIO      = $D500

; ----------------------------------------------------------------------------

; BOOT SECTOR starts here

BFLAG
boot_flag
    dta $00         ; unused

BRCNT
boot_record_count
    dta $03         ; 3 boot sectors

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
    dta $7d      ; $fd for DD disks, $7d for SD disks

; drives info
    dta $01,$00,$00,$00,$00,$00,$00,$00
    dta $52,$52,$D2,$D2,$D2,$D2,$D2,$D2

;    dta $4C,$06,$08
    jmp do_sio_without_setting_daux         ; coincidence?

    dta $00,$00,$00,$00

command_mirror
    dta 'W'                 ; write

filename
    dta 'DOS     SYS'

; ----------------------------------------------------------------------------

boot_continuation
    ldx #$21

compare_ram_to_part_of_rom
    lda ROMDOSROM+$10,X
    cmp advance_zbufp_and_dbuf-1,X
    bne ram_is_not_equal

    dex
    bne compare_ram_to_part_of_rom

; ROMDOS ROM is present

    lda #$B0
    ldy #$CC
    jmp store_dosini_and_return

; --------------------------------

; No ROMDOS present

ram_is_not_equal

    jsr some_supercart_stuff    ; check if supercart banking works

    cpy #$08
    bcs going_to_skip_modify

    tya

    jsr some_supercart_stuff

    cpy #$08
    beq modify_code             ; only if Y is 8, whatever that means ;)

going_to_skip_modify
    lda #>BUFFER                ; (a,y) = $0874     low mem buffer
    ldy #<BUFFER

    ldx #' '                    ; normal DOS.SYS
    bne skip_modify             ; branch always

modify_code
    sta store_a_to_cartio+1     ; LSB of store to CARTIO + what is stored here

    lda #>(CARTLEFT + $0400)    ; (a,y) = $a400     buffer under supercart
    ldy #<(CARTLEFT + $0400)

    ldx #'C'        ; load DOSC.SYS version to be hidden underneath the cart

skip_modify
    stx filename+3

    jsr set_zbufp_and_dbuf              ; set both pointers

    ldy #<DIRSECTOR
    bne load_sector           ; branch always

; --------------------------------

next_dir_entry
    tya
    sbc #$10            ; subtract one directory line (16 bytes)
    ora #$0f            ; always start comparing from the end of the dirline
    tay
    bpl continue_comparing      ; not went "under zero" so continue

    ldy ZDRVA           ; remembered LSB of sector
    iny                 ; next one
    cpy #<DIRSECTOR+8
    bcs error_out       ; stop at 369, 368 was last directory sector

; --------------------------------

load_sector
    sty ZDRVA           ; remember LSB of sector
    clc
    ldx density
    lda #>DIRSECTOR

    jsr do_sio_with_daux_ay

    bmi error_out

; --------------------------------

; start comparing from last entry backwards through the directory

    ldy #$7f            ; end of buffer

continue_comparing
    ldx #$0b            ; 11 bytes (compare is done with bne keep_comparing)

; compare filename

keep_comparing
    lda (ZBUFP),Y
    cmp filename-1,X
    bne next_dir_entry

    dey
    dex
    bne keep_comparing

; found!

    lda (ZBUFP),Y
    tax                     ; save MSB of first sector

    dey
    lda (ZBUFP),Y
    sta FMZSPG+5            ; save LSB of first sector

    dey
    dey
    dey
    lda (ZBUFP),Y           ; flags
    and #$81                ; DELETED | CREATED_BY_DOS2
    bne next_dir_entry      ; if one of them is true

    txa                     ; MSB of first sector in A

    ldy FMZSPG+5            ; LSB of first sector in Y

read_next_sector
    clc
    ldx density
    beq error_out

    jsr do_sio_with_daux_ay

    bmi error_out

; process sector link for next sector or end

    ldy buffer_index
    lda (ZBUFP),Y
    and #$03                ; upper two bits of next sector
    pha                     ; save MSB

    iny
    ora (ZBUFP),Y           ; logical OR with lower eight bits
    beq we_are_done         ; if all zero, we are done

    lda (ZBUFP),Y           ; otherwise, load lower eigth bits
    pha                     ; save LSB

    jsr advance_zbufp_and_dbuf       ; where we load stuff

    pla                     ; restore LSB in Y
    tay

    pla                     ; restore MSB in A
    bcc read_next_sector

error_out
    sec
    rts

; -----------

we_are_done
    pla                         ; one stray byte on the stack

    lda #<($17B0)               ; DOSINI in DOS.SYS loaded from disk
    ldy #>($17B0)               ;

    ldx ZBUFP
    bpl store_dosini_and_return

    lda #<($B440)               ; DOSINI under supercart
    ldy #>($B440)

store_dosini_and_return
    sta DOSINI                  ; store 'em!
    sty DOSINI+1
    clc
    rts

; ----------------------------------------------------------------------------

    nop
    nop

; ----------------------------------------------------------------------------

; This is the code that is checked against the ROM to see if it is present.

    .proc advance_zbufp_and_dbuf

    clc
    lda ZBUFP
    adc buffer_index
    tay                                 ; calculate new Y
    lda ZBUFP+1
    adc #0                              ; and new A

    .endp                               ; fall through!!

; ------------------------------------

    .proc set_zbufp_and_dbuf            ; set by Y and A

    sty ZBUFP
    sta ZBUFP+1

    sty DBUFLO
    sta DBUFHI

    rts

    .endp

; ------------------------------------

    .proc do_sio_with_daux_ay

    sta DAUX2       ; MSB
    sty DAUX1       ; LSB

    .endp

    .proc do_sio_without_setting_daux

    ldy #10                 ; retry circa 10 seconds
    lda #'R'                ; Read
    bcc do_not_load_mirror

    lda command_mirror      ; Default to Write

do_not_load_mirror
    sta DCOMND
    sty DTIMLO

; -----

; determine amount of bytes that will be transfered?

    lda #$80
    clc
    dex
    beq store_DBYT          ; single density

    ldx DAUX2
    bne _double_density

    ldx DAUX1
    cpx #$04
    bcc store_DBYT          ; first three sectors are 128 bytes

_double_density
    asl

store_DBYT
    sta DBYTLO              ; clever trick to get either $0080 or $0100
    rol                     ; SD carry is clear, DD carry is set
    sta DBYTHI

; -----

    ldy #$31            ; Disk drive D1:        $30+num
    sty DDEVIC

    ldy #$03            ; Number of retries
    sty FMZSPG+5        ; Temporary variable

retry
    ldx #$40            ; DSTATS for read and format

    lda DCOMND
    cmp #'R'            ; Read
    beq stats_and_call_sio

    cmp #'!'            ; Format!
    beq stats_and_call_sio

    ldx #$80            ; DSTATS for the rest

stats_and_call_sio
    stx DSTATS

    jsr SIOV            ; Call SIO

    bpl sio_done        ; Succes

    dec FMZSPG+5        ; The temp retry variable
    bne retry

sio_done
    ldx ICAX5Z
    lda DSTATS
    rts

    .endp

; ----------------------------------------------------------------------------

    .proc some_supercart_stuff

    ldy CARTLEFT+$0fff
    inc CARTLEFT+$0fff
    cpy CARTLEFT+$0fff
    beq L0869

    sty CARTLEFT+$0fff
    ldy #$08

L0869
    sty CARTIO+8
    sty store_a_to_cartio+1         ; Note: self modifying code here!
    rts

    .endp

; ----------------------------------------------------------------------------

    .proc store_a_to_cartio

    sta CARTIO                  ; modified by SMC
    rts

    .endp

; ----------------------------------------------------------------------------

BUFFER
    dta $00,$00,$00,$00
    dta $00,$00,$00,$00
    dta $00,$00,$00,$00

