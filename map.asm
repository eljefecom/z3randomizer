; ==============================================================================
PrepMapZoom:
	LDA.b #$80 : STA $211A ; thing we wrote over
	
	LDA.b #$00 : STA !MAP_ZOOM
RTL
; ==============================================================================
ForceMapZoom:
	LDA !MAP_ZOOM : BNE .isPreset
	LDA.b #$01
	LDA.b #$01 : STA !MAP_ZOOM
RTL
	.isPreset
	LDA $F6 : AND.b #$70
RTL
; ==============================================================================