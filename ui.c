#include <stdio.h>
#include <string.h>

#include "gba.h"

//header files?  who needs 'em :P

void cls(int);		//from main.c
void rommenu(void);
void drawtext(int,char*,int);
void waitframe(void);
extern char *textstart;

void backup_nes_sram(void); //from sram.c
void clearconfig(void);
void clean_nes_sram(void);

int SendMBImageToClient(void);	//mbclient.c

//----asm calls------
void resetSIO(u32);		//io.s
void doReset(void);		//io.s
void debug_(int,int);	//ppu.s
void spriteinit(char);	//io.s
void suspend(void);		//io.s
int gettime(void);		//io.s
//-------------------

extern u32 joycfg;			//from io.s
extern u32 g_emuflags;		//from cart.s
extern char g_scaling;		//from cart.s
extern char novblankwait;	//from 6502.s
extern u32 sleeptime;		//from 6502.s
extern u32 wtop;			//from ppu.s
extern u32 FPSValue;		//from ppu.s
extern char twitch;			//from ppu.s
extern char flicker;		//from ppu.s
extern char fpsenabled;		//from ppu.s

extern int rtc;
extern int pogones;
extern int gameboyplayer;

int autoA,autoB;	//0=off, 1=on, 2=R
u8 stime=0;

void autoAset(void);
void autoBset(void);
void display(void);
void loadstatemenu(void);
void savestatemenu(void);
void vblset(void);
void restart(void);
void exit(void);
void multiboot(void);
void drawshit(void);
void drawclock(void);
void drawui2(void);
void subui(void);
void scrolll(void);
void scrollr(void);
void controller(void);
void sleep(void);
void sleepset(void);
void flickset(void);
void fpsset(void);
void bajs(void);
void fadetowhite(void);

void managesram(void);	//sram.c
void writeconfig(void);	//sram.c

#define MENU2ITEMS 4		//menu2items
#define CARTMENUITEMS 12 //mainmenuitems when running from cart (not multiboot)
#define MULTIBOOTMENUITEMS 8 //"" when running from multiboot
fptr fnlist1[]={autoBset,autoAset,controller,display,subui,multiboot,managesram,savestatemenu,loadstatemenu,sleep,restart,exit};
fptr fnlist2[]={vblset,sleepset,fpsset,flickset,bajs};
fptr multifnlist[]={autoBset,autoAset,controller,display,subui,multiboot,sleep,restart};

int selected;//selected menuitem.  used by all menus.
int mainmenuitems;//? or CARTMENUITEMS, depending on whether saving is allowed

u32 oldkey;//init this before using getmenuinput
u32 getmenuinput(int menuitems) {
	u32 keyhit;
	u32 tmp;
	int sel=selected;

	waitframe();		//(polling REG_P1 too fast seems to cause problems)
	tmp=~REG_P1;
	keyhit=(oldkey^tmp)&tmp;
	oldkey=tmp;
	if(keyhit&UP)
		sel=(sel+menuitems-1)%menuitems;
	if(keyhit&DOWN)
		sel=(sel+1)%menuitems;
	if(keyhit&RIGHT) {
		sel+=10;
		if(sel>menuitems-1) sel=menuitems-1;
	}
	if(keyhit&LEFT) {
		sel-=10;
		if(sel<0) sel=0;
	}
	if((oldkey&(L_BTN+R_BTN))!=L_BTN+R_BTN)
		keyhit&=~(L_BTN+R_BTN);
	selected=sel;
	return keyhit;
}

