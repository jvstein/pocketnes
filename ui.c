#define EDITFOLLOW 1
#define BRANCHHACKDETAIL 1

#include "gba.h"

#include <stdio.h>
#include <string.h>
#include "main.h"
#include "asmcalls.h"
#include "ui.h"
#include "sram.h"
#include "mbclient.h"

u8 autoA,autoB;				//0=off, 1=on, 2=R
u8 stime=0;
u8 autostate=0;

#define cf_getbit(i) bits[i>>5]&(1<<(31-(i&31)))
#define cf_togglebit(i) bits[i>>5]^=1<<(31-(i&31))


int selected;//selected menuitem.  used by all menus.
int mainmenuitems;//? or CARTMENUITEMS, depending on whether saving is allowed

u32 oldkey;

/*
//header files?  who needs 'em :P

void cls(int);		//from main.c
void rommenu(void);
void drawtext(int,char*,int);
void setdarknessgs(int dark);
void setbrightnessall(int light);
extern char *textstart;


//----asm calls------
void run(int);
void resetSIO(u32);			//io.s
void doReset(void);			//io.s
void suspend(void);			//io.s
void waitframe(void);		//io.s
int gettime(void);			//io.s
void spriteinit(char);		//io.s
void debug_(int,int);		//ppu.s
void paletteinit(void);		//ppu.s
void PaletteTxAll(void);	//ppu.s
void Update_Palette(void);	//ppu.s
//-------------------

extern u32 joycfg;			//from io.s
extern u32 g_emuflags;		//from cart.s
extern char g_scaling;		//from cart.s
extern char novblankwait;	//from 6502.s
extern u32 sleeptime;		//from 6502.s
extern char dontstop;		//from 6502.s
extern u32 FPSValue;		//from ppu.s
extern char fpsenabled;		//from ppu.s
extern char gammavalue;		//from ppu.s
extern char twitch;			//from ppu.s
extern char flicker;		//from ppu.s
extern u32 wtop;			//from ppu.s

extern char rtc;
extern char pogoshell;
extern char gameboyplayer;
extern char gbaversion;
extern char g_hackflags;      //from cart.s
extern char g_hackflags2;      //from cart.s
extern char g_mappernumber;

u8 autoA,autoB;				//0=off, 1=on, 2=R
u8 stime=0;
u8 ewramturbo=0;
u8 autostate=0;

void autoAset(void);
void autoBset(void);
void swapAB(void);
void controller(void);
void vblset(void);
void restart(void);
void exit(void);
void multiboot(void);
void scrolll(int f);
void scrollr(void);
void drawui1(void);
void drawui2(void);
void drawui3(void);
void drawui4(void);
void drawui5(void);
void text(int ,char *);
void text2(int,char *);
void strmerge(char *,char *,char *);
void strmerge3(char *,char *,char *, char *);
void strmerge4(char *,char *,char *, char *, char *);
void subui(int menunr);
void ui2(void);
void ui3(void);
void ui4(void);
void ui5(void);
void drawclock(void);
void sleep(void);
void sleepset(void);
void fpsset(void);
void brightset(void);
void fadetowhite(void);
void ewramturboset(void);
void loadstatemenu(void);
void savestatemenu(void);
void autostateset(void);
void autostateset2(void);
void display(void);
void flickset(void);
void bajs(void);

void writeconfig(void);	//sram.c
void managesram(void);	//sram.c
void quicksave(void);   //sram.c

//new from unoffical versions
void ntsc_pal_reset(void); //6502.s
void make_freq_table(void); //6502.s
void cpuhack_reset(void); //6502.s
void paltoggle(void);
void cpuhacktoggle(void);
void ppuhacktoggle(void);
void followramtoggle(void);
void selectfollowaddress(void);
#if CHEATFINDER | EDITFOLLOW
char *hexn(unsigned int, int);
#endif

//from speed hacks
void clear_speedhack_find_buffers(void);
void autodetect_speedhack(void);
void find_best_speedhack(void);

void changehackmode(void);
void changebranchlength(void);
int getbranchhacknumber(void);
char *number(unsigned short);
void setunscaledmode(void);

#if CHEATFINDER
//from cheat finder
char* real_address(u16);
int add_cheat(u16, u8);
void delete_cheat(int);

int cheat_test(u32, int);
void cf_comparewith(void);
void cf_editcheats(void);
void edit_cheat(int);
void cf_results(void);
void cf_equal(void);
void cf_greater(void);
void cf_greaterequal(void);
void cf_less(void);
void cf_lessequal(void);
void cf_newsearch(void);
void cf_notequal(void);
void cf_update(void);
void cf_results(void);
void cf_drawresults(void);
void cf_drawedit(int);
void cheat_memcopy(void);
void do_cheats(void);
void reset_cheatfinder(void);
void update_cheatfinder_tally(void);
int cf_next_result(int);
int cf_result(int);
u8 cf_readmem(int);
#endif

void go_multiboot(void);

void draw_input_text(int, int, char*, int);
u32 inputhex(int, int, u32, u32);


extern u32 SPEEDHACK_FIND_BPL_BUF[32],SPEEDHACK_FIND_BNE_BUF[32],SPEEDHACK_FIND_BEQ_BUF[32];
extern u32 CHEATFINDER_BITS[320];
extern u8 CHEATFINDER_VALUES[10240],CHEATFINDER_CHEATS[900];

*/
#define MENU2ITEMS 7		//othermenu items
#if EDITFOLLOW
#define MENU3ITEMS 5		//displaymenu items
#else
#define MENU3ITEMS 3		//displaymenu items
#endif

#define MENU4ITEMS 3        //speedhack items (5 to allow editing branchhacks)

#if CHEATFINDER
#define MENU5ITEMS 11
#endif

