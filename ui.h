#ifndef __UI_H__
#define __UI_H__

#define VERSION_NUMBER "v9.99"

extern u8 autoA,autoB;				//0=off, 1=on, 2=R
extern u8 stime;
extern u8 autostate;

extern int cheatfinderstate;
extern int num_cheats;
extern const int MAX_CHEATS; // 900/18
extern u8 compare_value;
extern int found_for[7];
extern int selected;//selected menuitem.  used by all menus.
extern int mainmenuitems;//? or CARTMENUITEMS, depending on whether saving is allowed

extern u32 oldkey;


extern const char MENUXITEMS[];

extern const fptr multifnlist[];
extern const fptr fnlist1[];
extern const fptr fnlist2[];
extern const fptr fnlist2[];

extern const fptr fnlist3[];
extern const fptr fnlist4[];
extern const fptr fnlist5[];

extern const fptr* fnlistX[];
extern const fptr* fnlistX[];

extern const fptr drawuiX[];

extern char *const autotxt[];
extern char *const vsynctxt[];
extern char *const sleeptxt[];
extern char *const brightxt[];
extern char *const ctrltxt[];
extern char *const disptxt[];
extern char *const flicktxt[];
extern char *const cntrtxt[];
extern char *const followtxt[];
extern char *const followtxt2[];
extern char *const branchtxt[];
extern char *const emuname[];

extern u32 *const speedhack_buffers[];
extern const u8 hacktypes[];
extern const int num_speedhack_buffers;

void drawui1(void);
void drawui2(void);
void drawui3(void);
void drawui4(void);
void drawui5(void);

u32 getmenuinput(int menuitems);
void subui(int menunr);
void ui(void);
void ui2(void);
void ui3(void);
void ui4(void);
void ui5(void);
void text(int row,char *str);
void text2(int row,char *str);
void strmerge(char *dst,char *src1,char *src2);
void strmerge3(char *dst,char *src1,char *src2, char *src3);
void strmerge4(char *dst,char *src1,char *src2, char *src3, char *src4);
char *hexn(unsigned int n, int digits);
__inline char *hex4(short n) {	return hexn(n,4); }
void drawclock(void);
void autoAset(void);
void autoBset(void);
void controller(void);
void sleepset(void);
void vblset(void);
void fpsset(void);
void brightset(void);
void multiboot(void);
void restart(void);
void exit(void);
void sleep(void);
void fadetowhite(void);
void scrolll(int f);
void scrollr(void);
void swapAB(void);
void display(void);
void flickset(void);
void autostateset(void);
void autostateset2(void);
void bajs(void);
void paltoggle(void);
void cpuhacktoggle(void);
void ppuhacktoggle(void);
void followramtoggle(void);
void draw_input_text(int row, int column, char* str, int hilitedigit);
u32 inputhex(int row, int column, u32 value, u32 digits);
void inputtext(int row, int column, char *text, u32 length);
void selectfollowaddress(void);
void changehackmode(void);
void changebranchlength(void);
int getbranchhacknumber(void);
char *number(unsigned short n);
void autodetect_speedhack(void);
void find_best_speedhack(void);
void update_cheatfinder_tally(void);
void reset_cheatfinder(void);
void cheat_memcopy(void);
void write_byte(u8 *address, u8 data);
int add_cheat(u16 address, u8 value);
char* real_address(u16 addr);
void do_cheats(void);
void do_cheat_test(u32 testfunc);
void cf_equal(void);
void cf_notequal(void);
void cf_greater(void);
void cf_less(void);
void cf_greaterequal(void);
void cf_lessequal(void);
void cf_comparewith(void);
void cf_update(void);
void cf_newsearch(void);
int cf_next_result(int i);
int cf_result(int n);
void cf_drawresults(void);
void cf_results(void);
void cf_drawedit(int center);
void edit_cheat(int cheatnum);
void delete_cheat(int i);
void cf_editcheats(void);
void go_multiboot(void);

#endif
