#ifndef __CONFIG_H__
#define __CONFIG_H__

//#define VERSION_NUMBER "X alpha 3"
#define VERSION_NUMBER "11-10-08"
//#define VERSION_NUMBER "DO NOT RELEASE"

#if defined COMPY
//For PocketNES Compy
#define LINK 0
#define USE_GAME_SPECIFIC_HACKS 0
#define USE_ACCELERATION 0
#define CHEATFINDER 0
#define MIXED_VRAM_VROM 0
#define EDITFOLLOW 0
#define BRANCHHACKDETAIL 0
#define RTCSUPPORT 0
#define GBAMPSAVE 0
#define SAVE 0
#define SAVE32 0
#define SAVE_FORBIDDEN 0
#define GOMULTIBOOT 0
#define MULTIBOOT 0
#define MOVIEPLAYER 0
#define EDITBRANCHHACKS 0
#elif defined GBAMP
//For PocketNES GBAMP
#define LINK 1
#define USE_GAME_SPECIFIC_HACKS 1
#define USE_ACCELERATION 1
#define CHEATFINDER 0
#define MIXED_VRAM_VROM 1
#define EDITFOLLOW 1
#define BRANCHHACKDETAIL 1
#define RTCSUPPORT 0
#define GBAMPSAVE 1
#define SAVE 0
#define SAVE32 0
#define SAVE_FORBIDDEN 0
#define GOMULTIBOOT 0
#define MULTIBOOT 0
#define MOVIEPLAYER 1
#define EDITBRANCHHACKS 0
#else
//For regular PocketNES
#define LINK 1
#define USE_GAME_SPECIFIC_HACKS 1
#define USE_ACCELERATION 1
#define CHEATFINDER 1
#define MIXED_VRAM_VROM 1
#define EDITFOLLOW 1
#define BRANCHHACKDETAIL 1
#define RTCSUPPORT 1
#define GBAMPSAVE 1
#define SAVE 1
#define SAVE_FORBIDDEN 0
#define GOMULTIBOOT 0
#define MULTIBOOT 0
#define MOVIEPLAYER 0
#define EDITBRANCHHACKS 0
	#ifdef NOCASH
	#define SAVE32 1
	#else
	#define SAVE32 0
	#endif
#endif

#ifndef GCC
#define GCC 0
#endif

#endif