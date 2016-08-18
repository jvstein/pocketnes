//based on Jeff Frohwein's slave boot demo:
//http://www.devrs.com/gba/files/mbclient.txt

#include <stdio.h>
#include "gba.h"

u8 *findrom(int);

extern u8 Image$$RO$$Limit;
extern u8 Image$$RW$$Limit;
extern u32 romnum;	//from cart.s
extern u8 *textstart;	//from main.c

u32 max_multiboot_size;		//largest possible multiboot transfer (init'd by boot.s)

typedef struct {
  u32 reserve1[5];      //
  u8 hs_data;           // 20 ($14) Needed by BIOS
  u8 reserve2;          // 21 ($15)
  u16 reserve3;         // 22 ($16)
  u8 pc;                // 24 ($18) Needed by BIOS
  u8 cd[3];             // 25 ($19)
  u8 palette;           // 28 ($1c) Needed by BIOS - Palette flash while load
  u8 reserve4;          // 29 ($1d) rb
  u8 cb;                // 30 ($1e) Needed by BIOS
  u8 reserve5;          // 31 ($1f)
  u8 *startp;           // 32 ($20) Needed by BIOS
  u8 *endp;             // 36 ($24) Needed by BIOS
  u8 *reserve6;         // 40 ($28)
  u8 *reserve7[3];      // 44 ($2c)
  u32 reserve8[4];      // 56 ($38)
  u8 reserve9;          // 72 ($48)
  u8 reserve10;         // 73 ($49)
  u8 reserve11;         // 74 ($4a)
  u8 reserve12;         // 75 ($4b)
} MBStruct;

const
#include "client.h"

void delay() {
	int i=32768;
	while(--i);	//(we're running from EXRAM)
}

u16 xfer(u32 send) {
	REG_SIOMLT_SEND = send;
	REG_SIOCNT = 0x2083;
	while(REG_SIOCNT & 0x80) {}
	return (REG_SIOMULTI1);
}

void swi25(void *p) {
	__asm{mov r1,#1}
	__asm{swi 0x250000, {r0-r1}, {}, {r0-r2,r8-r12} }
}

//returns error code:  1=no link, 2=bad send, 3=too big
#define TIMEOUT 40
int SendMBImageToClient(void) {
	MBStruct mp;
	u8 palette;
	u32 i,j;
	u16 key;
	u16 *p;
	u16 ie;
	u32 emusize,romsize;

	emusize=((u32)(&Image$$RO$$Limit)&0x3ffff)+((u32)(&Image$$RW$$Limit)&0x7fff);
	romsize=48+*(u32*)(findrom(romnum)+32);
	if(emusize+romsize>max_multiboot_size) return 3;

	REG_RCNT=0x8003;		//general purpose comms - sc/sd inputs
	i=TIMEOUT;
	while(--i && (REG_RCNT&3)==3) delay();
	if(!i) return 1;

	i=TIMEOUT;
	while(--i && (REG_RCNT&3)!=3) delay();
	if(!i) return 1;

	REG_RCNT=0;			//non-general purpose comms

	i=5;
	do {
		delay();
		j=xfer(0x6202);
	} while(--i && j!=0x7202);
	if(!i) return 2;

	xfer (0x6100);
	p=(u16*)0x2000000;
	for(i=0;i<96; i++) {		//send header
		xfer(*p);
		p++;
	}

	xfer(0x6202);
	mp.cb = 2;
	mp.pc = 0xd1;
	mp.startp=(u8*)Client;
	i=sizeof(Client);
	i=(i+15)&~15;		//16 byte units
	mp.endp=(u8*)Client+i;

	palette = 0xef;
//8x=purple->blue
//9x=blue->emerald
//ax=emerald->green
//bx=green->yellow
//cx=yellow->red
//dx=red->purple
//ex=purple->white
	mp.palette = palette;

	xfer(0x6300+palette);
	i=xfer(0x6300+palette);

	mp.cd[0] = i;
	mp.cd[1] = 0xff;
	mp.cd[2] = 0xff;

	key = (0x11 + (i & 0xff) + 0xff + 0xff) & 0xff;
	mp.hs_data = key;

	xfer(0x6400 | (key & 0xff));

	ie=REG_IE;
	REG_IE=0;		//don't interrupt
	REG_DM0CNT_H=0;		//DMA stop
	REG_DM1CNT_H=0;
	REG_DM3CNT_H=0;

	swi25(&mp);	//Execute BIOS routine to transfer client binary to slave unit

	//now send everything else

	REG_RCNT=0;			//non-general purpose comms
	while(xfer(0x99)!=0x99);	//wait til client is ready

	xfer(emusize+romsize);		//transmission size..
	xfer((emusize+romsize)>>16);

	p=(u16*)((u32)textstart&0xa000000);		//(from rom or ram?)
	for(;emusize;emusize-=2)	//send whole emu
		xfer(*(p++));
	p=(u16*)findrom(romnum);	//send ROM
	for(;romsize;romsize-=2)
		xfer(*(p++));
	REG_IE=ie;
	return 0;
}