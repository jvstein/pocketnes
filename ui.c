#include <stdio.h>
#include <string.h>
#include "gba.h"
#include "minilzo.107/minilzo.h"

#define STATEID 0x57a731d7

extern u8 Image$$RO$$Limit;

//header files?  BAH! who needs em

void cls(void);		//from main.c
void rommenu(void);
void drawtext(int,char*,int);
u8 *findrom(int);
char *findname(int);
int readtitle(char *src,char *dst);
extern char *textstart;
extern int roms;

void debug_(int,int);	//from ppu.s
int savestate(void*);	//from cart.s
void loadstate(int,void*);	//this too..
void spriteinit(int);	//io.s
void suspend(void);	//io.s

extern u32 joycfg;	//from io.s
extern u32 hflags;	//from cart.s
extern u8 *romstart;	//from cart.s
extern u32 romnum;	//from cart.s
extern u32 wtop;	//from ppu.s
extern u32 frametotal;	//from 6502.s

int autoA,autoB;	//0=off, 1=on, 2=R
int scaling;		//0=scaled, 1=scaled (big sprites), 2=not scaled

void autoAset(void);
void autoBset(void);
void display(void);
void loadstatemenu(void);
void savestatemenu(void);
void restart(void);
void drawshit(void);
u8 *drawstates(int);
void updatestates(int,int);
void p1p2(void);
void sleep(void);

typedef void (*fptr)(void);
fptr fnlist[]={autoBset,autoAset,p1p2,display,savestatemenu,loadstatemenu,sleep,restart};
fptr multifnlist[]={autoBset,autoAset,p1p2,display,sleep,restart};

int selected;//selected menuitem.  used by all menus.
#define CARTMENUITEMS 8 //mainmenuitems when running from cart (not multiboot)
int mainmenuitems;//6 or CARTMENUITEMS, depending on whether saving is allowed

u32 oldkey;//init this before using getmenuinput
u32 getmenuinput(int menuitems) {
	u32 keyhit;
	u32 tmp;

	while(REG_VCOUNT>=160) {};	//wait a while
	while(REG_VCOUNT<160) {};	//(polling REG_P1 too fast seems to cause problems)
	tmp=~REG_P1;
	keyhit=(oldkey^tmp)&tmp;
	oldkey=tmp;
	if(keyhit&UP)
		selected=(selected+menuitems-1)%menuitems;
	if(keyhit&DOWN)
		selected=(selected+1)%menuitems;
	if((oldkey&(L_BTN+R_BTN))!=L_BTN+R_BTN)
		keyhit|=R_BTN;		//flag L+R not held
	return keyhit;
}

void ui() {
	int key,soundvol;

	autoA=joycfg&A_BTN?0:1;
	autoA|=joycfg&(A_BTN<<16)?0:2;
	autoB=joycfg&B_BTN?0:1;
	autoB|=joycfg&(B_BTN<<16)?0:2;
	if(hflags&NOSCALING)
		scaling=2;
	else if(hflags&SCALESPRITES)
		scaling=0;
	else
		scaling=1;

	mainmenuitems=((u32)textstart>0x8000000?CARTMENUITEMS:6);//running from rom or multiboot?

	REG_BLDMOD=0x00f3;	//darken screen
	REG_COLY=0x0006;

	soundvol=REG_SGCNT0_L;
	REG_SGCNT0_L=0;		//stop sound

	oldkey=~REG_P1;		//reset key input
	selected=0;
	drawshit();
	do {
		key=getmenuinput(mainmenuitems);
		if(key&(A_BTN+B_BTN)) {
			if(mainmenuitems<CARTMENUITEMS)
				multifnlist[selected]();
			else
				fnlist[selected]();
		}
		if(key&(A_BTN+B_BTN+UP+DOWN))
			drawshit();
	} while(!(key&R_BTN));
	REG_BLDMOD=0;	//no dark
	REG_SGCNT0_L=soundvol;	//resume sound
	cls();
}

void text(int row,char *str) {
	drawtext(row+10-mainmenuitems/2,str,selected==row);
}

