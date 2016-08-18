#include <stdio.h>
#include "gba.h"

void cls(void);		//from main.c
void rommenu(void);
void drawtitle(int,char*,int);

void savestate(void);	//from cart.s
void loadstate(void);	//this too..
void spriteinit(int);	//io.s

extern u32 automask;	//from io.s
extern u32 hflags;	//from cart.s
extern u32 wtop;	//from ppu.s
int autoA,autoB;	//0=off, 1=on, 2=R

void autoAset(void);
void autoBset(void);
void display(void);
void state_save(void);
void state_load(void);
void restart(void);
void drawshit(void);

#define MENUITEMS 6
typedef void (*fptr)(void);
fptr list[]={autoBset,autoAset,display,state_save,state_load,restart};

int selected;
void ui() {
	int keypad,keyhit,tmp,soundvol;

	autoA=automask&A_BTN?0:1;
	autoA|=automask&(A_BTN<<16)?0:2;
	autoB=automask&B_BTN?0:1;
	autoB|=automask&(B_BTN<<16)?0:2;

	REG_BLDMOD=0x00f3;	//darken screen
	REG_COLY=0x0006;

	soundvol=REG_SGCNT0_L;
	REG_SGCNT0_L=0;		//stop sound

	keypad=~REG_P1;
	cls();
	selected=0;
	drawshit();
	drawtitle(19,"                PocketNES v6",0);
	do {
		while(REG_VCOUNT>=160) {};	//wait a while
		while(REG_VCOUNT<160) {};	//(polling REG_P1 too fast seems to cause problems)
		tmp=~REG_P1;
		keyhit=(keypad^tmp)&tmp;
		keypad=tmp;
		if(keyhit&UP)
			selected=(selected+MENUITEMS-1)%MENUITEMS;
		if(keyhit&DOWN)
			selected=(selected+1)%MENUITEMS;
		if(keyhit&(A_BTN+B_BTN))
			list[selected]();
		if(keyhit&(A_BTN+B_BTN+UP+DOWN))
			drawshit();
	} while((keypad&(L_BTN+R_BTN))==L_BTN+R_BTN);
	REG_BLDMOD=0;	//no dark
	REG_SGCNT0_L=soundvol;	//resume sound
	cls();
}

void text(int row,char *str) {
	drawtitle(row+10-MENUITEMS/2,str,selected==row);
}

char *autotxt[]={"OFF","ON","with R"};
char *disptxt[]={"SCALED","UNSCALED"};
void drawshit() {
	char str[30];

	sprintf(str,"B autofire: %s",autotxt[autoB]);
	text(0,str);
	sprintf(str,"A autofire: %s",autotxt[autoA]);
	text(1,str);
	sprintf(str,"Display: %s",disptxt[hflags&NOSCALING?1:0]);
	text(2,str);
	text(3,"Save State");
	text(4,"Load State");
	text(5,"Restart");
}

void autoAset() {
	autoA++;
	automask|=A_BTN+(A_BTN<<16);
	if(autoA==1)
		automask&=~A_BTN;
	else if(autoA==2)
		automask&=~(A_BTN<<16);
	else
		autoA=0;
}

void autoBset() {
	autoB++;
	automask|=B_BTN+(B_BTN<<16);
	if(autoB==1)
		automask&=~B_BTN;
	else if(autoB==2)
		automask&=~(B_BTN<<16);
	else
		autoB=0;
}

void display() {
	hflags^=NOSCALING;
	wtop=0;
	spriteinit(hflags);
}

void state_save() {
	savestate();
	selected=0;
}

void state_load() {
	loadstate();
	selected=0;
}

void restart() {
	REG_BLDMOD=0;	//no dark
	__asm {mov sp,#0x3007f00}
	rommenu();
}