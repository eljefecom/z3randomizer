;=================================================================================
; SRAM enforcement functions (to make sure save files are only used on the
; ROM seed that created them)
;=================================================================================
!SRAM_HASH_ADDR = $7004E8 ; chosen to be at the upper end of the SRAM just below
			  ; the randomizer file marker
;---------------------------------------------------------------------------------
InitSramDeletedFlag:
	SEP #$30 ; go into 8bit mode
	JSR NameHashWrapper ; I need to call NameHash this early to get the hash
	REP #$30 ; an instruction we wrote over
	LDA.w #$0000 : STA $7F5026 ;$7F5026 is scratch space, this is a marker that the sram file-delete routine has not run
	STZ $00  ; an instruction we wrote over
RTL
;---------------------------------------------------------------------------------
SetSramDeletedFlag:
	; don't mess with X !
	; assumes 16bit Accumulator and Index registers
	LDA $7F5026 : BNE +
		LDA.w #$0001 : STA $7F5026 ;$7F5026 is scratch space, this is a marker that the sram file-delete routine has run
		SEP #$20 ; go in 8bit accumulator mode
		LDA.b #$3C : STA $012E ; play buzzer sound
		REP #$20 ; go in 16bit accumulator mode
	+ ; skip because sound already played
	LDY.w #$0000 : TYA ; instructions we wrote over
RTL
;---------------------------------------------------------------------------------
SkipOverwriteEmptySramFile:
	;assumes 16bit Accumulator and Index registers
	;the original SRAM validation code will overwrite an empty save file
	;(which is already all zeros) with all zeros, this seems inefficient.
	;this will mark an empty file as having a valid checksum and skip that step
	-
	!ADD $700000, X
	INX #2
	INY : CPY.w #$0280 : BNE -
	;accumulator now has the checksum
	CMP.w #$0000 : BNE +
		;if it was zero, it's not valid, but probably empty, don't automatically overwrite
		TXA : !SUB #$0500 : TAX ; correct X by subtracting 0x500
		LDA.w #$0000 : STA $7003E1, X ; mark file empty if it wasn't already
		LDA.w #$5A5A ; lie to the calling routine that the checksum was valid
	+
RTL
;---------------------------------------------------------------------------------
WriteRomHashToSram:
	;assumes 16bit Accumulator and Index registers
	;assumes X has the save file offset, don't mess with X !
	;the ROM hash was previously stored in scratch space at $7F5028-$7F502F        
	LDA $7F5028 : STA !SRAM_HASH_ADDR, X
	LDA $7F502A : STA !SRAM_HASH_ADDR+2, X
	LDA $7F502C : STA !SRAM_HASH_ADDR+4, X
	LDA $7F502E : STA !SRAM_HASH_ADDR+6, X

	LDA.w #$001D : STA $02 ;instructions we wrote over
RTL
;---------------------------------------------------------------------------------
CompareRomHashToSram:
	;assumes 16bit Accumulator and Index registers
	;assumes X has the save file offset, don't mess with X !
	;the ROM hash was previously stored in scratch space at $7F5028-$7F502F        
	LDA !SRAM_HASH_ADDR, X : CMP $7F5028 : BNE +
	LDA !SRAM_HASH_ADDR+2, X : CMP $7F502A : BNE +
	LDA !SRAM_HASH_ADDR+4, X : CMP $7F502C : BNE +
	LDA !SRAM_HASH_ADDR+6, X : CMP $7F502E : BNE +
	BRA ++
	+ ; sram/rom mismatch
	LDA.w #$0000 : STA $7003E1, X : STA $7012E1, X ; corrupt the valid file marker and the backup
	; the automatic deletion routine will delete it now
	++ ; sram/rom match
	LDY.w #$0000 : TYA ;instructions we wrote over
RTL
;---------------------------------------------------------------------------------
NameHashWrapper:
	;save $00 thru $07
	LDA $00 : PHA
	LDA $01 : PHA
	LDA $02 : PHA
	LDA $03 : PHA
	LDA $04 : PHA
	LDA $05 : PHA
	LDA $06 : PHA
	LDA $07 : PHA
	JSL.l NameHash ; make the ROM hash
	;restore $00 thru $07
	PLA : STA $07
	PLA : STA $06
	PLA : STA $05
	PLA : STA $04
	PLA : STA $03
	PLA : STA $02
	PLA : STA $01
	PLA : STA $00
RTS