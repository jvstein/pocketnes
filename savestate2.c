#include "includes.h"

#if SAVE || MOVIEPLAYER

#include "gba.h"
#include <string.h>

#if !MOVIEPLAYER
typedef u8 *save_ptr;
typedef const u8 *load_ptr;
#define read_u32(src,var) ((src<limit)?((var)=*((u32*)(src)),(src)+=4,4):(0))
#define read_mem_block(dest,src,size) (memcpy((dest),(src),(size)),(src)+=(size),size)
#define seek_ahead(src,size) ((src)+=(size))
#define write_u32(dest,var) (*((u32*)(dest))=(var),(dest)+=4,4)
#define write_mem_block(dest,src,size) (memcpy((dest),(src),(size)),(dest)+=(size),size)
#else
typedef File save_ptr;
typedef File load_ptr;
#define read_u32(src,var) FAT_fread(&(var),1,4,(src))
#define read_mem_block(dest,src,size) FAT_fread ((dest),1,(size),(src))
#define seek_ahead(src,size) (FAT_fseek((src),(size),SEEK_CUR))
#define write_u32(dest,var) FAT_fwrite(&(var),1,4,(dest))
#define write_mem_block(dest,src,size) FAT_fwrite ((src),1,(size),(dest))
#endif

typedef enum
{
	SAVE_NORMAL=0,
	SAVE_DEREF,
	SAVE_WRITEONLY,
	SAVE_PPUSTATE,
	SAVE_VRAM1,
	SAVE_VRAM4,
	SAVE_INVALID
} Savefunc_t;

typedef int (*savefunc)(save_ptr*,const u8*,int,u32);
typedef int (*loadfunc)(u8*,load_ptr*,int,int);

static int save_normal(save_ptr *dest, const u8* src, int size, u32 tag);
static int save_deref(save_ptr *dest, const u8* src, int size, u32 tag);
static int save_vram1(save_ptr *dest, const u8* src, int size, u32 tag);
static int save_vram4(save_ptr *dest, const u8* src, int size, u32 tag);
static int save_invalid(save_ptr *dest, const u8* src, int size, u32 tag);

static int load_normal(u8* dest, load_ptr *src, int actualsize, int expectedsize);
static int load_deref(u8* dest, load_ptr *src, int actualsize, int expectedsize);
static int load_writeonly(u8* dest, load_ptr *src, int actualsize, int expectedsize);
static int load_ppustate(u8* dest, load_ptr *src, int actualsize, int expectedsize);
static int load_vram1(u8* dest, load_ptr *src, int actualsize, int expectedsize);
static int load_vram4(u8* dest, load_ptr *src, int actualsize, int expectedsize);
static int load_invalid(u8* dest, load_ptr *src, int actualsize, int expectedsize);

extern const char saveversion[];
extern const savefunc save_functions[];
extern const loadfunc load_functions[];
extern const char save_function_numbers[];
extern const u32 tags[];
extern void *const addresses[];
extern const int sizes[];
static int dumpdata(save_ptr *dest, int tagid);
static int tag_search(u32 lookfor, const u32 array[], int arrsize);
static int loadblock(load_ptr *src, u32 tag, int size);
static void load_old_savestate(load_ptr *src);

#if !MOVIEPLAYER
void loadstate(int romnumber, u8* src, int statesize);
int savestate(u8 *dest);
#else
bool loadstate(const char *filename);
bool savestate(const char *filename);
#endif

static void prepare_variables_for_savestate(void);
static void restore_variables_for_loadstate(void);
static void restore_more_variables_for_loadstate(void);

//declarations end...code starts

const char saveversion[]="PocketNES " VERSION_NUMBER " savestate";
#define VERSION_TAG 0

//#define VRAM1_TAG 5
//#define VRAM2_TAG 6
//#define VRAM4_TAG 7
//#define NUM_TAGS 13

const savefunc save_functions[]=
{
	save_normal,
	save_deref,
	save_normal,
	save_normal,
	save_vram1,
	save_vram4,
	save_invalid
};
const loadfunc load_functions[]=
{
	load_normal,
	load_deref,
	load_writeonly,
	load_ppustate,
	load_vram1,
	load_vram4,
	load_invalid
};

