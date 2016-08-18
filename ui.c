#include <stdio.h>
#include <string.h>

#include "gba.h"

//header files?  who needs 'em :P

void cls(void);		//from main.c
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
void debug_(int,int);		//ppu.s
void spriteinit(char);		//io.s
void suspend(void);		//io.s
//-------------------

extern u32 joycfg;	//from io.s
extern char g_scaling;	//from cart.s
extern u32 wtop;	//from ppu.s

extern int pogones;

int autoA,autoB;	//0=off, 1=on, 2=R

void autoAset(void);
void autoBset(void);
void display(void);
void loadstatemenu(void);
void savestatemenu(void);
void restart(void);
void exit(void);
void multiboot(void);
void drawshit(void);
u8 *drawstates(int);
void updatestates(int,int);
void controller(void);
void sleep(void);

void managesram(void);	//sram.c
void writeconfig(void);	//sram.c

#define POGOMENUITEMS 11 //mainmenuitems when running from cart (not multiboot)
#define CARTMENUITEMS 10 //mainmenuitems when running from cart (not multiboot)
#define MULTIBOOTMENUITEMS 7 //"" when running from multiboot
fptr fnlist[]={autoBset,autoAset,controller,display,multiboot,managesram,savestatemenu,loadstatemenu,sleep,restart,exit};
fptr multifnlist[]={autoBset,autoAset,controller,display,multiboot,sleep,restart};

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
	int key,soundvol,oldsel,tm0cnt;

	autoA=joycfg&A_BTN?0:1;
	autoA|=joycfg&(A_BTN<<16)?0:2;
	autoB=joycfg&B_BTN?0:1;
	autoB|=joycfg&(B_BTN<<16)?0:2;

	mainmenuitems=((u32)textstart>0x8000000?CARTMENUITEMS:MULTIBOOTMENUITEMS);//running from rom or multiboot?
	if(pogones)
	    mainmenuitems++;

	REG_BLDMOD=0x00f3;	//darken screen

	soundvol=REG_SGCNT0_L;
	REG_SGCNT0_L=0;		//stop sound (GB)
	tm0cnt=REG_TM0CNT;
	REG_TM0CNT=0;		//stop sound (directsound)

	oldkey=~REG_P1;		//reset key input
	selected=0;
	drawshit();
	do {
		key=getmenuinput(mainmenuitems);
		if(key&(A_BTN)) {
			oldsel=selected;
			if(mainmenuitems<CARTMENUITEMS)
				multifnlist[selected]();
			else
				fnlist[selected]();
			selected=oldsel;
		}
		if(key&(A_BTN+UP+DOWN+LEFT+RIGHT))
			drawshit();
	} while(!(key&(B_BTN+R_BTN+L_BTN)));
	writeconfig();		//save any changes
	REG_SGCNT0_L=soundvol;	//resume sound (GB)
	REG_TM0CNT=tm0cnt;	//resume sound (directsound)
	cls();
}

void text(int row,char *str) {
	drawtext(row+10-mainmenuitems/2,str,selected==row);
}


//trying to avoid using sprintf...  (takes up almost 3k!)
void strmerge(char *dst,char *src1,char *src2) {
	if(dst!=src1)
		strcpy(dst,src1);
	strcat(dst,src2);
}

char *ctrltxt[]={"1P","2P","Link2P","Link3P","Link4P"};
char *autotxt[]={"OFF","ON","with R"};
char *disptxt[]={"UNSCALED","UNSCALED (Auto)","SCALED","SCALED (w/sprites)"};
void drawshit() {
	char str[30];

	cls();
    if(pogones)
    {
	drawtext(19,"                PogoNES v9.6",0);
    }
    else
    {
	drawtext(19,"              PocketNES v9.6",0);
    }
	strmerge(str,"B autofire: ",autotxt[autoB]);
	text(0,str);
	strmerge(str,"A autofire: ",autotxt[autoA]);
	text(1,str);
	strmerge(str,"Controller: ",ctrltxt[(joycfg>>29)-2]);
	text(2,str);
	strmerge(str,"Display: ",disptxt[g_scaling&3]);
	text(3,str);
	if(mainmenuitems==MULTIBOOTMENUITEMS) {
		text(4,"Link Transfer");
		text(5,"Sleep");
		text(6,"Restart");
	} else {
		text(4,"Link Transfer");
		text(5,"Manage SRAM");
		text(6,"Save State");
		text(7,"Load State");
		text(8,"Sleep");
		text(9,"Restart");
		if(pogones)
		    text(10,"Exit");
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

void multiboot() {
	int i;
	cls();
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
    REG_BLDMOD=0;	//no dark
    __asm {mov r0,#0x3007f00} //stack reset
    __asm {mov sp,r0}
    rommenu();
}
void exit() {
    doReset();
}

void sleep() {
	suspend();
	while((~REG_P1)&0x3ff) {
		while(REG_VCOUNT>=160) {};	//wait a while
		while(REG_VCOUNT<160) {};	//(polling REG_P1 too fast seems to cause problems)
	}
}