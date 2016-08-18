	IMPORT scroll_threshhold_mod
	IMPORT findsprite0

;	IMPORT nesoambuff

	IMPORT nes_chr_update
	IMPORT newframe_nes_vblank
	IMPORT PPU_init
	IMPORT PPU_reset
	IMPORT PPU_R
	IMPORT PPU_W
	IMPORT dma_W
;	IMPORT agb_nt_map
	IMPORT VRAM_name0
	IMPORT VRAM_name1
	IMPORT VRAM_name2
	IMPORT VRAM_name3

	IMPORT VRAM_chr
	[ MIXED_VRAM_VROM
	IMPORT VRAM_chr3
	]
;	IMPORT vram_map
;	IMPORT vram_write_tbl
	IMPORT vram_write_direct
	IMPORT vram_read_direct
	IMPORT debug_
	IMPORT map_palette
	IMPORT newframe
;	IMPORT agb_pal
	IMPORT ppustat_
	IMPORT ppustate
	IMPORT writeBG
	IMPORT newX
	IMPORT newY
	IMPORT newframe_set0
	IMPORT ctrl0_W
	IMPORT ctrl1_W
;	IMPORT scrollbuff
;	IMPORT dmascrollbuff
;	IMPORT bg0cntbuff

	IMPORT stat_R_ppuhack
	IMPORT stat_R
	IMPORT PPU_read_tbl
	
;	IMPORT g_PAL60

	IMPORT update_Y_hit
	IMPORT stat_R_simple
	IMPORT stat_R_clearvbl
	IMPORT stat_R_sameline

	END
