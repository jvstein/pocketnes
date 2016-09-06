#include <string.h>
#include "gba.h"
#include "minilzo.107/minilzo.h"

#define STATEID 0x57a731d7

#define STATESAVE 0
#define SRAMSAVE 1
#define CONFIGSAVE 2

extern u8 Image$$RO$$Limit;
extern u8 g_cartflags;	//(from iNES header)
extern char g_scaling;	//(cart.s) current display mode
extern u8 *textstart;	//from main.c

extern int pogones;

int totalstatesize;	//how much SRAM is used

//-------------------
u8 *findrom(int);
void cls(void);		//main.c
void drawtext(int,char*,int);
void waitframe(void);
u32 getmenuinput(int);
void writeconfig(void);
void setup_sram_after_loadstate(void);

extern int roms;		//main.c
extern int selected;	//ui.c
extern char pogoshell_romname[32];	//main.c
//----asm stuff------
int savestate(void*);		//cart.s
void loadstate(int,void*);		//cart.s

extern u8 *romstart;	//from cart.s
extern u32 romnum;	//from cart.s
extern u32 frametotal;	//from 6502.s
//-------------------

typedef struct {
	u16 size;	//header+data
	u16 type;	//=STATESAVE or SRAMSAVE
	u32 compressedsize;
	u32 framecount;
	u32 checksum;
	char title[32];
} stateheader;

typedef struct {		//(modified stateheader)
	u16 size;
	u16 type;	//=CONFIGSAVE
	char displaytype;
	char reserved1;
	char reserved2;
	char reserved3;
	u32 sram_checksum;	//checksum of rom using SRAM e000-ffff	
	u32 zero;	//=0
	char reserved4[32];  //="CFG"
} configdata;

//we have a big chunk of memory starting at Image$$RO$$Limit free to use
#define BUFFER1 (&Image$$RO$$Limit)
#define BUFFER2 (&Image$$RO$$Limit+0x10000)
#define BUFFER3 (&Image$$RO$$Limit+0x20000)

void bytecopy(u8 *dst,u8 *src,int count) {
	int i=0;
	do {
		dst[i]=src[i];
		i++;
	} while(--count);
}

/*
void debug_(u32 n,int line);
void errmsg(char *s) {
	int i;

	drawtext(9,s,0);
	for(i=30;i;--i)
		waitframe();
	drawtext(9,"                     ",0);
}*/

void getsram() {		//copy GBA sram to BUFFER1
	u8 *sram=MEM_SRAM;
	u8 *buff1=BUFFER1;
	u32 *p;

	p=(u32*)buff1;
	if(*p!=STATEID) {	//if sram hasn't been copied already
		bytecopy(buff1,sram,0xe000);	//copy everything to BUFFER1
		if(*p!=STATEID) {	//valid savestate data?
			*p=STATEID;	//nope.  initialize
			*(p+1)=0;
		}
	}
}

//quick & dirty rom checksum
u32 checksum(u8 *p) {
	u32 sum=0;
	int i;
	for(i=0;i<128;i++) {
		sum+=*p|(*(p+1)<<8)|(*(p+2)<<16)|(*(p+3)<<24);
		p+=128;
	}
	return sum;
}

void writeerror() {
	int i;
	cls();
	drawtext(9,"  Write error! Memory full.",0);
	drawtext(10,"     Delete some games.",0);
	for(i=90;i;--i)
		waitframe();
}