char *autotxt[]={"OFF","ON","with R"};
char *disptxt[]={"SCALED (BG+SPR)","SCALED (BG)","UNSCALED"};
void drawshit() {
	char str[30];

	cls();
	drawtext(19,"                PocketNES v7",0);
	sprintf(str,"B autofire: %s",autotxt[autoB]);
	text(0,str);
	sprintf(str,"A autofire: %s",autotxt[autoA]);
	text(1,str);
	sprintf(str,"Controller: %iP",(joycfg>>31)+1);
	text(2,str);
	sprintf(str,"Display: %s",disptxt[scaling]);
	text(3,str);
	if(mainmenuitems<CARTMENUITEMS) {
		text(4,"Sleep");
		text(5,"Restart");
	} else {
		text(4,"Save State");
		text(5,"Load State");
		text(6,"Sleep");
		text(7,"Restart");
	}
}

void autoAset() {
	autoA++;
	joycfg|=A_BTN+(A_BTN<<16);
	if(autoA==1)
		joycfg&=~A_BTN;
	else if(autoA==2)
		joycfg&=~(A_BTN<<16);
	else
		autoA=0;
}

void autoBset() {
	autoB++;
	joycfg|=B_BTN+(B_BTN<<16);
	if(autoB==1)
		joycfg&=~B_BTN;
	else if(autoB==2)
		joycfg&=~(B_BTN<<16);
	else
		autoB=0;
}

void p1p2() {
	joycfg^=0x80000000;
}

void display() {
	wtop=0;
	scaling++;
	hflags&=~(NOSCALING+SCALESPRITES);
	if(scaling==3) {
		hflags|=SCALESPRITES;
		scaling=0;
	} else if(scaling==2) {
		hflags|=NOSCALING;
	}
	spriteinit(hflags);
}