const char save_function_numbers[]=
{
	SAVE_WRITEONLY,
	SAVE_NORMAL,
	SAVE_PPUSTATE,
	SAVE_NORMAL,
	SAVE_NORMAL,
	SAVE_VRAM1,
	SAVE_NORMAL,
	SAVE_VRAM4,
	SAVE_NORMAL,
	SAVE_NORMAL,
	SAVE_NORMAL,
	SAVE_DEREF,
	SAVE_NORMAL,
	SAVE_INVALID
};

extern const u32 tags[];
/*
defined in cart.s
	DCB "VERS"
	DCB "CPUS"
	DCB "GFXS"
	DCB "RAM "
	DCB "SRAM"
	DCB "VRM1"
	DCB "VRM2"
	DCB "VRM4"
	DCB "MAPR"
	DCB "PAL2"
	DCB "MIR2"
	DCB "OAM "
	DCB "SND0"
*/

void *const addresses[]=
{
	(void*)saveversion,
	(void*)cpustate,
	(void*)ppustate,
	(void*)NES_RAM,
	(void*)NES_SRAM,
	(void*)NES_VRAM,
	(void*)NES_VRAM2,
	(void*)NES_VRAM4,
	(void*)mapperstate,
	(void*)nes_palette,
	(void*)&BGmirror,
	(void*)&_nesoambuff,
	(void*)sound_state,
	(void*)NULL
};

#define NUM_TAGS ARRSIZE(addresses)-1

const int sizes[]=
{
	 ((sizeof(saveversion)-2) | 3)+1 ,	//saveversion
	32,		//cpustate
	40,		//ppustate
	2048,	//NES_RAM
	8192,	//NES_SRAM
	8192,	//NES_VRAM
	2048,	//NES_VRAM2
	2048,	//NES_VRAM4
	48,		//mapperstate
	32,		//nes_palette
	4,		//&BGmirror
	256,	//&_nesoambuff
	sizeof(sound_state),
	-1		//invalid
};

int dumpdata(save_ptr *dest, int tagid)
{
	u32 tag;
	int size;
	int retsize;
	const u8 *address;
	Savefunc_t function_number;
	savefunc save_function;
	
	function_number=save_function_numbers[tagid];
	save_function=save_functions[function_number];
	
	tag=tags[tagid];
	size=sizes[tagid];
	address=(const u8*)addresses[tagid];
	
	retsize=save_function(dest,address,size,tag);
	
	if (retsize>=0)
	{
		//add the headers to the returned size
		retsize+=8;
	}
	//no tag written if returned size is negative
	if (retsize<0) retsize=0;
	return retsize;
}

int tag_search(u32 lookfor, const u32 array[], int arrsize)
{
	int i;
	for (i=0;i<arrsize;i++)
	{
		if (array[i]==lookfor) return i;
	}
	return arrsize;
}

int loadblock(load_ptr *src, u32 tag, int size)
{
	int tagid;
	int expectedsize;
	u8 *address;
	int returnsize;
	Savefunc_t function_number;
	loadfunc load_function;

	tagid=tag_search(tag,tags,NUM_TAGS);
	
	expectedsize=sizes[tagid];
	address=(u8*)addresses[tagid];
	
	function_number=save_function_numbers[tagid];
	load_function=load_functions[function_number];
	
	returnsize=load_function(address,src,size,expectedsize);
	return returnsize;
}

void load_old_savestate(load_ptr *src)
{
	read_mem_block(&emuflags,*src,8); //emuflags, scaling settings, bg mirror
	read_mem_block(NES_RAM,*src,0x800);
	read_mem_block(NES_SRAM,*src,0x2000);
	if (has_vram)	{
		read_mem_block(NES_VRAM,*src,0x2000);
	} else {
		seek_ahead(*src,0x2000);
	}
	read_mem_block(NES_VRAM2,*src,0x800);
	if (fourscreen) {
		read_mem_block(NES_VRAM4,*src,0x800);
	} else {
		seek_ahead(*src,0x800);
	}
	seek_ahead(*src,64); //AGB palette
	read_mem_block(nes_palette,*src,32);
	
	
	//convert vram_map to nes_chr_map
	seek_ahead(*src,64);  //vram_map is unreadable
	seek_ahead(*src,16); //agb_nt_map, no longer used
	read_mem_block(mapperstate,*src,32);
	read_mem_block(nes_chr_map,*src,8);
	seek_ahead(*src,8); //skip duplicate of nes_chr_map
	read_mem_block(rommap,*src,16);
	{
		int i;
		for (i=0;i<4;i++)
		{
			bank8[i]=((int)rommap[i]+0x8000+8192*i)/8192;
		}
	}
	{
		u32 old_readmem;
		old_readmem = cpustate[1];
		read_mem_block(cpustate,*src,32);
		cpustate[1]=old_readmem;
	}
	read_mem_block(&lastbank,*src,4);
	seek_ahead(*src,8);
	m6502_s=(u8*) ((u32)m6502_s&0x3FF);
	m6502_pc=(u8*)((u32)m6502_pc-(u32)lastbank);
	lastbank=NULL;
	read_mem_block(ppustate,*src,32);
	nextx=scrollX;
}
/*
savelst	DCD rominfo,8,NES_RAM,0x2800,NES_VRAM,0x3000,agb_pal,96
	DCD vram_map,64,agb_nt_map,16,mapperstate,48,rommap,16,cpustate,44,ppustate,32
*/