#if CHEATFINDER
int cheatfinderstate;
int num_cheats=0;
const int MAX_CHEATS=50; // 900/18
u8 compare_value;
int found_for[7];
#endif
int selected;//selected menuitem.  used by all menus.
int mainmenuitems;//? or CARTMENUITEMS, depending on whether saving is allowed

#if CHEATFINDER
#define CARTMENUITEMS 15 //mainmenuitems when running from cart (not multiboot)
#define MULTIBOOTMENUITEMS 11 //"" when running from multiboot
#else
#define CARTMENUITEMS 13 //mainmenuitems when running from cart (not multiboot)
#define MULTIBOOTMENUITEMS 10 //"" when running from multiboot
#endif

const char MENUXITEMS[]={CARTMENUITEMS,MULTIBOOTMENUITEMS,MENU2ITEMS,MENU3ITEMS,MENU4ITEMS,MENU5ITEMS};

const fptr multifnlist[]={
	#if CHEATFINDER
	ui5,
	#endif
	autoBset,autoAset,controller,ui3,ui2,ui4,multiboot,sleep,restart,exit};
const fptr fnlist1[]={
	#if CHEATFINDER
	ui5,
	#endif
	autoBset,autoAset,controller,ui3,ui2,ui4,multiboot,savestatemenu,loadstatemenu,managesram,sleep,go_multiboot,restart,exit};
const fptr fnlist2[]={vblset,fpsset,swapAB,sleepset,autostateset,autostateset2,paltoggle,bajs};
const fptr fnlist3[]={display,flickset,brightset
#if EDITFOLLOW
,followramtoggle,selectfollowaddress
#endif
};
const fptr fnlist4[]={ppuhacktoggle,cpuhacktoggle,autodetect_speedhack};//,changehackmode,changebranchlength};
#if CHEATFINDER
const fptr fnlist5[]={cf_editcheats,cf_results,cf_equal,cf_notequal,cf_greater,cf_less,cf_greaterequal,cf_lessequal,cf_comparewith,cf_update,cf_newsearch};
#endif

const fptr* fnlistX[]={fnlist1,multifnlist,fnlist2,fnlist3,fnlist4,fnlist5};
const fptr drawuiX[]={drawui1,drawui1,drawui2,drawui3,drawui4,drawui5};

char *const autotxt[]={"OFF","ON","with R"};
char *const vsynctxt[]={"ON","OFF","SLOWMO"};
char *const sleeptxt[]={"5min","10min","30min","OFF"};
char *const brightxt[]={"I","II","III","IIII","IIIII"};
char *const hostname[]={"Crap","Prot","GBA","GBP","NDS"};
char *const ctrltxt[]={"1P","2P","1P+2P","Link2P","Link3P","Link4P"};
char *const disptxt[]={"Unscaled","Unscaled (Follow)","Scaled BG, Full OBJ","Scaled BG and OBJ"};
char *const flicktxt[]={"No Flicker","Flicker"};
char *const cntrtxt[]={"US (NTSC)","Europe (PAL)"};
#if EDITFOLLOW
char *const followtxt[]={"Sprite","RAM"};
char *const followtxt2[]={"Sprite Number: ","Address: "};
#endif
#if BRANCHHACKDETAIL
char *const branchtxt[]={"None","BPL","BNE","BEQ"};
#endif
char *const emuname[]={"PocketNES"};

void drawui1() {
	char str[30];
	int row=-1;
	cls(1);
	strmerge3(str,emuname[0]," " VERSION_NUMBER " on ",hostname[gbaversion]);
	drawtext(19,str,0);

#if CHEATFINDER
	text(++row,"Cheat Finder->");
#endif
	strmerge(str,"B autofire: ",autotxt[autoB]);
	text(++row,str);
	strmerge(str,"A autofire: ",autotxt[autoA]);
	text(++row,str);
	strmerge(str,"Controller: ",ctrltxt[(joycfg>>29)-1]);
	text(++row,str);
	text(++row,"Display->");
	text(++row,"Other Settings->");
	text(++row,"Speed Hacks->");
	text(++row,"Link Transfer");
	if(mainmenuitems==MULTIBOOTMENUITEMS) {
		text(++row,"Sleep");
		text(++row,"Restart");
		text(++row,"Exit");
	} else {
		text(++row,"Save State->");
		text(++row,"Load State->");
		text(++row,"Manage SRAM->");
		text(++row,"Sleep");
		text(++row,"Go Multiboot");
		text(++row,"Restart");
		text(++row,"Exit");
	}
}

void drawui2() {
	char str[30];
	int row=-1;
	cls(2);
	drawtext(32,"       Other Settings",0);
	strmerge(str,"VSync: ",vsynctxt[novblankwait]);
	text2(++row,str);
	strmerge(str,"FPS-Meter: ",autotxt[fpsenabled]);
	text2(++row,str);
	strmerge(str,"Swap A-B: ",autotxt[(joycfg>>10)&1]);
	text2(++row,str);
	strmerge(str,"Autosleep: ",sleeptxt[stime]);
	text2(++row,str);
	strmerge(str,"Autoload state: ",autotxt[autostate&1]);
	text2(++row,str);
	strmerge(str,"Autosave state: ",autotxt[(autostate&2)>>1]);
	text2(++row,str);
	strmerge(str,"Region: ",cntrtxt[(g_emuflags & 4)>>2]);		//USCOUNTRY=4
	text2(++row,str);
}