//(BUFFER1=copy of GBA SRAM, BUFFER3=new data)
//overwrite:  index=state#, erase=0
//new:  index=big number (anything >=total saves), erase=0
//erase:  index=state#, erase=1
//returns TRUE if successful
//IMPORTANT!!! totalstatesize is assumed to be current
int updatestates(int index,int erase,int type) {
	int i;
	int srcsize;
	int total=totalstatesize;
	u8 *dst=BUFFER1;
	u8 *src=BUFFER2;
	stateheader *newdata=(stateheader*)BUFFER3;

	memcpy(src,dst,total);			//copy buffer1 to buffer2
						//(buffer1=new, buffer2=old)
	src+=4;//skip STATEID
	dst+=4;

	//skip ahead to where we want to write

	srcsize=((stateheader*)src)->size;
	i=(type==((stateheader*)src)->type)?0:-1;
	while(i<index && srcsize) {	//while (looking for state) && (not out of data)
		dst+=srcsize;
		src+=srcsize;
		srcsize=((stateheader*)src)->size;
		if(((stateheader*)src)->type==type)
			i++;
	}

	//write new data

	total-=srcsize;
	if(!erase) {
		i=newdata->size;
		total+=i;
		if(total>0xe000) //**OUT OF MEMORY**
			return 0;
		memcpy(dst,newdata,i);	//overwrite
		dst+=i;
	}
	src+=srcsize;
	srcsize=((stateheader*)src)->size;

	//get trailing data

	while(srcsize) {
		memcpy(dst,src,srcsize);
		dst+=srcsize;
		src+=srcsize;
		srcsize=((stateheader*)src)->size;
	}
	*(u32*)dst=0;	//terminate
	*(u32*)(dst+4)=0xffffffff;	//terminate
	dst+=8;
	total+=8;

	//copy everything to GBA sram

	totalstatesize=total;
	while(total<0xe000)
	{
		*dst++=0;
		total++;
	}
	bytecopy(MEM_SRAM,BUFFER1,total);	//copy to sram
	return 1;
}

//more dumb stuff so we don't waste space by using sprintf
int twodigits(int n,char *s) {
	int mod=n%10;
	n=n/10;
	*(s++)=(n+'0');
	*s=(mod+'0');
	return n;
}

void getstatetimeandsize(char *s,int time,u32 size,u32 totalsize) {
	strcpy(s,"00:00:00 - 00/00k");
	twodigits(time/216000,s);
	s+=3;
	twodigits((time/3600)%60,s);
	s+=3;
	twodigits((time/60)%60,s);
	s+=5;
	twodigits(size/1024,s);
	s+=3;
	twodigits(totalsize/1024,s);
}

#define LOADMENU 0
#define SAVEMENU 1
#define SRAMMENU 2
#define FIRSTLINE 2
#define LASTLINE 16

//BUFFER1 holds copy of SRAM
//draw save/loadstate menu and update global totalstatesize
//returns a pointer to current selected state
//update *states on exit
stateheader* drawstates(int menutype,int *menuitems,int *menuoffset) {
	int type;
	int offset=*menuoffset;
	int sel=selected;
	int startline;
	int size;
	int statecount;
	int total;
	char s[30];
	stateheader *selectedstate;
	int time;
	int selectedstatesize;
	stateheader *sh=(stateheader*)(BUFFER1+4);

	type=(menutype==SRAMMENU)?SRAMSAVE:STATESAVE;

	statecount=*menuitems;
	if(sel-offset>LASTLINE-FIRSTLINE-3 && statecount>LASTLINE-FIRSTLINE+1) {		//scroll down
		offset=sel-(LASTLINE-FIRSTLINE-3);
		if(offset>statecount-(LASTLINE-FIRSTLINE+1))	//hit bottom
			offset=statecount-(LASTLINE-FIRSTLINE+1);
	}
	if(sel-offset<3) {				//scroll up
		offset=sel-3;
		if(offset<0)					//hit top
			offset=0;
	}
	*menuoffset=offset;
	
	startline=FIRSTLINE-offset;
	cls();
	statecount=0;
	total=8;	//header+null terminator
	while(sh->size) {
		size=sh->size;
		if(sh->type==type) {
			if(startline+statecount>=FIRSTLINE && startline+statecount<=LASTLINE) {
				drawtext(startline+statecount,sh->title,sel==statecount);
			}
			if(sel==statecount) {		//keep info for selected state
				time=sh->framecount;
				selectedstatesize=size;
				selectedstate=sh;
			}
			statecount++;
		}
		total+=size;
		sh=(stateheader*)((u8*)sh+size);
	}

	if(sel!=statecount) {//not <NEW>
		getstatetimeandsize(s,time,selectedstatesize,total);
		drawtext(18,s,0);
	}
	if(statecount)
		drawtext(19,"Push SELECT to delete",0);
	if(menutype==SAVEMENU) {
		if(startline+statecount<=LASTLINE)
			drawtext(startline+statecount,"<NEW>",sel==statecount);
		drawtext(0,"Save state:",0);
		statecount++;	//include <NEW> as a menuitem
	} else if(menutype==LOADMENU) {
		drawtext(0,"Load state:",0);
	} else {
		drawtext(0,"Erase SRAM:",0);
	}
	*menuitems=statecount;
	totalstatesize=total;
	return selectedstate;
}

