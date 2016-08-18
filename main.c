#include <stdio.h>
#include <string.h>
#include "gba.h"
#include "minilzo.107/minilzo.h"

#define NES_ID 0x1a53454e

typedef struct {
	char name[32];
	u32 filesize;
	u32 flags;
	u32 spritenum;
	u32 saveslot;
} rominfo;

extern u32 hflags;	//from cart.s
extern u32 joycfg;	//from io.s
extern u32 font;
extern u32 fontpal;
extern u32 AGBinput;	//from ppu.s
       u32 oldinput;

//asm calls
void loadcart(int,int);	//from cart.s
void run(int);
void ppu_init(void);
void resetSIO(u32);//io.s

void rommenu(void);
int drawmenu(void);
int getinput(void);
int ines(u8 *p);
void splash(void);
void waitframe(void);
void drawtext(int,char*,int);

const unsigned __fp_status_arm=0x40070000;
int roms;//total number of roms
u8 *textstart;//where rom descriptions reside (initialized by boot.s)

void C_entry() {
	int i;
	u8 *p;
	REG_DISPCNT=FORCE_BLANK;	//screen OFF

	lzo_init();	//init compression lib for savestates

	//splash screen present?
	if(*(u32*)(textstart+48)!=NES_ID) {
		splash();
		textstart+=76800;
	}

	ppu_init();

	i=0;
	p=textstart;
	while(*(u32*)(p+48)==NES_ID) {	//count roms
		p+=*(u32*)(p+32)+48;
		i++;
	}
	roms=i;

	//load font+palette
	memcpy((void*)0x6002400,&font,16*8*32);
	memcpy((void*)0x5000080,&fontpal,64);

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

void waitframe(void) {
#ifndef __DEBUGBUILD
	while(REG_VCOUNT>=160) {};
	while(REG_VCOUNT<160) {};
#endif
}

void cls(void) {
	int i;
	u32 *scr=(u32*)SCREENBASE;
	for(i=0;i<0x200;i++)
		scr[i]=0x01200120;
	REG_BG2VOFS=0;
}

int selectedrom=0;
void rommenu(void) {
	int i,lastselected=-1;
	int key;

	oldinput=AGBinput=~REG_P1;
	cls();
	waitframe();
	REG_BLDMOD=0;
	REG_BG2CNT=0x0700;	//16color 256x256 CHRbase0 SCRbase7 Priority0
	REG_DISPCNT=BG2_EN|OBJ_1D; //mode0, 1d sprites, main screen turn on
        resetSIO(joycfg&~0xff000000);//back to 1P
	do {
		key=getinput();
		if(key&UP)
			selectedrom=(selectedrom+roms-1)%roms;
		if(key&DOWN) {
			selectedrom=(selectedrom+1)%roms;
		}
		if(lastselected!=selectedrom) {
			if(roms)
				i=drawmenu();
			else
				i=hflags;
			loadcart(selectedrom,i);
			lastselected=selectedrom;
		}
		run(0);
	} while(roms>1 && !(key&(A_BTN+B_BTN+START)));
	cls();	//leave BG2 on for debug output
	while(AGBinput&(A_BTN+B_BTN+START)) {
		AGBinput=0;
		run(0);
	}
	run(1);
}

//return ptr to Nth ROM (including rominfo struct)
u8 *findrom(int n) {
	u8 *p=textstart;
	while(n--)
		p+=*(u32*)(p+32)+48;
	return p;
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

//returns options for selected rom
int drawmenu() {
	int i,j,topline,toprow,romflags;
	u8 *p;
	rominfo *ri;

	if(roms>20) {
		topline=8*(roms-20)*selectedrom/(roms-1);
		toprow=topline/8;
		j=(toprow<roms-20)?21:20;
	} else {
		toprow=0;
		j=roms;
	}
	p=findrom(toprow);
	for(i=0;i<j;i++) {
		drawtext(i,(char*)p,i==(selectedrom-toprow)?1:0);
		if(i==selectedrom-toprow) {
			ri=(rominfo*)p;
			romflags=(*ri).flags|(*ri).spritenum<<8|(*ri).saveslot<<24;
			romflags&=~(NOSCALING+SCALESPRITES);		//keep old scaling options..
			romflags|=hflags&(NOSCALING+SCALESPRITES);
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
	static int lastupdown,repeatcount=0;
	int updown;
	int keyhit=(oldinput^AGBinput)&AGBinput;
	oldinput=AGBinput;

	updown=AGBinput&(UP+DOWN);
	if(lastupdown==updown) {
		repeatcount++;
		if(repeatcount<25 || repeatcount&3)    //delay/repeat
			updown=0;
	} else {
		repeatcount=0;
		lastupdown=updown;
	}
	*(u8*)&AGBinput=0;	//disable game input (yeah, it's dumb.  don't want to mess with L/R buttons)
	return updown|(keyhit&(A_BTN+B_BTN+START));
}