void drawui3() {
	char str[30];
	int row=-1;
	cls(2);
	drawtext(32,"      Display Settings",0);
	strmerge(str,"Display: ",disptxt[g_scaling&3]);
	text2(++row,str);
	strmerge(str,"Scaling: ",flicktxt[flicker]);
	text2(++row,str);
	strmerge(str,"Gamma: ",brightxt[gammavalue]);
	text2(++row,str);
#if EDITFOLLOW
	strmerge(str,"Sprite Follow by: ",followtxt[(g_emuflags & 32)>>5]);		//MEMFOLLOW=32
	text2(++row,str);
	strmerge(str,followtxt2[(g_emuflags & 32)>>5],hex4(*((short*)((&g_scaling)+1))));
	text2(++row,str);
#endif
	
}
void drawui4() {
	char str[30];
	int row=-1;
	cls(2);
	drawtext(32,"        Speed Hacks",0);
	strmerge(str,"PPU Hack: ",autotxt[g_emuflags&1]);
	text2(++row,str);
	strmerge(str,"JMP Hack: ",autotxt[!(g_emuflags&2)]);
	text2(++row,str);
	if (g_hackflags==0)
	{
		strcpy(str,"Autodetect Speed Hack");
		text2(++row,str);
	}
//	else if (g_hackflags==1)  //removed, no longer needed
//	{
//		strcpy(str,"Play the game for 1 second");
//		text2(2,str);
//	}
	else
	{
		strcpy(str,"Remove Speed Hack");
		text2(++row,str);
//	}
//	if (g_hackflags<16)
//	{
////		strcpy(str,"Manually set Speed Hack");
////		text2(3,str);
//	}
//	else
//	{
#if BRANCHHACKDETAIL
		strmerge(str,"Branch Hack: ",branchtxt[getbranchhacknumber()]);
		text2(++row,str);
		strmerge(str,"Branch Length: ",number(g_hackflags2));
		text2(++row,str);
#endif
	}
}

#if CHEATFINDER
void drawui5() {
	char str[30];
	int row=-1;
	cls(2);
	drawtext(32,"       Cheat Finder",0);
	
	strcpy(str,"Edit Cheats...");
	text2(++row,str);
	strmerge(str,"Search Results - ",number(found_for[6]));
	text2(++row,str);

	if (cheatfinderstate==1)
	{
		strmerge(str,"New==Old - ",number(found_for[0]));
		text2(++row,str);
		strmerge(str,"New!=Old - ",number(found_for[1]));
		text2(++row,str);
		strmerge(str,"New>Old  - ",number(found_for[2]));
		text2(++row,str);
		strmerge(str,"New<Old  - ",number(found_for[3]));
		text2(++row,str);
		strmerge(str,"New>=Old - ",number(found_for[4]));
		text2(++row,str);
		strmerge(str,"New<=Old - ",number(found_for[5]));
		text2(++row,str);
		strmerge(str,"Compare with number - ","Off");
		text2(++row,str);
		strcpy(str,"Update Values");
		text2(++row,str);
	}
	else
	{
		char compare[4];
		strcpy(compare,hexn(compare_value,2));
		strmerge4(str,"Value==",compare," - ",number(found_for[0]));
		text2(++row,str);
		strmerge4(str,"Value!=",compare," - ",number(found_for[1]));
		text2(++row,str);
		strmerge4(str,"Value>",compare,"  - ",number(found_for[2]));
		text2(++row,str);
		strmerge4(str,"Value<",compare,"  - ",number(found_for[3]));
		text2(++row,str);
		strmerge4(str,"Value>=",compare," - ",number(found_for[4]));
		text2(++row,str);
		strmerge4(str,"Value<=",compare," - ",number(found_for[5]));
		text2(++row,str);
		strmerge(str,"Compare with number - ","On");
		text2(++row,str);
		strmerge(str,"Number to compare to: ",compare);
		text2(++row,str);
	}
	strcpy(str,"New Search");
	text2(++row,str);
}
#endif



u32 oldkey;//init this before using getmenuinput