void ui() {
	int key,soundvol,oldsel,tm0cnt,i;

	autoA=joycfg&A_BTN?0:1;
	autoA|=joycfg&(A_BTN<<16)?0:2;
	autoB=joycfg&B_BTN?0:1;
	autoB|=joycfg&(B_BTN<<16)?0:2;

	mainmenuitems=((u32)textstart>0x8000000?CARTMENUITEMS:MULTIBOOTMENUITEMS);//running from rom or multiboot?
	FPSValue=0;			//Stop FPS meter

	soundvol=REG_SGCNT0_L;
	REG_SGCNT0_L=0;		//stop sound (GB)
	tm0cnt=REG_TM0CNT;
	REG_TM0CNT=0;		//stop sound (directsound)

	REG_BG2HOFS=0x0100;	//Screen left
	selected=0;
	drawshit();
	REG_BLDCNT=0x00f3;	//darken screen
	REG_COLY=0x0000;	//set normal blending
	for(i=0;i<8;i++)
	{
		waitframe();
		REG_COLY=i;		//Darken screen
		REG_BG2HOFS=224-i*32;	//Move screen right
	}

	oldkey=~REG_P1;			//reset key input
	do {
		drawclock();
		key=getmenuinput(mainmenuitems);
		if(key&(A_BTN)) {
			oldsel=selected;
			if(mainmenuitems<CARTMENUITEMS)
				multifnlist[selected]();
			else
				fnlist1[selected]();
			selected=oldsel;
		}
		if(key&(A_BTN+UP+DOWN+LEFT+RIGHT))
			drawshit();
	} while(!(key&(B_BTN+R_BTN+L_BTN)));
	writeconfig();		//save any changes
	for(i=0;i<8;i++)
	{
		REG_COLY=7-i;		//Lighten screen
		REG_BG2HOFS=i*32;	//Move screen left
		waitframe();
	}
	REG_BG2HOFS=0x0100;		//Screen left
	while(key&(B_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
	REG_SGCNT0_L=soundvol;	//resume sound (GB)
	REG_TM0CNT=tm0cnt;	//resume sound (directsound)
	cls(3);
}

void subui() {
	int key,oldsel;

	selected=0;
	drawui2();
	scrolll();
	oldkey=~REG_P1;			//reset key input
	do {
		key=getmenuinput(MENU2ITEMS);
		if(key&(A_BTN)) {
			oldsel=selected;
			fnlist2[selected]();
			selected=oldsel;
		}
		if(key&(A_BTN+UP+DOWN+LEFT+RIGHT))
			drawui2();
	} while(!(key&(B_BTN+R_BTN+L_BTN)));
	scrollr();
	while(key&(B_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
}

void text(int row,char *str) {
	drawtext(row+10-mainmenuitems/2,str,selected==row);
}
void text2(int row,char *str) {
	drawtext(35+row+2,str,selected==row);
}


//trying to avoid using sprintf...  (takes up almost 3k!)
void strmerge(char *dst,char *src1,char *src2) {
	if(dst!=src1)
		strcpy(dst,src1);
	strcat(dst,src2);
}

char *ctrltxt[]={"1P","2P","Link2P","Link3P","Link4P"};
char *autotxt[]={"OFF","ON","with R"};
char *vsynctxt[]={"ON","OFF","SLOWMO"};
char *disptxt[]={"UNSCALED","UNSCALED (Auto)","SCALED","SCALED (w/sprites)"};
char *sleeptxt[]={"5min","10min","30min","OFF"};
char *cntrtxt[]={"US (NTSC)","Europe (PAL)"};
char *flicktxt[]={"No Flicker","Flicker"};
void drawshit() {
	char str[30];

	cls(1);
	if(pogones){
		drawtext(19,"                PogoNES v9.93",0);}
	else{
		if(gameboyplayer){
			drawtext(19,"       PocketNES v9.93 on GBP",0);}
		else{
			drawtext(19,"              PocketNES v9.93",0);}
	}
	strmerge(str,"B autofire: ",autotxt[autoB]);
	text(0,str);
	strmerge(str,"A autofire: ",autotxt[autoA]);
	text(1,str);
	strmerge(str,"Controller: ",ctrltxt[(joycfg>>29)-2]);
	text(2,str);
	strmerge(str,"Display: ",disptxt[g_scaling&3]);
	text(3,str);
	text(4,"Settings->");
	text(5,"Link Transfer");
	if(mainmenuitems==MULTIBOOTMENUITEMS) {
		text(6,"Sleep");
		text(7,"Restart");
	} else {
		text(6,"Manage SRAM");
		text(7,"Save State");
		text(8,"Load State");
		text(9,"Sleep");
		text(10,"Restart");
		text(11,"Exit");
	}
}

void drawui2() {
	char str[30];

	cls(2);
	drawtext(32,"       Other Settings",0);
	strmerge(str,"VSync: ",vsynctxt[novblankwait]);
	text2(0,str);
	strmerge(str,"Autosleep: ",sleeptxt[stime]);
	text2(1,str);
	strmerge(str,"FPS-Meter: ",autotxt[fpsenabled]);
	text2(2,str);
	strmerge(str,"Scaling: ",flicktxt[flicker]);
	text2(3,str);
	strmerge(str,"Region: ",cntrtxt[(g_emuflags & 4)>>2]);		//USCOUNTRY=4
	text2(4,str);
}

void drawclock() {

    char str[30];
    char *s=str+20;
    int timer,mod;

    if(rtc)
    {
	strcpy(str,"                    00:00:00");
	timer=gettime();
	mod=(timer>>4)&3;		//Hours.
	*(s++)=(mod+'0');
	mod=(timer&15);
	*(s++)=(mod+'0');
	s++;
	mod=(timer>>12)&15;
	*(s++)=(mod+'0');
	mod=(timer>>8)&15;
	*(s++)=(mod+'0');
	s++;
	mod=(timer>>20)&15;
	*(s++)=(mod+'0');
	mod=(timer>>16)&15;
	*(s++)=(mod+'0');

	drawtext(0,str,0);
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

void controller() {		//see io.s: refreshNESjoypads
	u32 i=joycfg+0x20000000;
	if(i>=0xe0000000)
		i-=0xa0000000;
	resetSIO(i);		//reset link state
}

void display() {
	char sc;
	wtop=0;
	g_scaling=sc=(g_scaling+1)&3;
	spriteinit(sc);
}

void sleepset() {
	stime++;
	if(stime==1)
		sleeptime=60*60*10;			// 10min
	else if(stime==2)
		sleeptime=60*60*30;			// 30min
	else if(stime==3)
		sleeptime=0x7F000000;		// 360days...
	else if(stime>=4){
		sleeptime=60*60*5;			// 5min
		stime=0;
	}
}

void vblset() {
	novblankwait++;
	if(novblankwait>=3)
		novblankwait=0;
}

void flickset() {
	flicker++;
	if(flicker > 1){
		flicker=0;
		twitch=0;
	}
}

void fpsset() {
	fpsenabled++;
	if(fpsenabled > 1){
		fpsenabled=0;
	}
}

void multiboot() {
	int i;
	cls(1);
	drawtext(9,"          Sending...",0);
	i=SendMBImageToClient();
	if(i) {
		if(i<3)
			drawtext(9,"         Link error.",0);
		else
			drawtext(9,"  Game is too big to send.",0);
		if(i==2) drawtext(10,"       (Check cable?)",0);
		for(i=0;i<90;i++)		//wait a while
			waitframe();
	}
}

void restart() {
    writeconfig();		//save any changes
	scrolll();
    REG_BLDCNT=0;		//no dark
    __asm {mov r0,#0x3007f00}	//stack reset
    __asm {mov sp,r0}
    rommenu();
}
void exit() {
	writeconfig();		//save any changes
	fadetowhite();
	REG_DISPCNT=FORCE_BLANK;	//screen OFF
	REG_BG0HOFS=0;
	REG_BG0VOFS=0;
	REG_BLDCNT=0;		//no blending
	doReset();
}

void sleep() {
	fadetowhite();
	suspend();
	REG_BLDCNT=0x00f3;	//restore screen
	REG_COLY=7;		//restore screen
	while((~REG_P1)&0x3ff) {
		while(REG_VCOUNT>=160) {};	//wait a while
		while(REG_VCOUNT<160) {};	//(polling REG_P1 too fast seems to cause problems)
	}
}
void fadetowhite() {
	int i;
	REG_BLDCNT=0x00f3;	//darken screen
	for(i=7;i>=0;i--)
	{
		REG_COLY=i;	//go from dark to normal
		waitframe();
	}
	REG_BLDCNT=0xbf;	//(brightness increase)
	for(i=0;i<17;i++) {	//fade to white
		REG_COLY=i;
		waitframe();
	}
}

void scrolll() {
	int i;
	for(i=0;i<9;i++)
	{
		waitframe();
		REG_BG2HOFS=i*32;	//Move screen left
	}
}
void scrollr() {
	int i;
	for(i=8;i>=0;i--)
	{
		waitframe();
		REG_BG2HOFS=i*32;	//Move screen left
	}
	cls(2);					//Clear BG2
}

void bajs(){
}