//compress src into BUFFER3 (adding header), using 64k of workspace
void compressstate(lzo_uint size,u16 type,u8 *src,void *workspace) {
	lzo_uint compressedsize;
	stateheader *sh;

	lzo1x_1_compress(src,size,BUFFER3+sizeof(stateheader),&compressedsize,workspace);

	//setup header:
	sh=(stateheader*)BUFFER3;
	sh->size=(compressedsize+sizeof(stateheader)+3)&~3;	//size of compressed state+header, word aligned
	sh->type=type;
	sh->compressedsize=compressedsize;	//size of compressed state
	sh->framecount=frametotal;
	sh->checksum=checksum((u8*)romstart);	//checksum
    if(pogones)
    {
		strcpy(sh->title,pogoshell_romname);
    }
    else
    {
		strcpy(sh->title,(char*)findrom(romnum));
    }
}

void managesram() {
	int i;
	int menuitems;
	int offset=0;

	getsram();

	selected=0;
	drawstates(SRAMMENU,&menuitems,&offset);
	if(!menuitems)
		return;		//nothing to do!
	do {
		i=getmenuinput(menuitems);
		if(i&SELECT) {
			updatestates(selected,1,SRAMSAVE);
			if(selected==menuitems-1) selected--;	//deleted last entry.. move up one
		}
		if(i&(SELECT+UP+DOWN+LEFT+RIGHT))
			drawstates(SRAMMENU,&menuitems,&offset);
	} while(menuitems && !(i&(L_BTN+R_BTN+B_BTN)));
}

void savestatemenu() {
	int i;
	int menuitems;
	int offset=0;

	i=savestate(BUFFER2);
	compressstate(i,STATESAVE,BUFFER2,BUFFER1);

	getsram();

	selected=0;
	drawstates(SAVEMENU,&menuitems,&offset);
	do {
		i=getmenuinput(menuitems);
		if(i&(A_BTN)) {
			if(!updatestates(selected,0,STATESAVE))
				writeerror();
		}
		if(i&SELECT)
			updatestates(selected,1,STATESAVE);
		if(i&(SELECT+UP+DOWN+LEFT+RIGHT))
			drawstates(SAVEMENU,&menuitems,&offset);
	} while(!(i&(L_BTN+R_BTN+A_BTN+B_BTN)));
}

//locate last save by checksum
//returns save index (-1 if not found) and updates stateptr
//updates totalstatesize (so quicksave can use updatestates)
int findstate(u32 checksum,int type,stateheader **stateptr) {
	int state,size,foundstate,total;
	stateheader *sh;

	getsram();
	sh=(stateheader*)(BUFFER1+4);

	state=-1;
	foundstate=-1;
	total=8;
	size=sh->size;
	while(size) {
		if(sh->type==type) {
			state++;
			if(sh->checksum==checksum) {
				foundstate=state;
				*stateptr=sh;
			}
		}
		total+=size;
		sh=(stateheader*)(((u8*)sh)+size);
		size=sh->size;
	}
	totalstatesize=total;
	return foundstate;
}

