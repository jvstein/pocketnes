#include <stdio.h>
#include <string.h>
#include "gba.h"
#include "minilzo.107/minilzo.h"

//#define HEAPBASE 0x2030000
//#define HEAPSIZE 0x?

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

void rommenu(void);
int drawmenu(void);
int getinput(void);
int ines(u8 *p);
void splash(void);
void waitframe(void);

/*
void *__rt_embeddedalloc_init(void *base, unsigned int size);
void *heapdescriptor;
void *__rt_heapdescriptor(void) {
	return heapdescriptor;
}*/

const unsigned __fp_status_arm=0x40070000;
int roms;//total # of roms (# of menu titles found)
char *textstart;//where rom descriptions reside (initialized by boot.s)
u8 *firstrom;//1st rom ptr

void C_entry() {
	char *str,*str2;

	REG_DISPCNT=FORCE_BLANK;	//screen OFF

	//heapdescriptor=__rt_embeddedalloc_init((void*)HEAPBASE,HEAPSIZE);

	lzo_init();	//init compression lib for savestates

	//"#!" in menu indicates a splash screen is present
	if(*(textstart+76800)=='#' && *(textstart+76801)=='!') {
		splash();
		textstart+=76800;
	}

	ppu_init();

	//count # of titles
	roms=0;
	while(*textstart<' ') textstart++;//kill stray CRs
	str2=str=textstart;
	while(!ines((u8*)str)) { //look for first NES header
		str=strchr(str,'\n');
		while(*str<' ') str++;
		if(*str2!='#')
			roms++;
		str2=str;
	}
	firstrom=(u8*)str;

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
	for(i=0;i<120;i++) {	//wait 2 seconds
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
        joycfg&=0x7fffffff;       //switch back to 1P
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

//advance str to next rom title
void nexttitle(char **str) {
	char *s=*str;
	do {
		s=strchr(s,'\n');
		while(*s<' ') s++;
	} while(*s=='#');
	*str=s;
}

//check for iNES ID
int ines(u8 *p) {
	return (*p==0x4e && *(p+1)==0x45 && *(p+2)==0x53 && *(p+3)==0x1a);
}

//return ptr to Nth ROM (including NES header)
u8 *findrom(int n) {
	u32 prgsize,chrsize;
	u8 *p=firstrom;
	while(n--) {
		prgsize=*(p+4);
		chrsize=*(p+5);
		p=p+16+prgsize*16384+chrsize*8192;
		if(!ines(p))
			p+=128;
		if(!ines(p))
			return firstrom;
	}
	return p;
}

//return ptr to rom title
char *findname(int i) {
	char *s=textstart;
	if(i>roms-1)
		return "?";
	if(*s=='#') i++;//need this if first line is a comment
	while(i--)
		nexttitle(&s);
	return s;
}

//parse rom info string.  copy title into dst, return rom options
int readtitle(char *src,char *dst) {
	int hackflags,spritenum,saveslot;
	hackflags=spritenum=saveslot=0;
	sscanf(src,"%29[^|\n]%*[^|\n]|%i|%i|%i\n",dst,&hackflags,&spritenum,&saveslot);
	hackflags&=~(NOSCALING+SCALESPRITES);		//keep old scaling options..
	hackflags|=hflags&(NOSCALING+SCALESPRITES);
	return hackflags|(spritenum<<8)|(saveslot<<24);
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
	int i,j,topline,toprow,romflags,tmpflags;
	char *s;
	char title[30];

	if(roms>20) {
		topline=8*(roms-20)*selectedrom/(roms-1);
		toprow=topline/8;
		j=(toprow<roms-20)?21:20;
	} else {
		toprow=0;
		j=roms;
	}
	s=findname(toprow);
	for(i=0;i<j;i++) {
		tmpflags=readtitle(s,title);
		nexttitle(&s);
		drawtext(i,title,i==(selectedrom-toprow)?1:0);
		if(i==selectedrom-toprow)
			romflags=tmpflags;
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
	AGBinput=0;	//disable game input
	return updown|(keyhit&(A_BTN+B_BTN+START));
}