#if !MOVIEPLAYER
void loadstate(int romnumber, u8* src, int statesize)
#else
bool loadstate(const char* filename)
#endif
{
	#if !MOVIEPLAYER
	u8* limit=src+statesize;
	load_ptr file=src;
	#else
	File file;
	#endif

	bool do_load=true;
	
	u32 tag;
	int size;
	
	#if MOVIEPLAYER
	file=FAT_fopen(filename,"r");
	if (file==NO_FILE)
	{
		do_load=false;
	}
	#endif

	if (do_load)
	{
		do
		{
			int tagid;
			//verify presence of VERS tag as first thing in file
			if (!read_u32(file,tag)) break;
			//look up tag
			tagid=tag_search(tag,tags,NUM_TAGS);
			if (tagid!=VERSION_TAG)
			{
				seek_ahead(file,-4);
				#if !MOVIEPLAYER
				//reboot game, but don't clear some stuff
				do_not_decompress=1;
				do_not_reset_all=1;
				loadcart(romnumber,emuflags,0);
				do_not_decompress=0;
				do_not_reset_all=0;
				#endif
				load_old_savestate(&file);
				break;
			}
			else
			{
				if (!read_u32(file,size)) break;
				//discard version block
				loadblock(&file,tag,size);
				
				#if !MOVIEPLAYER
					//reboot game to a blank slate
					do_not_decompress=1;
					loadcart(romnumber,emuflags,0);
					do_not_decompress=0;
				#endif
				
				//load all other tags
				while (1)
				{
					if (!read_u32(file,tag)) break;
					if (!read_u32(file,size)) break;
					loadblock(&file,tag,size);
				}
			}
		} while (0);
		#if MOVIEPLAYER
		FAT_fclose(file);
		#endif
		restore_variables_for_loadstate();
		restore_more_variables_for_loadstate();
	}
	#if MOVIEPLAYER
	return do_load;
	#endif
}

#if !MOVIEPLAYER
int savestate(u8 *dest)
#else
bool savestate(const char *filename)
#endif
{
	int tag_number;
	int totalsize=0;
	int mysize;
	
	#if !MOVIEPLAYER
	save_ptr file = dest;
	#else
	bool retval=false;
	save_ptr file;
	file=FAT_fopen(filename,"r+b");
	if (file==NO_FILE)
	{
		file=FAT_fopen(filename,"wb");
	}
	if (file!=NO_FILE)
	#endif
	{
		prepare_variables_for_savestate();
		
		for (tag_number=0;tag_number<NUM_TAGS;tag_number++)
		{
			mysize=dumpdata(&file,tag_number);
			totalsize+=mysize;
		}
		
		#if MOVIEPLAYER
		FAT_fclose(file);
//		build_chr_decode(); //BECAUSE OF POSSIBLE STACK OVERFLOW
		retval=true;
		#endif
		
		restore_variables_for_loadstate();
	}
	
#if !MOVIEPLAYER
	return totalsize;
#else
	return retval;
#endif
}





