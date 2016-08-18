#include <stdio.h>
#include <string.h>
#include "gba.h"

//#define HEAPBASE 0x2030000
//#define HEAPSIZE 0x?

extern u32 font;
extern u32 fontpal;
extern u32 AGBinput;	//from ppu.s
       u32 oldinput;

//asm calls
void loadcart(void *romaddr,int flags);
void run(int);
void ppu_init(void);
s32 (*emul8)(int) = (s32 (*)(int))run;

void rommenu(void);
void *findrom(int);
int drawmenu(void);
int getinput(void);

/*
void *__rt_embeddedalloc_init(void *base, unsigned int size);
void *heapdescriptor;
void *__rt_heapdescriptor(void) {
	return heapdescriptor;
}*/

const unsigned __fp_status_arm=0x40070000;
int roms;//# of roms
char *textstart;//where rom descriptions reside (initialized by boot.s)
u8 *romstart;//1st rom ptr

void C_entry() {
	char *str,*str2;

	//heapdescriptor=__rt_embeddedalloc_init((void*)HEAPBASE,HEAPSIZE);

	//load font+palette
	memcpy((void*)0x6002400,&font,16*8*32);
	memcpy((void*)0x5000080,&fontpal,64);

	ppu_init();

	//count # of titles
	roms=0;
	while(*textstart<' ') textstart++;//kill stray CRs
	str2=str=textstart;
	while(*str!=0x4e || *(str+1)!=0x45 || *(str+2)!=0x53 || *(str+3)!=0x1a) { //iNES header
		str=strchr(str,'\n');
		while(*str<' ') str++;
		if(*str2!='#')
			roms++;
		str2=str;
	}
	romstart=(u8*)str;
	rommenu();
}

void cls(void) {
	int i;
	u32 *scr=(u32*)SCREENBASE;
	for(i=0;i<0x200;i++)
		scr[i]=0x01000100;
	REG_BG2VOFS=0;
}

int selectedrom=0;
void rommenu(void) {
	int i,lastselected=-1;
	int key;

	oldinput=AGBinput=~REG_P1;
	cls();
	REG_BG2CNT=0x0700;	//16color 256x256 CHRbase0 SCRbase7 Priority0
	REG_DISPCNT=BG2_EN|OBJ_1D; //mode0, 1d sprites, main screen turn on
	do {
		key=getinput();
		if(key&UP)
			selectedrom=(selectedrom+roms-1)%roms;
		if(key&DOWN) {
			selectedrom=(selectedrom+1)%roms;
		}
		if(lastselected!=selectedrom) {
			i=drawmenu();
			loadcart(findrom(selectedrom),i);
			lastselected=selectedrom;
		}
		(*emul8)(0);
	} while(roms>1 && !(key&(A_BTN+B_BTN+START)));
	cls();	//leave BG2 on for debug output
	while(AGBinput&(A_BTN+B_BTN+START)) {
		AGBinput=0;
		(*emul8)(0);
	}
	(*emul8)(1);
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

//return ptr to Nth ROM
void *findrom(int n) {
	u32 prgsize,chrsize;
	u8 *p=romstart;
	while(n--) {
		prgsize=*(p+4);
		chrsize=*(p+5);
		p=p+16+prgsize*16384+chrsize*8192;
		if(*p!=0x4e||*(p+1)!=0x45||*(p+2)!=0x53||*(p+3)!=0x1a)
			return romstart;
	}
	return p;
}

void drawtitle(int row,char *str,int hilite) {
	u16 *here=SCREENBASE+row*32;
	int i=0;

	*here=hilite?0x412a:0x4120;
	hilite=(hilite<<12)+0x4100;
	here++;
	while(str[i]) {
		here[i]=str[i]|hilite;
		i++;
	}
	for(;i<29;i++)
		here[i]=0x0120;
}

char *getline(int i) {
	char *s=textstart;
	if(*s=='#') i++;//need this if first line is a comment
	while(i--)
		nexttitle(&s);
	return s;
}

//returns options for selected rom
int drawmenu() {
	int i,j,topline,toprow,hackflags,allflags,saveslot,spritenum;
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
	s=getline(toprow);
	for(i=0;i<j;i++) {
		hackflags=spritenum=saveslot=0;
		sscanf(s,"%29[^|\n]%*[^|\n]|%i|%i|%i\n",title,&hackflags,&spritenum,&saveslot);
		nexttitle(&s);
		drawtitle(i,title,i==(selectedrom-toprow)?1:0);
		if(i==selectedrom-toprow)
			allflags=hackflags|(spritenum<<8)|(saveslot<<24);
	}
	if(roms>20)
		REG_BG2VOFS=topline%8;
	else
		REG_BG2VOFS=176+roms*4;
	return allflags;
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