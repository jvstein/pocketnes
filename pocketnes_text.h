#ifndef __POCKETNES_TEXT_H__
#define __POCKETNES_TEXT_H__

#define FONT_FIRSTCHAR 288
#define FONT_CHAR_PAGE 0
#define FONT_PALETTE_NUMBER 4
#define UI_TILEMAP_NUMBER 6
#define SCREENBASE (u16*)((u8*)MEM_VRAM + UI_TILEMAP_NUMBER*2048 )
#define FONT_MEM (u16*)((u8*)MEM_VRAM + FONT_CHAR_PAGE*16384 + FONT_FIRSTCHAR*32 )
#define FONT_PAL (u16*)((u8*)MEM_PALETTE + FONT_PALETTE_NUMBER*16*2 )

extern u32 oldkey;
extern int selected;

extern int ui_x;
extern int ui_y;

void move_ui(void);


void loadfont(void);
void loadfontpal(void);
void get_ready_to_display_text(void);
u32 getmenuinput(int menuitems);
void cls(int chrmap);
void drawtext(int row,const char *str,int hilite);
void setdarknessgs(int dark);
void setbrightnessall(int light);
void waitkey(void);
void clearoldkey(void);

#endif
