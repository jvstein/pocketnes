PocketNES v9.99
-=-=-=-=-=-=-=-

It's a Nintendo Entertainment System (NES) emulator for the GameBoy Advance. 
But you already knew that, didn't you?


Getting Started
-=-=-=-=-=-=-=-

Before you can use PocketNES, you need to add some NES roms to the emulator.
You can do this with various tools (Thingy, NEStoGBA, etc.) found at
http://www.pocketnes.org/downloads.html.  Older tools (made for v7a) should
work fine, as long as you don't use any "SRAM slot" settings, as they aren't
needed anymore.
Make sure your flashing software allocates 64kByte/512kbit SRAM for PocketNES.


Controls
-=-=-=-=

Menu navigation:  Press L+R to open the menu, A to choose, B (or L+R again)
to cancel.

Unscaled modes:  L and R buttons scroll the screen up and down.

Scaled modes:  Press L+SELECT to adjust the background.

Speed modes:  L+START switches between throttled/unthrottled/slomo mode.

Quick load:  R+START loads the last savestate of the current rom.

Quick save:  R+SELECT saves to the last savestate of the current rom (or makes
a new one if none exist).

Sleep:  START+SELECT wakes up from sleep mode (activated from menu or 5
minutes of inactivity)


Speedhacks
-=-=-=-=-=-=-=-
First turn off Vsync, otherwise you won't notice any speed improvements. If
the Jump Hack or PPU Hack is enough to speed up the game, don't use the auto
speedhack detector.

Run the auto speedhack detector, then return to the game and watch it fly!
Great for RPGs, especially the Dragon Warrior series.

Example: Dragon Warrior 1 runs at 68 frames per second on the overworld. Turn
on autospeedhack, then the game runs at a blazing 317FPS!

For best results, look for hacks during gameplay.  Title screens often give
different, incorrect speedhacks.

Some games act funny with speedhacks turned on, especially Who Framed Roger
Rabbit.  There are a few gameplay bugs introduced when you enable the automatic
speedhacks, so instead use the PPU hack for that game, it will boost the
framerate to 65FPS.  Zelda 2 has scrolling glitches, just use the PPU Hack for
that game also.

Maniac mansion crashes if you turn on autospeedhacks. Turning them off won't
revive the game.


Cheat Finder
-=-=-=-=-=-=-=-
Now there's a cheat finder in PocketNES, just like the PC emulators.


Cheat Descriptions
-=-=-=-=-=-=-=-=-=-=-
Cheat descriptions are 15 characters, defaulting to all spaces. Pressing the
L-Button is equivalent to pressing Up 10 times.  Pressing the R-Button is
equivalent to pressing Down 10 times.


Other Stuff
-=-=-=-=-=-=-

Link transfer:  Sends PocketNES to another GBA.  The other GBA must be in
  multiboot receive mode (no cartridge inserted, powered on and waiting with
  the "GAME BOY" logo displayed).  Only one game can be sent at a time, and
  only if it's small enough to send (approx. 192kB or less). If you have
  problems with sending to many GBAs at the same time, try with only one.

Multi player link play:  Go to the menu and change Controller: to read
  "Link2P"/"Link3P"/"Link4P", depending on how many Gameboys you will use.
  Once this is done on all GBAs, leave the menu on all slaves first, then
  the master, the game will restart and you can begin playing.
  If the link is lost (cable is pulled out, or a GBA is restarted),
  link must be re-initiated, this is done by a restart on the master and
  then selecting the appropriate link and leave the menu. The slaves doesn't
  have to do anything.

Use an original Nintendo cable!

Pogoshell Plugin:
  If you wish to use PocketNES with Pogoshell, you can rename it to
  pocketnes.mb, or even better, compress it with the dcmp program that is
  included with Pogoshell, and name it "pocketnes.mbz". Also remember to
  change the Pogo config accordingly.

GameBoy Player:
  To be able to check for the GameBoy Player one must display the
  GameBoy Player logo, the easiest way to get it is by downloading it from my
  homepage. Otherwise you can rip it from any other game that displays it
  (SMA4 & Pokemon Pinball). There is no actuall use for it yet, but the check
  is there and I would appreciate if people could test it on their
  GameBoy Players, it says in the menu "PocketNES v9.98 on GBP".

Supports Mappers:
  0,1,2,3,4,5,7,9,11,15,16,17,18,19,21,23,25,32,33,34,40,42,64,65,66,67,68,69,
  70,71,72,73,74,75,76,78,79,80,86,87,92,93,94,97,99,105,118,119,151,152,180,
  228,232,245,249
  Just because PocketNES supports a mapper doesn't mean all games using that
  mapper works correctly.

Go Multiboot: You can use the Go Multiboot feature to force the game to run in
  multiboot mode.  Useful if you want to boot someone else up and eject the
  cartridge.  Do not eject cartridges from a GameBoy Player.


For more information, go to PocketNES - The Official Site at
http://www.pocketnes.org/
Also look at the PocketNES Message Board at
http://www.pocketheaven.com/boards/viewforum.php?f=21

Misc info:
-=-=-=-=-=-=
Jaleco/PCCW used PocketNES in their GBA game Jajamaru Jr. Denshouki to emulate
5 of their old NES games. It's ok, I just wish they had asked before.

Atlus has also use PocketNES for their Kuniokun collection as well.  Loopy got
a kind letter from one of the programmers, deeply thanking him for PocketNES.

Apparently Nintendo has been given a Japanese & US patent on
the scaling technique used in PocketNES it is;
US patent nr:20040053691. Filed January 3, 2003.
JP patent nr:2004-105311. Filed September 13, 2002.
The first version of PocketNES that used this kind of scaling came
out in November 2001.


! Thank you:
-=-=-=-=-=-=
Warder1 - page hosting, testing
Titney - page hosting, testing
reio-ta - coding help, testing
Costis - Multiplayer help
Chris Owens - Multiplayer testing
Markus Oberhumer - LZO compression library
Jeff Frohwein - MBV2
Yuichi Oda - xLA
Ben Parnell - FCEU src.
www.lik-sang.com - Flash Advance Linker
PocketNES forum - for all the support and ideas
nesdev community - you know

Many thanks to everyone who donated money - you know who you are.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Neal Tew
pocketnes@olimar.fea.st
http://www.pocketnes.org/

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Fredrik Olsson
flubba@passagen.se
http://hem.passagen.se/gba.html

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Dan Weiss
pocketnes + nospam at dwedit.cjb.net
http://dwedit.home.comcast.net/
