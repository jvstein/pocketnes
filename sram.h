#ifndef __SRAM_H__
#define __SRAM_H__

#include "cheat.h"

extern u32 sram_owner;

void loadstatemenu(void);
void writeconfig(void);
void readconfig(void);
void bytecopy(u8 *dst,u8 *src,int count);
u32 checksum(u8 *p);
void managesram(void);
void savestatemenu(void);
void quickload(void);
void quicksave(void);
int backup_nes_sram(int called_from);
void get_saved_sram(void);

#ifdef CHEATFINDER
void cheatload(void);
void cheatsave(void);
#endif


#endif