void uncompressstate(int rom,stateheader *sh) {
	lzo_uint statesize=sh->compressedsize;
	lzo1x_decompress((u8*)(sh+1),statesize,BUFFER2,&statesize,NULL);
	loadstate(rom,BUFFER2);
	frametotal=sh->framecount;		//restore global frame counter
	setup_sram_after_loadstate();	//handle sram packing
}

int using_flashcart() {
	return (u32)textstart&0x8000000;
}

void quickload() {
	stateheader *sh;
	int i;

	if(!using_flashcart())
		return;

	i=findstate(checksum((u8*)romstart),STATESAVE,&sh);
	if(i>=0)
		uncompressstate(romnum,sh);
}

void quicksave() {
	stateheader *sh;
	int i;

	if(!using_flashcart())
		return;

	REG_BLDCNT=0x00f3;	//darken
	drawtext(9,"           Saving.",0);

	i=savestate(BUFFER2);
	compressstate(i,STATESAVE,BUFFER2,BUFFER1);
	i=findstate(checksum((u8*)romstart),STATESAVE,&sh);
	if(i<0) i=65536;	//make new save if one doesn't exist
	if(!updatestates(i,0,STATESAVE))
		writeerror();
	cls();
}

void backup_nes_sram() {
	int i;
	configdata *cfg;
	stateheader *sh;
	lzo_uint compressedsize;

	if(!using_flashcart())
		return;

	i=findstate(0,CONFIGSAVE,(stateheader**)&cfg);	//find config
	if(i>=0 && cfg->sram_checksum) {	//SRAM is occupied?
		i=findstate(cfg->sram_checksum,SRAMSAVE,&sh);//find out where to save
		if(i>=0) {
			memcpy(BUFFER3,sh,sizeof(stateheader));//use old info, in case the rom for this sram is gone and we can't look up its name.
			lzo1x_1_compress(MEM_SRAM+0xe000,0x2000,BUFFER3+sizeof(stateheader),&compressedsize,BUFFER2);
			sh=(stateheader*)BUFFER3;
			sh->size=(compressedsize+sizeof(stateheader)+3)&~3;	//size of compressed state+header, word aligned
			sh->compressedsize=compressedsize;	//size of compressed state
			updatestates(i,0,SRAMSAVE);
		}
	}
}

//make new saved sram (using NES_SRAM contents)
//this is to ensure that we have all info for this rom and can save it even after this rom is removed
void save_new_sram() {
	compressstate(0x2000,SRAMSAVE,NES_SRAM,BUFFER2);
	updatestates(65536,0,SRAMSAVE);
}

void get_saved_sram() {
	int i,j;
	u32 chk;
	configdata *cfg;
	stateheader *sh;
	lzo_uint statesize;

	if(!using_flashcart())
		return;

	if(g_cartflags&2) {	//if rom uses SRAM
		chk=checksum(romstart);
		i=findstate(0,CONFIGSAVE,(stateheader**)&cfg);	//find config
		j=findstate(chk,SRAMSAVE,&sh);	//see if packed SRAM exists
		if(i>=0) if(chk==cfg->sram_checksum) {	//SRAM is already ours
			bytecopy(NES_SRAM,MEM_SRAM+0xe000,0x2000);
			if(j<0) save_new_sram();	//save it if we need to
			return;
		}
		if(j>=0) {//packed SRAM exists: unpack into NES_SRAM
			statesize=sh->compressedsize;
			lzo1x_decompress((u8*)(sh+1),statesize,NES_SRAM,&statesize,NULL);
		} else { //pack new sram and save it.
			save_new_sram();
		}
		bytecopy(MEM_SRAM+0xe000,NES_SRAM,0x2000);
		writeconfig();//register new sram owner
	}
}

