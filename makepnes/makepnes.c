/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
I'm tired of hearing people bitch and moan that PocketNES can't run
improperly created ROMs (imagine that!), so I've made some changes.
Yep, that means all existing menu maker tools are now obsolete.
Tough luck.

Format for PocketNES GBA images:
----
???? bytes:  POCKETNES.GBA contents
----
(optional) 76800 bytes:  Splash screen (raw 240x160 15bit image)
----
32 bytes:  ROM title (NULL terminated)
4 bytes:  ROM size
4 bytes:  ROM flags
4 bytes:  Sprite follow value
4 bytes:  Save slot (1 thru 8, 0 if unused)
???? bytes:  ROM contents (.NES format), word (4 byte) aligned
----
32 bytes:  Next ROM title
&tc, &tc ...
----

ROM flags are the same as before.  They are:
   bit 0: Enable speed hack #1 (speeds up some games)
   bit 1: Disable speed hack #2 (a few games need this to work)
   bit 4: Screen follows sprite (in unscaled mode)
   bit 5: Screen follows value at memory address


Easy enough?  I thought so.  Here's a SIMPLE utility for building your own
PocketNES.  NES ROMs to include are listed at the commandline.  For example:
"MAKEPNES A.NES B.NES C.NES" ...
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/

#include <stdio.h>
#include <string.h>

#define BUFFSIZE 4096
char buffer[BUFFSIZE];

struct {
	char name[32];
	int filesize;
	int flags;
	int spritefollow;
	int saveslot;
} rominfo={"",0,0,0,0};

void addROM(FILE *f_out,char *name) {
	int i;
	FILE *f_in;
	f_in=fopen(name,"rb");
	if(!f_in)  {
		printf("Can't open %s\n",name);
		return;
	}
	fseek(f_in,0,SEEK_END);
	rominfo.filesize=ftell(f_in)+3&~3;
	fseek(f_in,0,SEEK_SET);
	i=fread(buffer,1,BUFFSIZE,f_in);
	if(*(int*)buffer==0x1a53454e) { //iNES ID?
		strncpy(rominfo.name,name,29);
		fwrite(&rominfo,1,sizeof(rominfo),f_out);
	}
	while(i>3) {
		fwrite(buffer,1,i,f_out);
		i=fread(buffer,1,BUFFSIZE,f_in)+3&~3;
	}
	fclose(f_in);
	puts(name);
}

int main(int argc,char **argv) {
	FILE *f;
	int i;
	if(argc<2) {
		puts("Need some names, please...");
		return(-1);
	}
	f=fopen("PNES.GBA","wb");
	if(!f)
		return(-1);
	puts("Creating PNES.GBA...");
	addROM(f,"POCKETNES.GBA");
	for(i=1;i<argc;i++)
		addROM(f,argv[i]);
	fclose(f);
	return 0;
}