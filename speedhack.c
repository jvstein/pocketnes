#include "includes.h"

#if EDITBRANCHHACKS
void changehackmode(void)
{
	char t=(hackflags&0xF0);
	char l=(hackflags&0x0F);
	if (t==0x00)
	{
		t=0x10; l=4;
	}
	else if (t==0x10)
	{
		t=0xD0;
	}
	else if (t==0xD0)
	{
		t=0xF0;
	}
	else if (t==0xF0)
	{
		t=0x00;
		l=0;
	}
	hackflags=t|l;
	cpuhack_reset();
}
void changebranchlength(void)
{
	//sheer laziness... hit A to increment
	char t=(hackflags&0xF0);
	char l=(hackflags&0x0F);
	if (t==0) return;
	l++;
	l&=0xF;
	hackflags=t|l;
	cpuhack_reset();
}
#endif

#if BRANCHHACKDETAIL
int getbranchhacknumber(void)
{
	u8 t=hackflags;
	if (t==0x4C) return 9;
	t=t&0xF0;
	return ((int)t+0x10)/0x20;
}
#endif


u32*const speedhack_buffers[]=
{
	SPEEDHACK_FIND_BPL_BUF,
	SPEEDHACK_FIND_BMI_BUF,
	SPEEDHACK_FIND_BVC_BUF,
	SPEEDHACK_FIND_BVS_BUF,
	SPEEDHACK_FIND_BCC_BUF,
	SPEEDHACK_FIND_BCS_BUF,
	SPEEDHACK_FIND_BNE_BUF,
	SPEEDHACK_FIND_BEQ_BUF,
	SPEEDHACK_FIND_JMP_BUF
};
const u8 hacktypes[]={
	0x10,
	0x30,
	0x50,
	0x70,
	0x90,
	0xB0,
	0xD0,
	0xF0,
	0x4C
};
const int num_speedhack_buffers=9;

__inline void clear_speedhack_find_buffers(void)
{
	int i;
	for (i=0;i<num_speedhack_buffers;i++)
	{
		memset (speedhack_buffers[i],0,128);
	}
}
void autodetect_speedhack(void)
{
	int oldvblank;
	hackflags3=0;
	if (hackflags==0)
	{
		clear_speedhack_find_buffers();
		hackflags=1;
		cpuhack_reset();
		oldvblank=novblankwait;  //preserve vblank
		
#if SAVE
		//Ensure that game has SRAM before running
		if (get_sram_owner()==0)
		{
			get_saved_sram();
		}
		writeconfig();			//save any changes
#endif
		
		run(0);
		
#if SAVE
		{
			//If game changed sram, save it now.
			int savesuccess=backup_nes_sram(1);
			if (!savesuccess)
			{
				drawui1();
				REG_BG2HOFS=0;
			}
		}
#endif		
		
		
		
		novblankwait=oldvblank;
		dontstop=1;
		find_best_speedhack();
	}
	else // if (hackflags!=1)  //no more deleayed searches
	{
		hackflags=0;
		cpuhack_reset();
	}
}


void find_best_speedhack(void)
{
	unsigned int max=0,val,branchlength;
	int hacktype=-1;
	int h;
	u32 *arr;
	int i,maxindex=-1;
	for (h=0;h<num_speedhack_buffers;h++)
	{
		arr=speedhack_buffers[h];
		for (i=0;i<32;i++)
		{
			val=arr[i];
			if (val>max)
			{
				maxindex=i;
					hacktype=h;
				max=val;
			}
		}
	}
	
	if (hacktype>-1)
	{
		branchlength=maxindex+2;
		hacktype=hacktypes[hacktype];
		if (hacktype==0x4C)
		{
			branchlength-=2;
		}
		hackflags=hacktype;
		hackflags2=branchlength;
		cpuhack_reset();
	}
	else
	{
		hackflags=0;
		cpuhack_reset();
	}
}

void drawui4()
{
	int row=0;
	cls(2);
	drawtext(32,"        Speed Hacks",0);
	print_2("PPU Hack: ",autotxt[emuflags&1]);
	print_2("JMP Hack: ",autotxt[!(emuflags&2)]);
	print_2("Full-Auto speedhacks: ",autotxt[hackflags3!=0]);
	if (hackflags==0)
	{
		print_2_1("Autodetect Speed Hack");
	}
//	else if (hackflags==1)  //removed, no longer needed
//	{
//		strcpy(str,"Play the game for 1 second");
//		text2(2,str);
//	}
	else
	{
		print_2_1("Remove Speed Hack");
	//	}
	//	if (hackflags<16)
	//	{
	////		strcpy(str,"Manually set Speed Hack");
	////		text2(3,str);
	//	}
	//	else
	//	{
		#if BRANCHHACKDETAIL
		print_2("Branch Hack: ",branchtxt[getbranchhacknumber()]);
		print_2("Branch Length: ",number(hackflags2));
		#endif
	}
}

int quickhackfinder(u8 *pc)
{
	//look within next 6 bytes for a branch
	int i;
	u8 ins,bl;
	
	for (i=0;i<6;i++)
	{
		ins=pc[i];
		if ((ins&0x1F) == 0x10)
		{
			i++;
			bl = pc[i];
			if (bl>=0xFB) //bne -5 to -1
			{
				hackflags=ins;
				hackflags2=256-bl;
				cpuhack_reset();
			}
			else
			{
				break;
			}
		}
	}
//	if (hackflags!=0)
//	{
//		hackflags=0;
//		cpuhack_reset();
//	}
	
	return 0;
	
}
void setjmp0hack()
{
	hackflags=0x4C;
	hackflags2=0;
	cpuhack_reset();
}
