#include "includes.h"

//extern const u8 font[];
//extern const u8 fontpal[];

u32 oldkey;
int selected;

int ui_x;
int ui_y;


void move_ui()
{
	REG_BG2HOFS=ui_x;
	REG_BG2VOFS=ui_y;
}

void loadfont()
{
	LZ77UnCompVram((void*)&font,FONT_MEM);
}
void loadfontpal()
{
	memcpy((void*)FONT_PAL,&fontpal,64);
}
void get_ready_to_display_text()
{
	REG_DISPCNT&=~(7 | FORCE_BLANK); //force mode 0, and turn off force blank
	REG_DISPCNT|=BG2_EN; //text on BG2
	REG_BG2CNT= 0 | (0 << 2) | (UI_TILEMAP_NUMBER << 8) | (1<<14);
}

void clearoldkey()
{
	oldkey=~REG_P1;
}

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

void cls(int chrmap)
{
	int i=0,len=0x200;
	u32 *scr=(u32*)SCREENBASE;
	
	const u32 FILL_PATTERN = (FONT_FIRSTCHAR + FONT_PALETTE_NUMBER*0x1000)*0x10001;
	
	if (chrmap&1)
	{
		len=0x540/4;
		for(;i<len;i++)				//512x256
		{
			scr[i]=FILL_PATTERN;
		}
	}
	if(chrmap&2)
	{
		i=0x200;
//		len=0x500/4+0x200;
		len=0x540/4+0x200;
		for(;i<len;i++)				//512x256
		{
			scr[i]=FILL_PATTERN;
		}
	}
//		len=0x400;
	ui_y=0;
	move_ui();
//	REG_BG2VOFS=0;
//	REG_WIN0V=0xFF;
}

void drawtext(int row,const char *str,int hilite) {
	u16 *here=SCREENBASE+row*32;
	int i=0;
	
	int map_add = 0x1000*FONT_PALETTE_NUMBER + FONT_FIRSTCHAR - 32;
	u16 space = map_add + ' ';
	
	if (hilite>=0)
	{
		//leading asterisk
		*here = hilite?map_add+'*':space;
		here++;
	}
	else
	{
		hilite=-hilite-1;
	}
	map_add+=hilite*0x1000;
	
	while(str[i]>=' ') {
		here[i]=(u16)(str[i]+map_add);
		i++;
	}
	for(;i<31;i++)
		here[i]=space;
}

void setdarknessgs(int dark) {
	REG_BLDCNT=0x01f1;				//darken game screen
	REG_BLDY=dark;					//Darken screen
	REG_BLDALPHA=(0x10-dark)<<8;	//set blending for OBJ affected BG0
}

void setbrightnessall(int light) {
	REG_BLDCNT=0x00bf;				//brightness increase all
	REG_BLDY=light;
}

void waitkey()
{
	u32 key;
	clearoldkey();
	do
	{
		key=getmenuinput(1);
		waitframe();
	} while (!(key & (A_BTN | B_BTN | START)));
}
