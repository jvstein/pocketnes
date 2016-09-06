#include <stdio.h>
#include <string.h>
#include "gba.h"
#include "minilzo.107/minilzo.h"

extern u32 g_emuflags;		//from cart.s
extern u32 joycfg;			//from io.s
extern u32 font;
extern u32 fontpal;
extern u32 *vblankfptr;		//from ppu.s
extern u32 vbldummy;		//from ppu.s
extern u32 vblankinterrupt;	//from ppu.s
extern u32 AGBinput;		//from ppu.s
extern u32 NESinput;
       u32 oldinput;
extern u8 autostate;		//from ui.c

extern romheader mb_header;
const PALTIMING=4;			//Also in equates.h

//asm calls
void loadcart(int,int);		//from cart.s
void run(int);
void ppu_init(void);
void resetSIO(u32);			//io.s
void LZ77UnCompVram(u32 *source,u16 *destination);		//io.s
void waitframe(void);									//io.s

void cls(int);
void rommenu(void);
int drawmenu(int);
int getinput(void);
int ines(u8 *p);
void splash(void);
void drawtext(int,char*,int);
void readconfig(void);		//sram.c
void quickload(void);
void backup_nes_sram(void);
void get_saved_sram(void);	//sram.c

const unsigned __fp_status_arm=0x40070000;
u8 *textstart;//points to first NES rom (initialized by boot.s)
int roms;//total number of roms

char pogoshell_romname[32];	//keep track of rom name (for state saving, etc)
char rtc=0;
char pogoshell=0;
char gameboyplayer=0;

int ne=0x454e;
void C_entry() {
	int i;
	vu16 *timeregs=(u16*)0x080000c8;
	u32 temp=(u32)(*(u8**)0x0203FBFC);
	if((temp & 0xFE000000) == 0x08000000) pogoshell=1;
	else pogoshell=0;
	*timeregs=1;
	if(*timeregs==1) rtc=1;
	vblankfptr=&vbldummy;
	ppu_init();

	if(pogoshell){
		u32 *magptr=(u32*)0x08000000;
		u32 *fileptr;
		char *d;
		char *s=(char*)0x0203fc08;

		while(*magptr!=0xfab0babe && magptr < (u32*)0x0a000000){
			magptr+=0x8000/4;						//Find the filesys root
		}
		magptr+=2;
		fileptr=magptr;

		do s++; while(*s);							//Command name (pce.bin)
		s++;
		if(strncmp(s,"/rom/",5)==0) s+=5;
		while(1){
			s++;									//First Directory
			d=s;									//First Directory
			while(*s!='/' && *s){s++;}				//Argument (/directory/.../romfile.pce)
			if(!*s)
				break;
			*s=0;									//Terminate directory name.
			while(strcmp((char*)magptr,d)){			//find directory
				magptr+=10;
			}
			magptr = (u32*)((u8*)fileptr + magptr[9]);
		}
		while(strcmp((char*)magptr,d)){				//find file
			magptr+=10;
		}
//		pogosize=magptr[8];							//file size
		if(strstr(d,"(E)") || strstr(d,"(e)"))		//Check if it's a European rom.
			g_emuflags |= PALTIMING;
		else
			g_emuflags &= ~PALTIMING;

		roms=1;
		textstart=(*(u8**)0x0203FBFC)-sizeof(romheader);
		memcpy(pogoshell_romname,d,32);
		memcpy(mb_header.name,d,32);
	}
	else
	{
		int nes_id=0x1a530000+ne;	//keep iNES id constant out of binary (for rom searching purposes)
		u8 *p;

		//splash screen present?
		if(*(u32*)(textstart+sizeof(romheader))!=nes_id) {
			splash();
			textstart+=76800;
		}

		i=0;
		p=textstart;
		while(*(u32*)(p+48)==nes_id) {	//count roms
			p+=*(u32*)(p+32)+48;
			i++;
		}
		if(!i)i=1;					//Stop PocketNES from crashing if there are no ROMs
		roms=i;
	}
	if(REG_DISPCNT==FORCE_BLANK)	//is screen OFF?
		REG_DISPCNT=0;				//screen ON
	*MEM_PALETTE=0x7FFF;			//white background
	REG_BLDCNT=0xff;				//(brightness decrease all)
	for(i=0;i<17;i++) {
		REG_COLY=i;					//fade to black
		waitframe();
	}
	*MEM_PALETTE=0;					//black background (avoids blue flash when doing multiboot)
	REG_DISPCNT=0;					//screen ON
	vblankfptr=&vblankinterrupt;
	lzo_init();	//init compression lib for savestates

	//load font+palette
	LZ77UnCompVram(&font,(u16*)0x6002400);
	memcpy((void*)0x5000080,&fontpal,64);
	readconfig();
	rommenu();
}

//show splash screen
void splash() {
	u16 *src;
	u16 *dst;
	int i;

	REG_DISPCNT=FORCE_BLANK;	//screen OFF
	src=(u16*)textstart;	//this *SHOULD* be halfword aligned..
	dst=MEM_VRAM;
	for(i=0;i<(240*160);i++) {
		*dst++=*src++;
	}
	waitframe();
	REG_BG2CNT=0x0000;
	REG_BLDCNT=0x84;	//(brightness increase)
	REG_DISPCNT=BG2_EN|MODE3;
	for(i=16;i>=0;i--) {	//fade from white
		REG_COLY=i;
		waitframe();
	}
	for(i=0;i<150;i++) {	//wait 2.5 seconds
		waitframe();
		if (REG_P1==0x030f) gameboyplayer=1;
	}
}

