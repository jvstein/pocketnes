#ifndef __ASMCALLS_H__
#define __ASMCALLS_H__

#if !GCC
extern u32 Image$$RO$$Limit;
#endif

extern u8 *chr_rom_table[256];
extern u8 spr_cache[16];
extern u8 spr_cache_disp[16];
extern u8 spr_cache_map[256];

extern u32 *_dmabankbuffer;
extern u8 *_dmanesoambuff;
extern u16 *_dmascrollbuff;
#define dmabankbuffer _dmabankbuffer
#define dmanesoambuff _dmanesoambuff
#define dmascrollbuff _dmascrollbuff
#define nesoambuff _nesoambuff

extern u8 *_nesoambuff;


extern u8 g_ppuctrl0frame;

extern u32 g_BGmirror;
extern u8 _nes_palette[32];
#define nes_palette _nes_palette

#if GCC
static __inline void breakpoint()
{
	__asm volatile ("mov r11,r11");
}
#else
void breakpoint(void);
#endif

extern u8 g_has_vram;
extern u8 g_bankable_vrom;
extern u8 g_vram_page_mask;
extern u8 g_vram_page_base;

extern u8 ppustat_;
extern u8 ppustat_savestate;

extern u8 dirty_rows[32];
extern u8 dirty_tiles[512];
extern u8 _bg_cache_full;

extern u8 g_fourscreen;

//6502.s
void CPU_reset(void);
void ntsc_pal_reset(void);
void cpuhack_reset(void);
void run(int dont_stop);
extern void* op_table[256];
extern void default_scanlinehook(void);
extern void pcm_scanlinehook(void);
extern void CheckI(void);
extern u8 PAL60;
extern u32 cpustate[16];

extern u8** g_instant_prg_banks;
extern u8** g_instant_chr_banks;
extern u8 *rommap[4];
extern u8 *g_memmap_tbl[8];
extern u8 *_vram_map[8];
#define vram_map _vram_map
extern u8 g_bank6[5];
extern u8 g_bank8[4];
extern u8 g_Cbank0[8];
extern u8 g_nes_chr_map[8];
extern u8 g_vrompages;
extern u8 g_rompages;
extern u8 NES_VRAM[8192];
extern void* g_readmem_tbl[8];
extern void* g_writemem_tbl[8];

extern u32 frametotal;
extern u32 sleeptime;
extern u8 novblankwait;
extern u8 dontstop;

extern u32 SPEEDHACK_FIND_BPL_BUF[32],SPEEDHACK_FIND_BMI_BUF[32],SPEEDHACK_FIND_BVC_BUF[32],
           SPEEDHACK_FIND_BVS_BUF[32],SPEEDHACK_FIND_BCC_BUF[32],SPEEDHACK_FIND_BCS_BUF[32],
           SPEEDHACK_FIND_BNE_BUF[32],SPEEDHACK_FIND_BEQ_BUF[32],SPEEDHACK_FIND_JMP_BUF[32];

extern u8* g_m6502_pc;
extern u8* g_m6502_s;
extern u8* g_lastbank;

//apack.s
void depack(u8 *source, u8 *destination);

//boot.s
extern const u8 font[];				//from boot.s
extern const u8 fontpal[];				//from boot.s

//cart.s
void reset_all(void);
void loadcart_asm(void);			//from cart.s
void map67_(int page);
void map89_(int page);
void mapAB_(int page);
void mapCD_(int page);
void mapEF_(int page);
void map89AB_(int page);
void mapCDEF_(int page);
void map89ABCDEF_(int page);
void chr0_(int page);
void chr1_(int page);
void chr2_(int page);
void chr3_(int page);
void chr4_(int page);
void chr5_(int page);
void chr6_(int page);
void chr7_(int page);
void chr01_(int page);
void chr23_(int page);
void chr45_(int page);
void chr67_(int page);
void chr0123_(int page);
void chr4567_(int page);
void chr01234567_(int page);
extern void *writeCHRTBL[8];
void updateBGCHR_(void);
void updateOBJCHR(void);
void mirror1_(void);
void mirror2V_(void);
void mirror2H_(void);
void mirror4_(void);
void mirrorKonami_(void);
void chrfinish(void);

//int savestate(void*);
//void loadstate(int,void*);

