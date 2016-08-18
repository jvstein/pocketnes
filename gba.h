#ifndef GBA_HEADER
#define GBA_HEADER

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned long u32;

typedef signed char s8;
typedef signed short s16;
typedef signed long s32;

#define NOSCALING 8	//from equates.h

#define MEM_PALETTE (u16*)0x5000000
#define MEM_VRAM (u16*)0x6000000
#define MEM_OAM (u32*)0x7000000
#define MEM_IRQVECT *(u32*)0x3007FFC

#define SCREENBASE (u16*)0x6003800

#define REG_DISPCNT *(volatile u32*)0x4000000
#define MODE0 0
#define MODE1 1
#define MODE2 2
#define MODE3 3
#define MODE4 4
#define MODE5 5
#define OBJ_H_STOP 0x20
#define OBJ_1D 0x40
#define FORCE_BLANK 0x80
#define BG0_EN 0x100
#define BG1_EN 0x200
#define BG2_EN 0x400
#define BG3_EN 0x800
#define OBJ_EN 0x1000
#define WINDOW0_EN 0x2000
#define WINDOW1_EN 0x4000
#define OBJ_WINDOW_EN 0x8000

#define REG_DISPSTAT *(volatile u16*)0x4000004
#define SCANLINE *(volatile u8*)0x4000005
#define VBLANK 1
#define HBLANK 2
#define VCOUNT_HIT 4
#define V_IRQ 8
#define H_IRQ 16
#define VCOUNT_IRQ 32

#define REG_BG2HOFS *(u16*)0x4000018
#define REG_BG2VOFS *(u16*)0x400001a
#define REG_BG2CNT *(u16*)0x400000c
#define COLOR16 0x0000
#define COLOR256 0x0080
#define SIZE256x256 0x0000
#define SIZE512x256 0x4000
#define SIZE256x512 0x8000
#define SIZE512x512 0xC000

#define REG_VCOUNT *(volatile u16*)0x4000006

#define REG_IE *(u16*)0x4000200
#define V_IRQ_EN 1
#define H_IRQ_EN 2
#define VCOUNT_IRQ_EN 4
#define TIMER0_IRQ_EN 8
#define TIMER1_IRQ_EN 16
#define TIMER2_IRQ_EN 32
#define TIMER3_IRQ_EN 64
#define SERIAL_IRQ_EN 128
#define DMA0_IRQ_EN 0x100
#define DMA1_IRQ_EN 0x200
#define DMA2_IRQ_EN 0x400
#define DMA3_IRQ_EN 0x800
#define KEY_IRQ_EN 0x1000
#define CART_IRQ_EN 0x2000

#define REG_IF *(volatile u16*)0x4000202
#define V_IRQ_ACK 1
#define H_IRQ_ACK 2
#define VCOUNT_IRQ_ACK 4
#define TIMER0_IRQ_ACK 8
#define TIMER1_IRQ_ACK 16
#define TIMER2_IRQ_ACK 32
#define TIMER3_IRQ_ACK 64
#define SERIAL_IRQ_ACK 128
#define DMA0_IRQ_ACK 0x100
#define DMA1_IRQ_ACK 0x200
#define DMA2_IRQ_ACK 0x400
#define DMA3_IRQ_ACK 0x800
#define KEY_IRQ_ACK 0x1000
#define CART_IRQ_ACK 0x2000

#define REG_P1 *(volatile u16*)0x4000130
#define A_BTN 1
#define B_BTN 2
#define SELECT 4
#define START 8
#define RIGHT 16
#define LEFT 32
#define UP 64
#define DOWN 128
#define R_BTN 256
#define L_BTN 512

#define REG_DM0CNT_H *(u16*)0x40000ba
#define REG_DM1CNT_H *(u16*)0x40000c6
#define REG_BLDMOD *(u16*)0x4000050
#define REG_COLY *(u16*)0x4000054
#define REG_SGCNT0_L *(u16*)0x4000080
#endif