void rommenu(void) {
	cls(3);
	REG_BG2HOFS=0x0100;		//Screen left
	REG_BLDCNT=0x00f3;	//darken screen
	REG_COLY=16;
	REG_BG2CNT=0x4600;	//16color 512x256 CHRbase0 SCRbase6 Priority0
	REG_DISPCNT=BG2_EN|OBJ_1D; //mode0, 1d sprites, main screen turn on
	backup_nes_sram();

	if(pogoshell)
	{
		loadcart(0,g_emuflags&0x304);		//Also save country
		get_saved_sram();
		if(autostate)quickload();
		run(1);
	}
	else
	{
		static int selectedrom=0;
		int i,lastselected=-1;
		int key;

		int romz=roms;	//globals=bigger code :P
		int sel=selectedrom;

		oldinput=AGBinput=~REG_P1;
		resetSIO((joycfg&~0xff000000) + 0x20000000);//back to 1P
    
		i=drawmenu(sel);
		loadcart(sel,i|(g_emuflags&0x300));  //(keep old gfxmode)
		get_saved_sram();
		lastselected=sel;
		if(romz>1){
			for(i=0;i<8;i++)
			{
				waitframe();
				REG_BG2HOFS=224-i*32;	//Move screen right
			}
			REG_COLY=7;			//Lighten screen
		}
		do {
			key=getinput();
			if(key&RIGHT) {
				sel+=10;
				if(sel>romz-1) sel=romz-1;
			}
			if(key&LEFT) {
				sel-=10;
				if(sel<0) sel=0;
			}
			if(key&UP)
				sel=sel+romz-1;
			if(key&DOWN)
				sel++;
			selectedrom=sel%=romz;
			if(lastselected!=sel) {
				if(romz>1)i=drawmenu(sel);
				loadcart(sel,i|(g_emuflags&0x300));  //(keep old gfxmode)
				get_saved_sram();
				lastselected=sel;
			}
			run(0);
		} while(romz>1 && !(key&(A_BTN+B_BTN+START)));
		for(i=0;i<8;i++)
		{
			waitframe();
			REG_COLY=7-i;		//Lighten screen
			REG_BG2HOFS=i*32;	//Move screen left
			run(0);
		}
		REG_BG2HOFS=0x0100;		//Screen left
		cls(3);	//leave BG2 on for debug output
		while(AGBinput&(A_BTN+B_BTN+START)) {
			AGBinput=0;
			run(0);
		}
		if(autostate)quickload();
		run(1);
	}
}

//return ptr to Nth ROM (including rominfo struct)
u8 *findrom(int n) {
	u8 *p=textstart;
	while(!pogoshell && n--)
		p+=*(u32*)(p+32)+sizeof(romheader);
	return p;
}

//returns options for selected rom
int drawmenu(int sel) {
	int i,j,topline,toprow,romflags=0;
	u8 *p;
	romheader *ri;

	if(roms>20) {
		topline=8*(roms-20)*sel/(roms-1);
		toprow=topline/8;
		j=(toprow<roms-20)?21:20;
	} else {
		toprow=0;
		j=roms;
	}
	p=findrom(toprow);
	for(i=0;i<j;i++) {
		if(roms>1)drawtext(i,(char*)p,i==(sel-toprow)?1:0);
		if(i==sel-toprow) {
			ri=(romheader*)p;
			romflags=(*ri).flags|(*ri).spritefollow<<16;
		}
		p+=*(u32*)(p+32)+48;
	}
	if(roms>20)
		REG_BG2VOFS=topline%8;
	else
		REG_BG2VOFS=176+roms*4;
	return romflags;
}

int getinput() {
	static int lastdpad,repeatcount=0;
	int dpad;
	int keyhit=(oldinput^AGBinput)&AGBinput;
	oldinput=AGBinput;

	dpad=AGBinput&(UP+DOWN+LEFT+RIGHT);
	if(lastdpad==dpad) {
		repeatcount++;
		if(repeatcount<25 || repeatcount&3)	//delay/repeat
			dpad=0;
	} else {
		repeatcount=0;
		lastdpad=dpad;
	}
	NESinput=0;	//disable game input
	return dpad|(keyhit&(A_BTN+B_BTN+START));
}


void cls(int chrmap) {
	int i=0,len=0x200;
	u32 *scr=(u32*)SCREENBASE;
	if(chrmap>=2)
		len=0x400;
	if(chrmap==2)
		i=0x200;
	for(;i<len;i++)				//512x256
		scr[i]=0x01200120;
	REG_BG2VOFS=0;
}

void drawtext(int row,char *str,int hilite) {
	u16 *here=SCREENBASE+row*32;
	int i=0;

	*here=hilite?0x412a:0x4120;
	hilite=(hilite<<12)+0x4100;
	here++;
	while(str[i]>=' ') {
		here[i]=str[i]|hilite;
		i++;
	}
	for(;i<31;i++)
		here[i]=0x0120;
}