void restart() {
	REG_BLDMOD=0;	//no dark
	__asm {mov sp,#0x3007f00} //stack reset
	rommenu();
}

void sleep() {
	suspend();
	while((~REG_P1)&0x3ff) {
		while(REG_VCOUNT>=160) {};	//wait a while
		while(REG_VCOUNT<160) {};	//(polling REG_P1 too fast seems to cause problems)
	}
}

//savestate format:
//STATEID
//----
//statesize (header+data)
//compresseddatasize
//frame count
//checksum
//title[32]
//compressed state
//(word align)
//----
//0

#define STATEHEADERSIZE 48
#define COMPRESSEDDATASIZE 1
#define FRAMECOUNT 2
#define CHECKSUM 3
#define STATETITLE 4

//we have a big chunk of memory starting at Image$$RO$$Limit free to use
#define BUFFER1 (&Image$$RO$$Limit)
#define BUFFER2 (&Image$$RO$$Limit+0x10000)
#define BUFFER3 (&Image$$RO$$Limit+0x20000)
#define MAXSTATES 14
void getsram() {		//copy sram to ram (BUFFER1)
	u8 *sram=MEM_SRAM;
	u8 *p=BUFFER1;
	int i;
	for(i=0;i<65536;i++)
		p[i]=sram[i];
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

int states;		//current number of savestates
int totalstatesize;	//size of savestate data
			//these are updated by drawstates().  yes, i know it's sloppy.  stop whining.
void savestatemenu() {
	lzo_uint statesize;
	u32 *p;
	int i;

	statesize=savestate(BUFFER2);		//copy uncompressed state into p2
	lzo1x_1_compress(BUFFER2,statesize,BUFFER3+STATEHEADERSIZE,&statesize,BUFFER1);	//compress state into p3

	//setup new state header:
	p=(u32*)BUFFER3;
	*p=(statesize+STATEHEADERSIZE+3)&~3;	//size of compressed state+header, word aligned
	p++;
	*p=statesize;		//size of compressed state
	p++;
	*p=frametotal;		//elapsed time
	p++;
	*p=checksum((u8*)romstart);	//checksum
	p++;
	readtitle(findname(romnum),(char*)p);

	getsram();

	p=(u32*)BUFFER1;
	if(*p!=STATEID) {	//unrecognized savestate format
		p[0]=STATEID;
		p[1]=0;
	}

	selected=0;
	drawstates(1);
	do {
		i=getmenuinput(states+(states<=MAXSTATES));
		if(i&(A_BTN+B_BTN))
			updatestates(selected,0);
		if((i&SELECT) && selected<states)
			updatestates(selected,1);
		if(i&(SELECT+UP+DOWN))
			drawstates(1);
	} while(!(i&(R_BTN+A_BTN+B_BTN)));
	selected=0;
}

void loadstatemenu() {
	lzo_uint statesize;
	u32 *p;
	u32 key;
	int i;
	u32 sum;

	getsram();

	p=(u32*)BUFFER1;
	if(*p!=STATEID)		//no savestate data?
		return;

	selected=0;
	p=(u32*)drawstates(0);
	if(!states)
		return;		//nothing to load!
	do {
		key=getmenuinput(states);
		if(key&(A_BTN+B_BTN)) {
			sum=*(p+CHECKSUM);
			i=0;
			do {
				if(sum==checksum(findrom(i)+16)) {
					statesize=*(p+COMPRESSEDDATASIZE);
					lzo1x_decompress((u8*)(p+STATEHEADERSIZE/4),statesize,BUFFER2,&statesize,NULL);
					loadstate(i,BUFFER2);
					frametotal=*(p+FRAMECOUNT);
					i=8192;
				}
				i++;
			} while(i<roms);
			if(i<8192) {
				cls();
				drawtext(9,"       ROM not found.",0);
				for(i=0;i<60;i++)	//(1 second wait)
					getmenuinput(1);
			}
		}
		if(key&(UP+DOWN))
			p=(u32*)drawstates(0);
	} while(!(key&(R_BTN+A_BTN+B_BTN)));
	selected=0;
}

//overwrite state:  index=state#, erase=0
//new state:  index=states, erase=0
//erase state:  index=state#, erase=1
void updatestates(int index,int erase) {
	int state;
	int i,j;
	u8 *dst=BUFFER1;
	u8 *src=BUFFER2;
	u8 *sram=MEM_SRAM;

	memcpy(src,dst,0x10000);		//buffer1 to buffer2
						//(buffer1=new, buffer2=old)
	src+=4;
	dst+=4;	//skip STATEID

	for(state=0;state<index;state++) {		//skip ahead
		dst+=*(u32*)src;
		src+=*(u32*)src;
	}
	if(!erase) {
		i=*(u32*)BUFFER3;	//i=state size
		if(totalstatesize+i-*(u32*)src>0x10000) {//**OUT OF MEMORY**
			cls();
			drawtext(9,"       Memory full!!",0);
			drawtext(10,"     Delete some games",0);
			for(j=0;j<60;j++)	//(1 second wait)
				getmenuinput(1);
			return;
		}
		memcpy(dst,BUFFER3,i);	//overwrite
		dst+=i;
	}
	src+=*(u32*)src;
	for(state++;state<states;state++) {			//finish up
		i=*(u32*)src;
		memcpy(dst,src,i);
		dst+=i;
		src+=i;
	}
	*(u32*)dst=0;			//terminate

	src=BUFFER1;
	for(i=0;i<65536;i++)			//copy to sram
		sram[i]=src[i];
}

#define YPOS 2
//draw save/loadstate menu and update global states,totalstatesize vars
//returns a pointer to current selected state
u8 *drawstates(int saving) {
	int n;
	char s[30];
	u8 *p=BUFFER1+4;
	u8 *selectedp;
	int time;

	cls();
	states=0;
	totalstatesize=8;	//STATEID+null
	while(*(u32*)p) {//while state size>0
		drawtext(states+YPOS,(char*)p+STATETITLE*4,selected==states);
		if(selected==states) {
			time=*(u32*)(p+FRAMECOUNT*4);
			selectedp=p;
		}
		n=*(u32*)p;
		states++;
		totalstatesize+=n;
		p+=n;
	}
	if(saving) {
		if(states<=MAXSTATES)
			drawtext(states+YPOS,"<NEW>",selected==states);
		drawtext(0,"Save state:",0);
		if(states)
			drawtext(19,"Push SELECT to delete",0);
	} else {
		drawtext(0,"Load state:",0);
	}
	if(selected!=states) {//not <NEW>
		sprintf(s,"%02i:%02i:%02i",time/216000,(time/3600)%60,(time/60)%60);
		drawtext(18,s,0);
	}
	return selectedp;
}
