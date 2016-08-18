#include "includes.h"

int roms;//total number of roms
int selectedrom=0;


void rommenu(void) {
	cls(3);
	//redundant, but let's include these two lines anyway
	ui_x=0x0100;		//Screen left
	move_ui();
//	REG_WIN0H=0xFF00;
	REG_BG2CNT=0x4600;	//16color 512x256 CHRbase0 SCRbase6 Priority0
	setdarknessgs(16);
	#if SAVE
		backup_nes_sram(1);
		//this now has its own delete menu built into the function
	#endif
	#if LINK
	resetSIO((joycfg&~0xff000000) + 0x20000000);//back to 1P
	#endif

	if(pogoshell)
	{
		loadcart(0,emuflags&0x304,1);		//Also save country
//		#if SAVE
//			get_saved_sram();
//		#endif
	}
	else
	{
		int i,lastselected=-1;
		int key;

		int romz=roms;	//globals=bigger code :P
		int sel=selectedrom;

		oldinput=AGBinput=~REG_P1;
    
		if(romz>1){
			i=drawmenu(sel);
			loadcart(sel,i|(emuflags&0x300),1);  //(keep old gfxmode)
//			#if SAVE
//				get_saved_sram();
//			#endif
			lastselected=sel;
			for(i=0;i<8;i++)
			{
				waitframe();
				ui_x=224-i*32;	//Move screen right
				move_ui();
//				REG_WIN0H=i*32-1;
			}
//			REG_WIN0H=239;
			setdarknessgs(7);			//Lighten screen
		}
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
				loadcart(sel,i|(emuflags&0x300),1);  //(keep old gfxmode)
//				#if SAVE
//					get_saved_sram();
//				#endif
				lastselected=sel;
			}
			run(0);
		} while(romz>1 && !(key&(A_BTN+B_BTN+START)));
		for(i=1;i<9;i++)
		{
			setdarknessgs(8-i);		//Lighten screen
			ui_x=i*32;		//Move screen left
			move_ui();
//			REG_WIN0H=255-i*32;
			run(0);
		}
		cls(3);	//leave BG2 on for debug output
//		REG_WIN0H=239;
		while(AGBinput&(A_BTN+B_BTN+START)) {
			AGBinput=0;
			run(0);
		}
	}
//#if SAVE
//	if(autostate&1)quickload();
//#endif
	run(1);
}

//return ptr to Nth ROM (including rominfo struct)
u8 *findrom(int n) {
	u8 *p=textstart;
	while(!pogoshell && n--)
	{
		p+=*(u32*)(p+32)+sizeof(romheader);
	}
	return p;
}

//returns options for selected rom
int drawmenu(int sel) {
	int i,j,topline,toprow,romflags=0;
	int top_displayed_line=0;
	u8 *p;
	romheader *ri;

	waitframe();

	if(roms>20) {
		topline=8*(roms-20)*sel/(roms-1);
		toprow=topline/8;
		j=(toprow<roms-20)?21:20;
		ui_y=topline%8;
		move_ui();
	} else {
		int ui_row;
		
		ui_row = (160-roms*8)/2;
		ui_row/=4;
		if (ui_row&1)
		{
			ui_y=4;
			move_ui();
			ui_row++;
		}
		ui_row/=2;
		top_displayed_line=ui_row;

		toprow=0;
		j=roms;
	}
	p=findrom(toprow);
	for(i=0;i<j;i++) {
		if(roms>1)drawtext(i+top_displayed_line,(char*)p,i==(sel-toprow)?1:0);
		if(i==sel-toprow) {
			ri=(romheader*)p;
			romflags=(*ri).flags|(*ri).spritefollow<<16;
		}
		p+=*(u32*)(p+32)+48;
	}
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
		if(repeatcount<25 || repeatcount&3)	//delay/repeat
			dpad=0;
	} else {
		repeatcount=0;
		lastdpad=dpad;
	}
	EMUinput=0;	//disable game input
	return dpad|(keyhit&(A_BTN+B_BTN+START));
}
