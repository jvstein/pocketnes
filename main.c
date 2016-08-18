#include "includes.h"

/*
#include <stdio.h>
#include <string.h>
#include "gba.h"
#include "minilzo.107/minilzo.h"
#include "cheat.h"
#include "asmcalls.h"
#include "main.h"
#include "ui.h"
#include "sram.h"
*/

extern romheader mb_header;

//const unsigned __fp_status_arm=0x40070000;
u8 *textstart;//points to first NES rom (initialized by boot.s)
u8 *ewram_start;
u8 *end_of_exram;
u32 max_multiboot_size;
u32 oldinput;

char pogoshell_romname[32];	//keep track of rom name (for state saving, etc)
#if RTCSUPPORT
char rtc=0;
#endif
char pogoshell=0;
char gameboyplayer=0;
char gbaversion;
int ne=0x454e;

#if SAVE
extern u8* BUFFER1;
extern u8* BUFFER2;
extern u8* BUFFER3;
#endif

void C_entry() {
	int i;
	u32 temp;
	
#if RTCSUPPORT
	vu16 *timeregs=(u16*)0x080000c8;
	*timeregs=1;
	if(*timeregs & 1) rtc=1;
#endif
	
#if !GCC
	ewram_start = (u8*)	&Image$$RO$$Limit;
	if (ewram_start>=(u8*)0x08000000)
	{
		ewram_start=(u8*)0x02000000;
	}
#endif
	end_of_exram = (u8*)&END_OF_EXRAM;
	
	temp=(u32)(*(u8**)0x0203FBFC);
	pogoshell=((temp & 0xFE000000) == 0x08000000)?1:0;
	gbaversion=CheckGBAVersion();
	vblankfptr=&vbldummy;
	memset((u32*)0x6000000,0,0x18000);  //clear vram (fixes graphics junk)

	ui_x=0x100;
	move_ui();
//	REG_BG2HOFS=0x0100;		//Screen left
	REG_BG2CNT=0x4600;	//16color 512x256 CHRbase0 SCRbase6 Priority0

	PPU_init();
	PPU_reset();

#if SAVE
	BUFFER1 = ewram_start;
	BUFFER2 = BUFFER1+0x10000;
	BUFFER3 = BUFFER2+0x20000;
#endif

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
			emuflags |= PALTIMING;
		else
			emuflags &= ~PALTIMING;

		roms=1;
		textstart=(*(u8**)0x0203FBFC)-sizeof(romheader);
		memcpy(pogoshell_romname,d,32);
#if MULTIBOOT
		memcpy(mb_header.name,d,32);
#endif
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
//	REG_WININ=0xFFFF;
//	REG_WINOUT=0xFFFB;
//	REG_WIN0H=0xFF;
//	REG_WIN0V=0xFF;

	if(REG_DISPCNT==FORCE_BLANK)	//is screen OFF?
		REG_DISPCNT=0;				//screen ON
	*MEM_PALETTE=0x7FFF;			//white background
	REG_BLDCNT=0x00ff;				//brightness decrease all
	for(i=0;i<17;i++) {
		REG_BLDY=i;					//fade to black
		waitframe();
	}
	*MEM_PALETTE=0;					//black background (avoids blue flash when doing multiboot)
	REG_DISPCNT=0;					//screen ON, MODE0
	vblankfptr=&vblankinterrupt;
	#if SAVE
		lzo_init();	//init compression lib for savestates
	#endif
	
	//load font+palette
	loadfont();
	loadfontpal();
//	LZ77UnCompVram(&font,(u16*)0x6002400);
//	memcpy((void*)0x5000080,&fontpal,64);
	
	
	#if SAVE
		readconfig();
	#endif
	rommenu();
}

//show splash screen
void splash() {
	int i;

	REG_DISPCNT=FORCE_BLANK;	//screen OFF
	memcpy((u16*)MEM_VRAM,(u16*)textstart,240*160*2);
	waitframe();
	ui_x=0;
	move_ui();
//	REG_BG2CNT=0x0000;
	REG_DISPCNT=BG2_EN|MODE3;
	for(i=16;i>=0;i--) {	//fade from white
		setbrightnessall(i);
		waitframe();
	}
	for(i=0;i<150;i++) {	//wait 2.5 seconds
		waitframe();
		if (REG_P1==0x030f){
			gameboyplayer=1;
			gbaversion=3;
		}
	}
}

