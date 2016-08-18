#ifndef __MAIN_H__
#define __MAIN_H__

extern u32 oldinput;
//extern const unsigned int __fp_status_arm;
extern u8 *textstart;//points to first NES rom (initialized by boot.s)
extern int roms;//total number of roms
extern int selectedrom;
extern char pogoshell_romname[32];	//keep track of rom name (for state saving, etc)
extern char pogoshell;
extern char rtc;
extern char gameboyplayer;
extern char gbaversion;
extern int ne;

#define PALTIMING 4

void C_entry(void);
void splash(void);
void get_saved_sram(void);
void rommenu(void);
u8 *findrom(int n);
int drawmenu(int sel);
int getinput(void);
void cls(int chrmap);
void drawtext(int row,char *str,int hilite);
void setdarknessgs(int dark);
void setbrightnessall(int light);

#endif