int save_normal(save_ptr *dest, const u8* src, int size, u32 tag)
{
	write_u32(*dest,tag);
	write_u32(*dest,size);
	write_mem_block(*dest,src,size);
	return size;
}
int save_deref(save_ptr *dest, const u8* src, int size, u32 tag)
{
	const u8 **src_ptr= (const u8**)src;
	const u8* src2=*src_ptr;
	
	return save_normal(dest,src2,size,tag);
}
int save_vram1(save_ptr *dest, const u8* src, int size, u32 tag)
{
	if (has_vram==0)
	{
		return -1;
	}
	else
	{
		return save_normal(dest,src,size,tag);
	}
}
int save_vram4(save_ptr *dest, const u8* src, int size, u32 tag)
{
	if (fourscreen==0)
	{
		return -1;
	}
	else
	{
		return save_normal(dest,src,size,tag);
	}
}
int save_invalid(save_ptr *dest, const u8* src, int size, u32 tag)
{
	return -1;
}


int load_normal(u8* dest, load_ptr *src, int actualsize, int expectedsize)
{
	if (actualsize<=expectedsize)
	{
		read_mem_block(dest,*src,actualsize);
		return actualsize;
	}
	else //(actualsize>expectedsize)
	{
		read_mem_block(dest,*src,expectedsize);
		seek_ahead(*src,actualsize-expectedsize);
		return expectedsize;
	}
}
int load_deref(u8* dest, load_ptr *src, int actualsize, int expectedsize)
{
	u8 **dest_ptr= (u8**)dest;
	u8 *dest2=*dest_ptr;
	return load_normal(dest2,src, actualsize, expectedsize);
}
int load_writeonly(u8* dest, load_ptr *src, int actualsize, int expectedsize)
{
	seek_ahead(*src,actualsize);
	return -1;
}
int load_ppustate(u8* dest, load_ptr *src, int actualsize, int expectedsize)
{
	int retval;
	retval= load_normal(dest,src,actualsize,expectedsize);
	if (actualsize<expectedsize)
	{
		nextx=scrollX;
	}
	return retval;
}

int load_vram1(u8* dest, load_ptr *src, int actualsize, int expectedsize)
{
	if (has_vram==0)
	{
		return load_writeonly(dest,src,actualsize,expectedsize);
	}
	else
	{
		return load_normal(dest,src,actualsize,expectedsize);
	}
}
int load_vram4(u8* dest, load_ptr *src, int actualsize, int expectedsize)
{
	if (fourscreen==0)
	{
		return load_writeonly(dest,src,actualsize,expectedsize);
	}
	else
	{
		return load_normal(dest,src,actualsize,expectedsize);
	}
}
int load_invalid(u8 *dest, load_ptr *src, int actualsize, int expectedsize)
{
	return load_writeonly(dest,src,actualsize,expectedsize);
}



void prepare_variables_for_savestate()
{
	ppustat_savestate=ppustat_;
	
	m6502_pc=(u8*)(m6502_pc - lastbank);
	m6502_s=(u8*)((u32)m6502_s-(u32)NES_RAM);
	lastbank=NULL;

	_pcmstart=(u8*) ((u32)_pcmstart-(u32)PCMWAV);
	_pcmcurrentaddr=(u8*) ((u32)_pcmcurrentaddr-(u32)PCMWAV);
}
void restore_variables_for_loadstate()
{
	u32 oldpc;
	
	oldpc=(u32)m6502_pc;
	
	#if MOVIEPLAYER
	update_cache();
	build_chr_decode();
	#else
	rebankswitch();
	#endif
	
	lastbank= memmap_tbl[ (((u32)m6502_pc) & 0xE000) / 8192];
	m6502_pc= (u8*)((u32)oldpc+(u32)lastbank);
	m6502_s=(u8*)((u32)m6502_s+(u32)NES_RAM);
	
	cpustate[1]=(u32)memmap_tbl;
	
	ppustat_=ppustat_savestate;
	
	_pcmstart=(u8*) ((u32)_pcmstart+(u32)PCMWAV);
	_pcmcurrentaddr=(u8*) ((u32)_pcmcurrentaddr+(u32)PCMWAV);
}
void restore_more_variables_for_loadstate()
{
	//restore palette
	PaletteTxAll();
	//restore other graphics
	loadstate_gfx();
	
	//copy sprite tables
	memcpy(dmanesoambuff,nesoambuff,256);
	
	//make all tiles dirty
	memset(dirty_tiles,0xFF,512);
	memset(dirty_rows,0xFF,32);	
	
	//make background dirty
	_bg_cache_full=1;

}




#endif