extern u32 g_emuflags;
extern u8* romstart;
extern u32 romnum;
extern u8 g_scaling;
extern u8 g_cartflags;
extern u8 g_hackflags;
extern u8 g_hackflags2;
extern u8 g_hackflags3;
extern u8 g_mapper_number;
extern u8* g_rombase;
extern u8* g_vrombase;
extern u32 g_vrommask;
extern u32 g_rommask;
extern u8 g_rompages;
extern u8 g_vrompages;

//extern char lfnName[256];
//extern unsigned char globalBuffer[BYTE_PER_READ];
//extern unsigned char fatWriteBuffer[BYTE_PER_READ];
//extern unsigned char fatBuffer[BYTE_PER_READ];
//extern FAT_FILE openFiles[MAX_FILES_OPEN];

extern u8 NES_RAM[2048];
extern u8 NES_SRAM[8192];
extern u8 END_OF_EXRAM;
extern char SramName[256];
extern u8 NES_VRAM[8192];
extern u8 NES_VRAM2[2048];
extern u8 NES_VRAM4[4096];
//extern u8* cache_location[MAX_CACHE_SIZE];
extern u16 DISPCNTBUFF[240];
extern u16 DMA1BUFF[164];

extern u8 mapperstate[32];

void loadstate_gfx(void);

extern u8 AGB_BG[8192];


//cf.s
int cheat_test(u32 operator, int changeok);

//io.s
extern u32 _joycfg;				//from io.s
#define joycfg _joycfg
void resetSIO(u32);				//io.s
void vbaprint(const char *text);		//io.s
void LZ77UnCompVram(u32 *source,u16 *destination);		//io.s
void waitframe(void);			//io.s
int CheckGBAVersion(void);		//io.s
void doReset(void);			//io.s
void suspend(void);			//io.s
void waitframe(void);		//io.s
int gettime(void);			//io.s
void spriteinit(char);		//io.s

//memory.s
extern u32 sram_R[];
extern u32 sram_W[];
extern u32 rom_R60[];
extern u32 empty_W[];
#if SAVE
extern u32 sram_W2[];
#else
#define sram_W2 sram_W
#endif
/*
memory.s(7): EXPORT void
memory.s(8): EXPORT empty_R
memory.s(9): EXPORT empty_W
memory.s(10): EXPORT ram_R
memory.s(11): EXPORT ram_W
memory.s(12): EXPORT sram_R
memory.s(13): EXPORT sram_W
memory.s(14): EXPORT sram_W2
memory.s(15): EXPORT rom_R60
memory.s(16): EXPORT rom_R80
memory.s(17): EXPORT rom_RA0
memory.s(18): EXPORT rom_RC0
memory.s(19): EXPORT rom_RE0
memory.s(20): EXPORT filler_
*/

//ppu.s
extern u32 *vblankfptr;			//from ppu.s
extern u32 vbldummy;			//from ppu.s
extern u32 vblankinterrupt;		//from ppu.s
extern u32 AGBinput;			//from ppu.s
extern u32 EMUinput;

void build_chr_decode(void);
void debug_(int,int);		//ppu.s
void paletteinit(void);		//ppu.s
void PaletteTxAll(void);	//ppu.s
void Update_Palette(void);

void PPU_reset(void);
void PPU_init(void);

extern u32 FPSValue;		//from ppu.s
extern char fpsenabled;		//from ppu.s
extern char gammavalue;		//from ppu.s
extern char g_twitch;			//from ppu.s
extern char g_flicker;		//from ppu.s
extern char wtop;			//from ppu.s

extern u32 ppustate[10];
extern u16 _agb_pal[32];

//extern u32 agb_nt_map[4];

extern u8 g_frameready;
extern u8 g_firstframeready;

extern u32 g_nextx;
extern u32 g_scrollX;