void setup_sram_after_loadstate() {
	int i;
	u32 chk;
	configdata *cfg;

	if(g_cartflags&2) {	//if rom uses SRAM
		chk=checksum(romstart);
		i=findstate(0,CONFIGSAVE,(stateheader**)&cfg);	//find config
		if(i>=0) if(chk!=cfg->sram_checksum) {//if someone else was using sram, save it
			backup_nes_sram();
		}
		bytecopy(MEM_SRAM+0xe000,NES_SRAM,0x2000);		//copy nes sram to real sram
		i=findstate(chk,SRAMSAVE,(stateheader**)&cfg);	//does packed SRAM for this rom exist?
		if(i<0)						//if not, create it
			save_new_sram();
		writeconfig();//register new sram owner
	}
}

void loadstatemenu() {
	stateheader *sh;
	u32 key;
	int i;
	int offset=0;
	int menuitems;
	u32 sum;

	getsram();

	selected=0;
	sh=drawstates(LOADMENU,&menuitems,&offset);
	if(!menuitems)
		return;		//nothing to load!

	do {
		key=getmenuinput(menuitems);
		if(key&(A_BTN)) {
			sum=sh->checksum;
			i=0;
			do {
				if(sum==checksum(findrom(i)+sizeof(romheader)+16)) {	//find rom with matching checksum
					uncompressstate(i,sh);
					i=8192;
				}
				i++;
			} while(i<roms);
			if(i<8192) {
				cls();
				drawtext(9,"       ROM not found.",0);
				for(i=0;i<60;i++)	//(1 second wait)
					waitframe();
			}
		} else if(key&SELECT) {
			updatestates(selected,1,STATESAVE);
			if(selected==menuitems-1) selected--;	//deleted last entry? move up one
		}
		if(key&(SELECT+UP+DOWN+LEFT+RIGHT))
			sh=drawstates(LOADMENU,&menuitems,&offset);
	} while(menuitems && !(key&(L_BTN+R_BTN+A_BTN+B_BTN)));
}

const configdata configtemplate={
	sizeof(configdata),
	CONFIGSAVE,
	0,0,0,0,0,0,
	"CFG"
};

void writeconfig() {
	configdata *cfg;
	int i;

	if(!using_flashcart())
		return;

	i=findstate(0,CONFIGSAVE,(stateheader**)&cfg);
	if(i<0) {//make new config
		memcpy(BUFFER3,&configtemplate,sizeof(configdata));
		cfg=(configdata*)BUFFER3;
	}
	cfg->displaytype=g_scaling;				//store current display type
	if(g_cartflags&2) {					//update sram owner
			cfg->sram_checksum=checksum(romstart);
	}
	if(i<0) {	//create new config
		updatestates(0,0,CONFIGSAVE);
	} else {		//config already exists, update sram directly (faster)
		bytecopy((u8*)cfg-BUFFER1+MEM_SRAM,(u8*)cfg,sizeof(configdata));
	}
}

void readconfig() {
	int i;
	configdata *cfg;
	if(!using_flashcart())
		return;

	i=findstate(0,CONFIGSAVE,(stateheader**)&cfg);
	if(i>=0) {
		g_scaling=cfg->displaytype;
	}
}
void clean_nes_sram() {
	int i;
	u8 *nes_sram_ptr = MEM_SRAM+0xe000;
	configdata *cfg;

	if(!using_flashcart())
		return;

	for(i=0;i<0x2000;i++) *nes_sram_ptr++ = 0;

	i=findstate(0,CONFIGSAVE,(stateheader**)&cfg);
	if(i<0) {//make new config
		memcpy(BUFFER3,&configtemplate,sizeof(configdata));
		cfg=(configdata*)BUFFER3;
	}
	cfg->displaytype=g_scaling;				//store current display type
	cfg->sram_checksum=0;			// we don't want to save the empty sram
	if(i<0) {	//create new config
		updatestates(0,0,CONFIGSAVE);
	} else {		//config already exists, update sram directly (faster)
		bytecopy((u8*)cfg-BUFFER1+MEM_SRAM,(u8*)cfg,sizeof(configdata));
	}
}

