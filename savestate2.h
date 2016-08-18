#ifndef __SAVESTATE2_H__
#define __SAVESTATE2_H__

#if !MOVIEPLAYER
void loadstate(int romnumber, u8* src, int statesize);
int savestate(u8 *dest);
#else
bool loadstate(const char *filename);
bool savestate(const char *filename);
#endif

#endif