/*
ppu.s(9): EXPORT PPU_init
ppu.s(10): EXPORT PPU_reset
ppu.s(11): EXPORT PPU_R
ppu.s(12): EXPORT PPU_W
ppu.s(13): EXPORT agb_nt_map
ppu.s(14): EXPORT vram_map
ppu.s(15): EXPORT _vram_write_tbl
ppu.s(16): EXPORT VRAM_chr
ppu.s(17): EXPORT VRAM_chr2
ppu.s(18): EXPORT debug_
ppu.s(19): EXPORT AGBinput
ppu.s(20): EXPORT EMUinput
ppu.s(21): EXPORT paletteinit
ppu.s(22): EXPORT PaletteTxAll
ppu.s(23): EXPORT newframe
ppu.s(24): EXPORT agb_pal
ppu.s(25): EXPORT ppustate
ppu.s(26): EXPORT writeBG
ppu.s(27): EXPORT wtop
ppu.s(28): EXPORT gammavalue
ppu.s(29): EXPORT oambuffer
ppu.s(30): EXPORT ctrl1_W
ppu.s(31): EXPORT newX
ppu.s(32): EXPORT twitch
ppu.s(33): EXPORT flicker
ppu.s(34): EXPORT fpsenabled
ppu.s(35): EXPORT FPSValue
ppu.s(36): EXPORT vbldummy
ppu.s(37): EXPORT vblankfptr
ppu.s(38): EXPORT vblankinterrupt
ppu.s(39): EXPORT NES_VRAM
*/

//sound.s
void make_freq_table(void);
extern u16* _freqtbl;
extern u16 FREQTBL2[2048];

extern u8 sound_state[116];

extern u8 PCMWAV[128];

extern u8 *_pcmstart, *_pcmcurrentaddr;


/*
sound.s(4): EXPORT timer1interrupt
sound.s(5): EXPORT Sound_reset
sound.s(6): EXPORT updatesound
sound.s(7): EXPORT make_freq_table
sound.s(8): EXPORT _4000w
sound.s(9): EXPORT _4001w
sound.s(10): EXPORT _4002w
sound.s(11): EXPORT _4003w
sound.s(12): EXPORT _4004w
sound.s(13): EXPORT _4005w
sound.s(14): EXPORT _4006w
sound.s(15): EXPORT _4007w
sound.s(16): EXPORT _4008w
sound.s(17): EXPORT _400aw
sound.s(18): EXPORT _400bw
sound.s(19): EXPORT _400cw
sound.s(20): EXPORT _400ew
sound.s(21): EXPORT _400fw
sound.s(22): EXPORT _4010w
sound.s(23): EXPORT _4011w
sound.s(24): EXPORT _4012w
sound.s(25): EXPORT _4013w
sound.s(26): EXPORT _4015w
sound.s(27): EXPORT _4015r
sound.s(28): EXPORT pcmctrl
*/

//visoly.s
void doReset(void);			//io.s

//aliases without the prefix
#define ppuctrl0frame	g_ppuctrl0frame
#define BGmirror	g_BGmirror
#define nes_palette	_nes_palette
#define agb_pal	_agb_pal
#define has_vram	g_has_vram
#define bankable_vrom	g_bankable_vrom
#define vram_page_mask	g_vram_page_mask
#define vram_page_base	g_vram_page_base
#define bg_cache_full	_bg_cache_full
#define fourscreen	g_fourscreen
#define instant_prg_banks	g_instant_prg_banks
#define instant_chr_banks	g_instant_chr_banks
#define bank6	g_bank6
#define bank8	g_bank8
#define Cbank0	g_Cbank0
#define nes_chr_map	g_nes_chr_map
#define vrompages	g_vrompages
#define rompages	g_rompages
#define readmem_tbl	g_readmem_tbl
#define writemem_tbl	g_writemem_tbl
#define m6502_pc	g_m6502_pc
#define m6502_s	g_m6502_s
#define lastbank	g_lastbank
#define emuflags	g_emuflags
#define scaling	g_scaling
#define cartflags	g_cartflags
#define hackflags	g_hackflags
#define hackflags2	g_hackflags2
#define hackflags3	g_hackflags3
#define mapper_number	g_mapper_number
#define rombase	g_rombase
#define vrombase	g_vrombase
#define vrommask	g_vrommask
#define rommask	g_rommask
#define rompages	g_rompages
#define vrompages	g_vrompages
#define joycfg	_joycfg
#define freqtbl	_freqtbl
#define frameready	g_frameready
#define firstframeready	g_firstframeready
#define memmap_tbl g_memmap_tbl
#define nextx g_nextx
#define scrollX g_scrollX
#define twitch g_twitch
#define flicker g_flicker

#define romstart rombase
#define romnumber romnum
#define mapper mapper_number


#endif