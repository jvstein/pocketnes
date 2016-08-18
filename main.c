#include <stdio.h>
#include <string.h>
#include "gba.h"
#include "minilzo.107/minilzo.h"

typedef struct {
	char name[32];
	u32 filesize;
	u32 flags;
	u32 followval;
	u32 reserved;
} rominfo;

extern u32 g_emuflags;	//from cart.s
extern u32 joycfg;	//from io.s
extern u32 font;
extern u32 fontpal;
extern u32 AGBinput;	//from ppu.s
extern u32 NESinput;
       u32 oldinput;

extern romheader mb_header;

//asm calls
void loadcart(int,int);	//from cart.s
void run(int);
void ppu_init(void);
void resetSIO(u32);//io.s

void cls(void);
void rommenu(void);
int drawmenu(int);
int getinput(void);
int ines(u8 *p);
void splash(void);
void waitframe(void);
void drawtext(int,char*,int);
void readconfig(void);		//sram.c
void backup_nes_sram(void);
void get_saved_sram(void);	//sram.c

const unsigned __fp_status_arm=0x40070000;
u8 *textstart;//points to first NES rom (initialized by boot.s)
int roms;//total number of roms

char pogoshell_romname[32];	//keep track of rom name (for state saving, etc)
int pogones=0;

int ne=0x454e;
void C_entry() {
    u32 temp=(u32)(*(u8**)0x0203FBFC);
    if((temp & 0xFE000000) == 0x08000000) pogones=1;
    if(pogones)
    {
	char *s=(char*)0x203fc08;
	do s++; while(*s);
	do s++; while(*s);
	do s--; while(*s!='/');
	s++;			//s=nes rom name

	roms=1;
	textstart=(*(u8**)0x0203FBFC)-sizeof(romheader);
	memcpy(pogoshell_romname,s,32);
	memcpy(mb_header.name,s,32);

	lzo_init();	//init compression lib for savestates
	ppu_init();
    }
    else
    {
	int nes_id=0x1a530000+ne;	//keep iNES id constant out of binary (for rom searching purposes)
	int i;
	u8 *p;
	REG_DISPCNT=FORCE_BLANK;	//screen OFF

	lzo_init();	//init compression lib for savestates

	//splash screen present?
	if(*(u32*)(textstart+48)!=nes_id) {
		splash();
		textstart+=76800;
	}

	ppu_init();

	i=0;
	p=textstart;
	while(*(u32*)(p+48)==nes_id) {	//count roms
		p+=*(u32*)(p+32)+48;
		i++;
	}
	roms=i;
        
    }
	//load font+palette
	memcpy((void*)0x6002400,&font,16*8*32);
	memcpy((void*)0x5000080,&fontpal,64);
	readconfig();
	rommenu();
}

//show splash screen
void splash() {
	u16 *src;
	u16 *dst;
	int i;

	src=(u16*)textstart;	//this *SHOULD* be halfword aligned..
	dst=MEM_VRAM;
	for(i=0;i<38400;i++) {
		*dst=*src;
		src++;
		dst++;
	}
	waitframe();
	REG_BG2CNT=0x0000;
	REG_BLDMOD=0x84;	//(brightness increase)
	REG_DISPCNT=BG2_EN|MODE3;
	for(i=16;i>=0;i--) {	//fade from white
		REG_COLY=i;
		waitframe();
	}
	for(i=0;i<150;i++) {	//wait 2.5 seconds
		waitframe();
	}
	REG_BLDMOD=0xc4;	//(brightness decrease)
	for(i=0;i<16;i++) {
		REG_COLY=i;	//fade to black
		waitframe();
	}
	*MEM_PALETTE=0;//black background (avoids blue flash when doing multiboot)
}

void rommenu(void) {
    if(pogones)
    {
        cls();
        REG_BLDMOD=0;
        REG_BG2CNT=0x0700;	//16color 256x256 CHRbase0 SCRbase7 Priority0
        REG_DISPCNT=BG2_EN|OBJ_1D; //mode0, 1d sprites, main screen turn on
        backup_nes_sram();
        loadcart(0,g_emuflags&0x300);
        get_saved_sram();
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
    	cls();
    	waitframe();
    	REG_BLDMOD=0x00f3;	//darken screen
    	REG_BG2CNT=0x0700;	//16color 256x256 CHRbase0 SCRbase7 Priority0
    	REG_DISPCNT=BG2_EN|OBJ_1D; //mode0, 1d sprites, main screen turn on
    	resetSIO((joycfg&~0xff000000) + 0x40000000);//back to 1P
    
    	backup_nes_sram();
    
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
    			i=drawmenu(sel);
    			loadcart(sel,i|(g_emuflags&0x300));  //(keep old gfxmode)
    			get_saved_sram();
    			lastselected=sel;
    		}
    		run(0);
    	} while(romz>1 && !(key&(A_BTN+B_BTN+START)));
    	cls();	//leave BG2 on for debug output
    	while(AGBinput&(A_BTN+B_BTN+START)) {
    		AGBinput=0;
    		run(0);
    	}
    	run(1);
    }
}

//return ptr to Nth ROM (including rominfo struct)
u8 *findrom(int n) {
        u8 *p=textstart;
        while(!pogones && n--)
            p+=*(u32*)(p+32)+sizeof(romheader);
        return p;
}

//returns options for selected rom
int drawmenu(int sel) {
	int i,j,topline,toprow,romflags;
	u8 *p;
	rominfo *ri;

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
		drawtext(i,(char*)p,i==(sel-toprow)?1:0);
		if(i==sel-toprow) {
			ri=(rominfo*)p;
			romflags=(*ri).flags|(*ri).followval<<16;
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
		if(repeatcount<25 || repeatcount&3)    //delay/repeat
			dpad=0;
	} else {
		repeatcount=0;
		lastdpad=dpad;
	}
	NESinput=0;	//disable game input
	return dpad|(keyhit&(A_BTN+B_BTN+START));
}


void cls(void) {
	int i;
	u32 *scr=(u32*)SCREENBASE;
	for(i=0;i<0x200;i++)
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
	for(;i<29;i++)
		here[i]=0x0120;
}

void waitframe(void) {
#ifndef __DEBUGBUILD
	while(REG_VCOUNT>=160) {};
	while(REG_VCOUNT<160) {};
#endif
}