u32 getmenuinput(int menuitems)
{
	u32 keyhit;
	u32 tmp;
	int sel=selected;

	waitframe();		//(polling REG_P1 too fast seems to cause problems)
	tmp=~REG_P1;
	keyhit=(oldkey^tmp)&tmp;
	oldkey=tmp;
	if (menuitems==0) return keyhit;
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

int global_savesuccess;

void ui() {
	int key,soundvol,oldsel,tm0cnt,i;
	int mb=(u32)textstart<0x8000000;
	global_savesuccess=1;

	autoA=joycfg&A_BTN?0:1;
	autoA|=joycfg&(A_BTN<<16)?0:2;
	autoB=joycfg&B_BTN?0:1;
	autoB|=joycfg&(B_BTN<<16)?0:2;

	mainmenuitems=MENUXITEMS[mb];
//	mainmenuitems=((u32)textstart>0x8000000?CARTMENUITEMS:MULTIBOOTMENUITEMS);//running from rom or multiboot?
	FPSValue=0;					//Stop FPS meter

	soundvol=REG_SGCNT0_L;
	REG_SGCNT0_L=0;				//stop sound (GB)
	tm0cnt=REG_TM0CNT;
	REG_TM0CNT=0;				//stop sound (directsound)

	selected=0;
//	drawuiX[mb]();
	drawui1();
	for(i=0;i<8;i++)
	{
		waitframe();
		setdarknessgs(i);		//Darken game screen
		REG_BG2HOFS=224-i*32;	//Move screen right
	}

	global_savesuccess=backup_nes_sram(1);
	if (!global_savesuccess)
	{
		drawui1();
		REG_BG2HOFS=0;
	}

	oldkey=~REG_P1;			//reset key input
	do {
		drawclock();
		key=getmenuinput(MENUXITEMS[mb]);
		if(key&(A_BTN)) {
			oldsel=selected;
			fnlistX[mb][selected]();
			selected=oldsel;
			if (mb != (u32)textstart<0x8000000)
			{
				mb=1;
				selected=0;
			}
		}
		if(key&(A_BTN+UP+DOWN+LEFT+RIGHT))
//			drawuiX[mb]();
			drawui1();
	} while(!(key&(B_BTN+R_BTN+L_BTN)));
	
	if (global_savesuccess)
	{
		get_saved_sram();
	}
	writeconfig();			//save any changes
	for(i=1;i<9;i++)
	{
		waitframe();
		setdarknessgs(8-i);	//Lighten screen
		REG_BG2HOFS=i*32;	//Move screen left
	}
	while(key&(B_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
	REG_SGCNT0_L=soundvol;	//resume sound (GB)
	REG_TM0CNT=tm0cnt;		//resume sound (directsound)
	cls(3);
}

void subui(int menunr) {
	int key,oldsel;

	selected=0;
	drawuiX[menunr]();
//	if(menunr==2)drawui2();
//	if(menunr==3)drawui3();
//	if(menunr==4)drawui4();
//	#if CHEATFINDER
//	if(menunr==5)drawui5();
//	#endif
	scrolll(0);
	oldkey=~REG_P1;			//reset key input
	do {
		key=getmenuinput(MENUXITEMS[menunr]);
//		if(menunr==2)key=getmenuinput(MENU2ITEMS);
//		if(menunr==3)key=getmenuinput(MENU3ITEMS);
//		if(menunr==4)key=getmenuinput(MENU4ITEMS);
//		#if CHEATFINDER
//		if(menunr==5)key=getmenuinput(MENU5ITEMS);
//		#endif
		if(key&(A_BTN)) {
			oldsel=selected;
			fnlistX[menunr][selected]();
//			
//			if(menunr==2)fnlist2[selected]();
//			if(menunr==3)fnlist3[selected]();
//			if(menunr==4)fnlist4[selected]();
//			#if CHEATFINDER
//			if(menunr==5)fnlist5[selected]();
//			#endif

			selected=oldsel;
		}
		if(key&(A_BTN+UP+DOWN+LEFT+RIGHT))
		{
			drawuiX[menunr]();
//			if(menunr==2)drawui2();
//			if(menunr==3)drawui3();
//			if(menunr==4)drawui4();
//			#if CHEATFINDER
//			if(menunr==5)drawui5();
//			#endif
		}
	} while(!(key&(B_BTN+R_BTN+L_BTN)));
	scrollr();
	while(key&(B_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
}

void ui2() {
	subui(2);
}
void ui3() {
	subui(3);
}
void ui4() {
	subui(4);
}
#if CHEATFINDER
void ui5() {
	if (cheatfinderstate==0)
	{
		cf_newsearch();
	}
	else
	{
		update_cheatfinder_tally();
	}
	subui(5);
}
#endif
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
void strmerge3(char *dst,char *src1,char *src2, char *src3) {
	if(dst!=src1)
		strcpy(dst,src1);
	strcat(dst,src2);
	strcat(dst,src3);
}
void strmerge4(char *dst,char *src1,char *src2, char *src3, char *src4) {
	if(dst!=src1)
		strcpy(dst,src1);
	strcat(dst,src2);
	strcat(dst,src3);
	strcat(dst,src4);
}

#if CHEATFINDER | EDITFOLLOW
char *hexn(unsigned int n, int digits)
{
	int i;

	static char hexbuffer[9];
	char hextable[]="0123456789ABCDEF";
	hexbuffer[8]=0;
	for (i=7;i>=8-digits;--i)
	{
		hexbuffer[i]=hextable[n&15];
		n>>=4;
	}
	return hexbuffer+8-digits;
}
#endif

void drawclock() {

    char str[30];
    char *s=str+20;
    int timer,mod;

    if(rtc)
    {
	strcpy(str,"                    00:00:00");
	timer=gettime();
	mod=(timer>>4)&3;				//Hours.
	*(s++)=(mod+'0');
	mod=(timer&15);
	*(s++)=(mod+'0');
	s++;
	mod=(timer>>12)&15;				//Minutes.
	*(s++)=(mod+'0');
	mod=(timer>>8)&15;
	*(s++)=(mod+'0');
	s++;
	mod=(timer>>20)&15;				//Seconds.
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

void controller() {					//see io.s: refreshNESjoypads
	u32 i=joycfg+0x20000000;
	if(i>=0xe0000000)
		i-=0xc0000000;
	resetSIO(i);					//reset link state
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

void fpsset() {
	fpsenabled = (fpsenabled^1)&1;
}

void brightset() {
	gammavalue++;
	if (gammavalue>4) gammavalue=0;
	paletteinit();
	PaletteTxAll();
	Update_Palette();
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
		for(i=0;i<90;i++)			//wait a while
			waitframe();
	}
}

void restart() {
	writeconfig();					//save any changes
	scrolll(1);
	__asm {mov r0,#0x3007f00}		//stack reset
	__asm {mov sp,r0}
	rommenu();
}
void exit() {
	writeconfig();					//save any changes
	if (autostate&2)
	{
		quicksave();
	}
	fadetowhite();
	REG_DISPCNT=FORCE_BLANK;		//screen OFF
	REG_BG0HOFS=0;
	REG_BG0VOFS=0;
	REG_BLDCNT=0;					//no blending
	doReset();
}

void sleep() {
	fadetowhite();
	suspend();
	setdarknessgs(7);				//restore screen
	while((~REG_P1)&0x3ff) {
		waitframe();				//(polling REG_P1 too fast seems to cause problems)
	}
}
void fadetowhite() {
	int i;
	for(i=7;i>=0;i--) {
		setdarknessgs(i);			//go from dark to normal
		waitframe();
	}
	for(i=0;i<17;i++) {				//fade to white
		setbrightnessall(i);		//go from normal to white
		waitframe();
	}
}

void scrolll(int f) {
	int i;
	for(i=0;i<9;i++)
	{
		if(f) setdarknessgs(8+i);	//Darken screen
		REG_BG2HOFS=i*32;			//Move screen left
		waitframe();
	}
}
void scrollr() {
	int i;
	for(i=8;i>=0;i--)
	{
		waitframe();
		REG_BG2HOFS=i*32;			//Move screen right
	}
	cls(2);							//Clear BG2
}

void swapAB() {
	joycfg^=0x400;
}

void display() {
	char sc;
	wtop=0;
	g_scaling=sc=(g_scaling+1)&3;
	spriteinit(sc);
}

void flickset() {
	flicker++;
	if(flicker > 1){
		flicker=0;
		twitch=1;
	}
}

void autostateset() {
	autostate^=1;
}
void autostateset2() {
	autostate^=2;
}

void bajs(){
}

//new code...
void paltoggle() {
	g_emuflags^=4;
	ntsc_pal_reset();
	make_freq_table();
}

void cpuhacktoggle() {
	g_emuflags^=2;
	cpuhack_reset();
}

void ppuhacktoggle() {
	g_emuflags^=1;
}

void followramtoggle(void)
{
	g_emuflags^=32;
}

#if CHEATFINDER | EDITFOLLOW
void draw_input_text(int row, int column, char* str, int hilitedigit)
{
	int i=0;
	const int hilite=(1<<12)+0x4100,nohilite=0x4100;
	u16 *here;
	row+=37;
	here=SCREENBASE+row*32+column+1;
	while(str[i]>=' ') {
		here[i]=str[i]|nohilite;
		if (i==hilitedigit) {
			if (str[i]==' ')
			   here[i]='_'|hilite;
			else
			   here[i]=str[i]|hilite;
		}
		i++;
	}
}

u32 inputhex(int row, int column, u32 value, u32 digits)
{
	int key,tmp;
	u32 digit,addthis;
	digit=digits-1;
	
	draw_input_text(row,column,hexn(value,digits),digit);
	
	oldkey=~REG_P1;			//reset key input
	do {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		tmp=~REG_P1;
		key=(oldkey^tmp)&tmp;
		oldkey=tmp;
		if (key&(RIGHT)) ++digit;
		if (key&(LEFT)) --digit;
		digit%=digits;
		addthis=1<<((digits-digit-1)<<2);
		if (key&UP) value+=addthis;
		if (key&DOWN) value-=addthis;

		if(key&(UP+DOWN+LEFT+RIGHT))
		{
			draw_input_text(row,column,hexn(value,digits),digit);
		}
	} while(!(key&(A_BTN+B_BTN+R_BTN+L_BTN)));
	while(key&(B_BTN|A_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
	return value;
}
#endif

#if CHEATFINDER
void inputtext(int row, int column, char *text, u32 length)
{
	int key,tmp;//,fast;
	u32 pos=0;
	const u8 textrange=127-' ';
	
	draw_input_text(row,column,text,pos);
	
	oldkey=~REG_P1;			//reset key input
	do {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		tmp=~REG_P1;
		key=(oldkey^tmp)&tmp;
		oldkey=tmp;
	
		if (key&(RIGHT)) ++pos;
		if (key&(LEFT))	pos+=(length-1);
		pos%=length;
		if (key&UP) text[pos]++;
		if (key&L_BTN) text[pos]+=10;
		if (key&DOWN) text[pos]+=(textrange-1);
		if (key&R_BTN) text[pos]+=(textrange-10);
		text[pos]=((text[pos]-' ')%textrange)+' ';

		if(key&(UP+DOWN+LEFT+RIGHT+R_BTN+L_BTN))
		{
			draw_input_text(row,column,text,pos);
		}
	} while(!(key&(A_BTN+B_BTN)));
	while(key&(B_BTN|A_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
}
#endif

#if EDITFOLLOW

void selectfollowaddress()
{
	unsigned short followaddress;
	drawui3();
	followaddress=(*((short*)((&g_scaling)+1)));
	followaddress=inputhex(4,strlen(followtxt2[(g_emuflags & 32)>>5]),followaddress,4);
	(*((short*)((&g_scaling)+1)))=followaddress;
}
#endif

/*
void changehackmode(void)
{
	char t=(g_hackflags&0xF0);
	char l=(g_hackflags&0x0F);
	if (t==0x00)
	{
		t=0x10; l=4;
	}
	else if (t==0x10)
	{
		t=0xD0;
	}
	else if (t==0xD0)
	{
		t=0xF0;
	}
	else if (t==0xF0)
	{
		t=0x00;
		l=0;
	}
	g_hackflags=t|l;
	cpuhack_reset();
}
void changebranchlength(void)
{
	//sheer laziness... hit A to increment
	char t=(g_hackflags&0xF0);
	char l=(g_hackflags&0x0F);
	if (t==0) return;
	l++;
	l&=0xF;
	g_hackflags=t|l;
	cpuhack_reset();
}
*/
#if BRANCHHACKDETAIL
int getbranchhacknumber(void)
{
	char t=(g_hackflags&0xF0);
//NoHacks			EQU 0x00
//BplHack			EQU 0x10
//BneHack			EQU 0xD0
//BeqHack			EQU 0xF0
	if (t==0x00) return 0;
	if (t==0x10) return 1;
	if (t==0xD0) return 2;
	if (t==0xF0) return 3;
	return 4; //shouldn't happen
}
#endif
#if BRANCHHACKDETAIL | CHEATFINDER
char *number(unsigned short n)
{
	int i;

	static char numbuffer[6];
	numbuffer[5]=0;
	i=5;
	if (n==0)
	{
		--i;
		numbuffer[i]='0';
	}
	while(n>0)
	{
		--i;
		numbuffer[i]=(n%10)+'0';
		n/=10;
	}
	return &numbuffer[i];
}
#endif

u32*const speedhack_buffers[]={SPEEDHACK_FIND_BPL_BUF,SPEEDHACK_FIND_BNE_BUF,SPEEDHACK_FIND_BEQ_BUF};
const u8 hacktypes[]={0x10,0xD0,0xF0};
const int num_speedhack_buffers=3;

__inline void clear_speedhack_find_buffers(void)
{
	int i;
	for (i=0;i<num_speedhack_buffers;i++)
	{
		memset (speedhack_buffers[i],0,128);
	}
}
void autodetect_speedhack(void)
{
	int oldvblank;
	if (g_hackflags==0)
	{
		clear_speedhack_find_buffers();
		g_hackflags=1;
		cpuhack_reset();
		oldvblank=novblankwait;  //preserve vblank
		
		//FIX POSSIBLE BUG
		if (global_savesuccess)
		{
			get_saved_sram();
		}
		writeconfig();			//save any changes
		
		run(0);
		
		//FIX POSSIBLE BUG
		global_savesuccess=backup_nes_sram(1);
		if (!global_savesuccess)
		{
			drawui1();
			REG_BG2HOFS=0;
		}
		
		
		
		
		novblankwait=oldvblank;
		dontstop=1;
		find_best_speedhack();
	}
	else // if (g_hackflags!=1)  //no more deleayed searches
	{
		g_hackflags=0;
		cpuhack_reset();
	}
}


void find_best_speedhack(void)
{
	unsigned int max=0,val,branchlength;
	int hacktype=-1;
	int h;
	u32 *arr;
	int i,maxindex=-1;
	for (h=0;h<num_speedhack_buffers;h++)
	{
		arr=speedhack_buffers[h];
		for (i=0;i<32;i++)
		{
			val=arr[i];
			if (val>max)
			{
				maxindex=i;
					hacktype=h;
				max=val;
			}
		}
	}
	
	if (hacktype>-1)
	{
		branchlength=maxindex+2;
		hacktype=hacktypes[hacktype];
		g_hackflags=hacktype;
		g_hackflags2=branchlength;
		cpuhack_reset();
	}
	else
	{
		g_hackflags=0;
		cpuhack_reset();
	}
}



#if CHEATFINDER

void update_cheatfinder_tally(void)
{
	found_for[0]=cheat_test(0,0);
	found_for[1]=cheat_test(4,0);
	found_for[2]=cheat_test(8,0);
	found_for[3]=cheat_test(12,0);
	found_for[4]=cheat_test(16,0);
	found_for[5]=cheat_test(20,0);
	found_for[6]=cheat_test(24,0);
/*
	found_for[0]=cheat_test(is_equal,0);
	found_for[1]=cheat_test(is_not_equal,0);
	found_for[2]=cheat_test(is_greater,0);
	found_for[3]=cheat_test(is_less,0);
	found_for[4]=cheat_test(is_greater_equal,0);
	found_for[5]=cheat_test(is_less_equal,0);
	found_for[6]=cheat_test(is_always_true,0);
*/
}

void reset_cheatfinder(void)
{
	u32 *const bits=CHEATFINDER_BITS;
//	u8 *const values=CHEATFINDER_VALUES;
//	u8 *const cheats=CHEATFINDER_CHEATS;
//	int i;
	memset(bits,0xFFFFFFFF,1280*sizeof(char));
//	for (i=0;i<1280;i++)
//	{
//		bits[i]=0xFF;
//	}
//	for (i=0;i<10240;i++)
//	{
//		values[i]=0xFF;
//	}
	update_cheatfinder_tally();
}
void cheat_memcopy(void)
{
	u8 *const values=CHEATFINDER_VALUES;
	memcpy(values,NES_RAM,10240);
//	memcpy(values+2048,NES_SRAM,8192);
}

void write_byte(u8 *address, u8 data)
{

	u16 *addr2;
	//if not hw aligned
	if ( (int)address & 1)
	{
		addr2=(u16*)((int)address-1);
		*addr2 &= 0xFF;
		*addr2 |= (data << 8);
	}
	else
	{
		addr2=(u16*)address;
		*addr2 &= 0xFF00;
		*addr2 |= data;
	}
}

int add_cheat(u16 address, u8 value)
{
	u8* cheats=CHEATFINDER_CHEATS;
	u32 element=num_cheats*3;
	int i;
	if (num_cheats<MAX_CHEATS)
	{
		//'012abcdefghijklmno' to
		//'012345abcdefghijklmno               '
		//'012345678abcdefghijklmnoABCDEFGHIJKLMNO               '
		for(i=num_cheats*18+3-1;i>=(element+3);i--)
		   write_byte(&cheats[i],cheats[i-3]);
		for(i=num_cheats*18+3;i<(num_cheats+1)*18;i++)
		   write_byte(&cheats[i],' ');
		write_byte(&cheats[element],address&255);
		write_byte(&cheats[element+1],address>>8);
		write_byte(&cheats[element+2],value);
		num_cheats++;
		return 1;
	}
	else
	{
		return 0;
	}
}

char* real_address(u16 addr)
{
	addr&=0x7FFF;
	if (addr>=0x800)
	{
		addr-=0x800;
		addr+=0x6000;
	}
	return hex4(addr);
}

void do_cheats(void)
{
	int i;
	u8* cheats=CHEATFINDER_CHEATS;
	u8 data;
	u16 addr;
	u32 max=num_cheats*3;
	for (i=0;i<max;i+=3)
	{
		addr=cheats[i]+(cheats[i+1]<<8);
		data=cheats[i+2];
		if (addr<10240)
		{
//			if (addr<0x800)
//			{
				(NES_RAM)[addr]=data;
//			}
//			else
//			{
//				(NES_SRAM)[addr-0x800]=data;
//			}
		}
	}
}
void do_cheat_test(u32 testfunc)
{
	cheat_test(testfunc,1);
	cheat_memcopy();
	update_cheatfinder_tally();
}
//void do_cheat_test(cheattestfunc testfunc)
//{
//	cheat_test(testfunc,1);
//	cheat_memcopy();
//	update_cheatfinder_tally();
//}

void cf_equal(void)
{
	do_cheat_test(0);
//	cheat_memcopy();
//	update_cheatfinder_tally();
}
void cf_notequal(void)
{
	do_cheat_test(4);
//	cheat_memcopy();
//	update_cheatfinder_tally();
}
void cf_greater(void)
{
	do_cheat_test(8);
//	cheat_memcopy();
//	update_cheatfinder_tally();
}
void cf_less(void)
{
	do_cheat_test(12);
//	cheat_memcopy();
//	update_cheatfinder_tally();
}
void cf_greaterequal(void)
{
	do_cheat_test(16);
//	cheat_memcopy();
//	update_cheatfinder_tally();
}
void cf_lessequal(void)
{
	do_cheat_test(20);
//	cheat_memcopy();
//	update_cheatfinder_tally();
}
void cf_comparewith(void)
{
	cheatfinderstate^=3;
	update_cheatfinder_tally();
}
void cf_update(void)
{
	if (cheatfinderstate==1)
	{
		cheat_memcopy();
		update_cheatfinder_tally();
	}
	else
	{
		compare_value=inputhex(9,22,compare_value,2);
		update_cheatfinder_tally();
	}

}
void cf_newsearch(void)
{
	reset_cheatfinder();
	cheat_memcopy();
	if (cheatfinderstate==0)
	{
		cheatfinderstate=1;
	}
	update_cheatfinder_tally();
}
int cf_next_result(int i)
{
	u32 *const bits=CHEATFINDER_BITS;
	do

	{
		if (i<10240)
		{
			if (cf_getbit(i))
			{
				return i;
			}
			i++;
		}
		else
		{
			return -1;
		}
	} while(1);
}
int cf_result(int n)
{
	int i=0;
	do
	{
		i=cf_next_result(i);
		if (i!=-1)
		{
			if (n==0)
				return i;
			n--;
			i++;
		}
		else
		{
			return -1;
		}
	} while(1);
}

__inline u8 cf_readmem(int i)
{
	return (NES_RAM)[i];
//	if (i<2048)
//		return (NES_RAM)[i];
//	else if (i<10240)
//		return (NES_SRAM)[i-2048];
//	return 0;
}

void cf_drawresults()
{
	int bottom=found_for[6];
	u8 *const values=CHEATFINDER_VALUES;
	int i;
	u8 value;
	int line=0;
	char str[30];
	int top,sel;
	sel=selected;
	top=selected-5;
	if (top<0) top=0;
	selected=sel-top;
	
	i=cf_result(top);
	cls(2);
	drawtext(32,"    Cheat Search Results",0);
	drawtext(33,"Press A to add cheat",0);
	while (line<10)
	{
		if (i==-1)
			break;
		value=cf_readmem(i);
		strmerge(str,real_address(i),": ");
		strmerge(str,str,hexn(value,2));
		strmerge3(str,str," was ",hexn(values[i],2));
		text2(line,str);
		line++;
		if (line>=bottom-top || line>10)
			break;
		i=cf_next_result(i+1);
	}
	selected=sel;
}


void cf_results(void)
{
	int top, bottom;

	int key;
	top=0;
	bottom=found_for[6];  // 0<=selected<bottom
	if (bottom==0) return;
	selected=0;
	
	cf_drawresults();
	oldkey=~REG_P1;			//reset key input
	do {
		key=getmenuinput(bottom);
		if(key&(A_BTN)) {
			int add_address=cf_result(selected);
			u8 add_value=cf_readmem(add_address);
			if (add_cheat(add_address,add_value))
				edit_cheat(num_cheats-1);
		}
		if(key&(A_BTN+UP+DOWN+LEFT+RIGHT))
			cf_drawresults();
	} while(!(key&(B_BTN+R_BTN+L_BTN)));
	while(key&(B_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
	cheatsave();
}

void cf_drawedit(int center)
{
	int bottom=num_cheats+1;

	u8 *cheats=CHEATFINDER_CHEATS;
	u16 address;
	u8 data;
	int i;
	int max;
	int line=0;
	char str[30];
	char buffer[18];
	int top,sel;
	
	sel=selected;
	top=center-5;
	if (top<0) top=0;
	selected=sel-top;
	if (bottom>top+10) bottom=top+10;
	max=bottom*3;
	
	cls(2);
	//          "                             "
	drawtext(32,"     Cheat List Editor",0);
	drawtext(33,"A to Edit, Start to Toggle",0);
	drawtext(34,"Select to delete",0);
//	drawtext(35,"R to poke",0);  //disabled

	buffer[16]=buffer[0]=' ';
	buffer[17]='\0';
	for (i=top*3;i<max;i+=3)
	{
		if (i==num_cheats*3)
		{
			strcpy(str,"Add New Cheat");
		}
		else
		{
//entries look like 6543: 21 (currently FF) Off
//entries now look like 6543:21 Infinite Health Off
			address=cheats[i]+(cheats[i+1]<<8);
			data=cheats[i+2];
			//strmerge(str,real_address(address),": ");
			strmerge(str,real_address(address),":");
			strmerge(str,str,hexn(data,2));
			//15 character long cheat desc
			memcpy(&buffer[1],&cheats[num_cheats*3+(i*15/3)],15);
			strmerge(str,str,buffer);
			//strmerge4(str,str," (currently ",hexn(cf_readmem(address&0x7FFF),2),") ");
			strmerge(str,str,(address&0x8000)?"Off":"On");
		}
		text2(line,str);
		line++;
	}
	selected=sel;
}


void edit_cheat(int cheatnum)
{
	int bottom=num_cheats+1;

	u8 *const cheats=CHEATFINDER_CHEATS;
	u32 address;
	u8 data;
	int max;
	int i;
//	int line=0;
	int top,sel;
	int row,column;
	int enabled;
	char buffer[16];
	
	u8* activecheat=cheats+cheatnum*3;
	u8* activecheatdesc=cheats+num_cheats*3+cheatnum*15;

	sel=selected;
	top=cheatnum-5;
	selected=-1;
	if (top<0) top=0;
	row=cheatnum-top;
	column=0;
	if (bottom>top+10) bottom=top+10;
	max=bottom*3;
	
	cf_drawedit(cheatnum);

	address=activecheat[0]+(activecheat[1]<<8);
	enabled=address&0x8000;
	data=activecheat[2];

	address&=0x7FFF;

	if (address>=0x800) address+=0x5800;
	address=inputhex(row,column,address,4);
	address&=0x7FFF;
	if (address<0x6000)
		address&=0x7FF;
	else
	{
		address-=0x5800;
	}
	address|=enabled;
	write_byte(&activecheat[0],address&255);
	write_byte(&activecheat[1],address>>8);
	cf_drawedit(cheatnum);
	
	column=5;
	data=inputhex(row,column,data,2);
	write_byte(&activecheat[2],data);
	cf_drawedit(cheatnum);
	
	column=8;
	buffer[15]='\0';
	memcpy(buffer,activecheatdesc,15);
	inputtext(row,column,buffer,15);
	for (i=0;i<15;i++)
	    write_byte(&activecheatdesc[i],buffer[i]);
	
	selected=sel;
}

void delete_cheat(int i)
{
	u8* cheats=CHEATFINDER_CHEATS;
	u8* cheatsdesc;
	int j;
//	u32 element=num_cheats*3;
	if (i<num_cheats)
	{
		//'012012abcdefghijklmnoABCDEFGHIJKLMNO' to
		//'012ABCDEFGHIJKLMNO'
		num_cheats--;
		for (j=i;j<num_cheats;j++)

		{
			write_byte(&cheats[j*3+0],cheats[j*3+3]);
			write_byte(&cheats[j*3+1],cheats[j*3+4]);
			write_byte(&cheats[j*3+2],cheats[j*3+5]);
		}
		cheatsdesc=cheats+num_cheats*3;
		for (j=0;j<i*15;j++)
			write_byte(&cheatsdesc[j],cheatsdesc[j+3]);
		for (j=i*15;j<num_cheats*15;j++)
			write_byte(&cheatsdesc[j],cheatsdesc[j+15+3]);
	}
}


void cf_editcheats(void)
{
	u8* cheats=CHEATFINDER_CHEATS;
	int top;

	int key;//,oldsel;
	top=0;
	selected=0;
	
	cf_drawedit(selected);
//	scrolll(0);
	oldkey=~REG_P1;			//reset key input
	do {
		key=getmenuinput(num_cheats+1);
//		if(key==(R_BTN)) {  //poke feature disabled
//			u16 addr=(cheats[selected*3+0]+(cheats[selected*3+1]<<8))&0x7FFF;
//			u8 data=cheats[selected*3+2];
//			if (addr<0x800)
//			{
//				(NES_RAM)[addr]=data;
//			}
//			else
//			{
//				(NES_SRAM)[addr-0x800]=data;
//			}
//		}
		if(key&(START)) {
			if (selected==num_cheats)
			{
				if(add_cheat(0,0))
					edit_cheat(selected);
			}
			else
			{
				write_byte(&cheats[selected*3+1],cheats[selected*3+1]^0x80);
			}
		}
		if(key&(A_BTN)) {
			if (selected<num_cheats)
			{
				edit_cheat(selected);
			}
			if (selected==num_cheats)
			{
				if (add_cheat(0,0))
					edit_cheat(selected);
			}
		}
		if (key&(SELECT)){
			delete_cheat(selected);
		}
		if(key&(A_BTN+UP+DOWN+LEFT+RIGHT+START+SELECT))
			cf_drawedit(selected);
	} while(!(key&(B_BTN+L_BTN+R_BTN)));
//	scrollr();
	while(key&(B_BTN)) {
		waitframe();		//(polling REG_P1 too fast seems to cause problems)
		key=~REG_P1;
	}
	cheatsave();
}

#endif


//extern char NES_VRAM;
//extern char g_rombase;
//extern char g_vrombase;
//extern int selectedrom;
//u8 *findrom(int);
//void loadcart(int, int);
//extern int roms;
//extern int max_multiboot_size;
//extern int romnum;

void go_multiboot()
{
	u8 *src, *dest;
	int size;
	int key;
	int rom_size;
	
	if(pogoshell) rom_size=48+16+(*(u8*)(findrom(romnum)+48+4))*16*1024+(*(u8*)(findrom(romnum)+48+5))*8*1024;  //need to read this from ROM
	else rom_size=sizeof(romheader)+*(u32*)(findrom(romnum)+32);
	src=(u8*)findrom(selectedrom);
	dest=(u8*)(&Image$$RO$$Limit);
	size=(NES_VRAM)-dest+0x2000;
	if (rom_size>size)
	{
		cls(1);
		drawtext(8, "Game is too big to multiboot",0);
		drawtext(9,"      Attempt anyway?",0);
		drawtext(10,"        A=YES, B=NO",0);
		oldkey=~REG_P1;			//reset key input
		do {
			key=getmenuinput(10);
			if(key&(B_BTN + R_BTN + L_BTN ))
				return;
		} while(!(key&(A_BTN)));
		oldkey=~REG_P1;			//reset key input
	}

	memcpy (dest,src,size);
	textstart=dest;	
	selectedrom=0;
	loadcart(selectedrom,g_emuflags&0x300);
	mainmenuitems=MENUXITEMS[1];
	roms=1;
}
