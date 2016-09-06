//based on Jeff Frohwein's slave boot demo:
//http://www.devrs.com/gba/files/mbclient.txt

#include <stdio.h>
#include "gba.h"

u8 *findrom(int);

extern u8 Image$$RO$$Limit;
extern u8 Image$$ZI$$Base;
extern u32 romnum;	//from cart.s
extern u8 *textstart;	//from main.c

extern char pogoshell;

romheader mb_header;

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

const u8 Client[]={
#include "client.h"
};

void DelayCycles (u32 cycles)
{
	__asm{mov r2, pc};
	__asm{lsr r2, #24};
	__asm{mov r1, #12};
	__asm{cmp r2, #0x02};
	__asm{beq MultiBootWaitCyclesLoop};

	__asm{mov r1, #14};
	__asm{cmp r2, #0x08};
	__asm{beq MultiBootWaitCyclesLoop};

	__asm{mov r1, #4};

	__asm{MultiBootWaitCyclesLoop:};
	__asm{sub r0, r1};
	__asm{bgt MultiBootWaitCyclesLoop};
}

int xfer(u32 send) {
	int i;
	REG_SIOMLT_SEND = send;
	DelayCycles(600);
	REG_SIOCNT = 0x2083;
	i=0x2000;
	while(--i>=0 && (REG_SIOCNT&0x80));
	return (REG_SIOMULTI1|i&0x80000000);	//return negative on timeout
}

int swi25(void *p) {
	__asm{mov r1,#1}
	__asm{swi 0x25, {r0-r1}, {}, {r0-r2} }
}

//returns error code:  2=bad send, 3=too big
#define TIMEOUT 40
int SendMBImageToClient(void) {
	MBStruct mp;
	u8 palette;
	int i,j,k;
	u8 key;
	u16 *p;
	u16 slaves;
	u16 ie;
	u32 emusize1,emusize2,romsize;

	p=(u16 *)&mp;
	for(i=0;i<38;i++)
		p[i]=0;

//	emusize=((u32)(&Image$$RO$$Limit)&0x3ffff)+((u32)(&Image$$RW$$Limit)&0x7fff);
	emusize1=((u32)(&Image$$RO$$Limit)&0x3ffff);
	emusize2=((u32)(&Image$$ZI$$Base)&0x7fff);
	if(pogoshell) romsize=48+16+(*(u8*)(findrom(romnum)+48+4))*16*1024+(*(u8*)(findrom(romnum)+48+5))*8*1024;  //need to read this from ROM
	else romsize=sizeof(romheader)+*(u32*)(findrom(romnum)+32);
	if(emusize1+romsize>max_multiboot_size) return 3;

	i=50;
	REG_RCNT=0;			//multi-comms
	do {
		j=xfer(0x6200);
	} while(--i && (j&0xfff0)!=0x7200);
	if(!i) return 2;

	slaves=(j&0xe);

	xfer(0x6100 + slaves);
	p=(u16*)0x2000000;
	for(i=0;i<96; i++) {		//send header
		xfer(*p);
		p++;
	}

	xfer(0x6200);
	xfer(0x6200 + slaves);
	mp.cb = slaves;
	mp.pc = 0xd1;
	mp.startp=(u8*)Client;
	i=sizeof(Client);
	i=(i+15)&~15;		//16 byte units
	mp.endp=(u8*)Client+i;

//8x=purple->blue
//9x=blue->emerald
//ax=emerald->green
//bx=green->yellow
//cx=yellow->red
//dx=red->purple
//ex=purple->white
	palette = 0xef;
	mp.palette = palette;

	xfer(0x6300+palette);
	xfer(0x6300+palette);
	key=0x11;
	key+=mp.cd[0]=REG_SIOMULTI1&0xff;
	key+=mp.cd[1]=REG_SIOMULTI2&0xff;
	key+=mp.cd[2]=REG_SIOMULTI3&0xff;
	mp.hs_data = key;
	xfer(0x6400 | key);

	ie=REG_IE;
	REG_IE=0;		//don't interrupt
	REG_DM0CNT_H=0;		//DMA stop
	REG_DM1CNT_H=0;
	REG_DM2CNT_H=0;
	REG_DM3CNT_H=0;

	if(swi25(&mp)){	//Execute BIOS routine to transfer client binary to slave unit
		i=2;
		goto transferEnd;
	}

	//now send everything else

	REG_RCNT=0;			//multi-comms
	i=100;
	j=(emusize1+emusize2+romsize)>>2;
	do {				//send size to client, wait for response
		DelayCycles(1000000);
		k=xfer(j);
	} while(--i && j!=k);

	if(!i) {				//client not responding?
		i=2;
		goto transferEnd;
	}

	p=(u16*)((u32)0x2000000);	//(from ewram.)

	do {					//send first part of emu
		j=xfer(*(p++));
		emusize1-=2;
	} while(emusize1 && j>=0);

	p=(u16*)0x3000000;			//(from iwram)
	do {					//send second part of emu
		j=xfer(*(p++));
		emusize2-=2;
	} while(emusize2 && j>=0);

	if(pogoshell)
	{
		mb_header.filesize=romsize;
		p=(u16*)&mb_header;	//send header
		for(i=0;i<sizeof(romheader);i+=2)
			xfer(*(p++));
		romsize-=sizeof(romheader);

		p=(u16*)findrom(romnum)+sizeof(romheader)/2;
	}
	else p=(u16*)findrom(romnum);
	do {				//send ROM
		j=xfer(*(p++));
		romsize-=2;
	} while(romsize && j>=0);
	i=0;
transferEnd:
	REG_IE=ie;
	return i;
}