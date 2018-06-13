## General Info

Steam Sky is an open source roguelike with a steampunk setting. Your a commander of a flying ship, 
as leader you will be traveling across floating bases, engaging in combat, trading goods etc...
There is no ending to this game, the game continues until your character dies. The game is currently 
under heavy development, but is in a playable state. Steam Sky is available on Linux 64-bit and Windows 
(development version only) platforms.

## Game versions
There are currently 2 versions of the game:
- 2.0.x: "stable" version of game. This version will receive bug fixes but
  no new features. Source code for this version is in *2.0* branch.
- 2.x: "development" version of game, future version 3.0. This is where 
game feature updates will happen. Due to new features, save comaptibility 
will typically break between releases. Use this version at your own risk. 
Source code for this version is in the *master* branch.

## Build game from sources

To build(works on Linux and Windows too) you need:

* compiler - GCC with enabled Ada support or (best option) GNAT from: 
  
  https://www.adacore.com/download/

  It is recommended to use GNAT GPL 2017 to compile the game on linux.
  Game does not work with old compilers (like GCC 4.9) since it 
  lacks full support for ada 2012

* GtkAda library which should be available in most Linux distributions. Best
  option is to use (with GNAT GPL) AdaCore version of GtkAda from:
  
  https://www.adacore.com/download/more

  At this moment tested version of GtkAda is 2017 and game require GTK library
  in version 3.14 (may not works with other versions).

If you have all the required packages, navigate to the main directory(where this file is)
to compile:

* Easiest way to compile game is use Gnat Programming Studio included in GNAT. 
  Just run GPS, select *steamsky.gpr* as a project file and select option `Build
  All`.

* If you prefer using console: in main source code directory type `gprbuild` 
  for debug mode build or for release mode: `gprbuild -XMode=release`


## Running Steam Sky

### Linux
If you use downloaded binaries, you don't need any additional libraries. Just
run `steamsky` program to start game.

### Windows
If you compiled the game just clicking on `steamsky.exe` should run it

### Starting parameters
You can set game directories by using starting parameters. Possible options are:

* --datadir=[directory] set directory where all game data files (and
  directories like ships, items, etc.) are. Example: `./steamsky
  --datadir=/home/user/game/tmp`. Default value is *data/*

* --savedir=[directory] set directory where game (or logs) will be saved. Game
  must have write permission to this directory. Example: `./steamsky
  --savedir=/home/user/.saves`. Default value is *data/*

* --docdir=[directory] set directory where game documentation is (at this
  moment important only for license and changelog files). Example `./steamsky
  --docdir=/usr/share/steamsky/doc`. Default value is *doc/*.

* --libdir=[directory] set directory where libraries needed for game are (this
  works only on Linux). Example `./steamsky --libdir=/lib`. Default value is 
  *../lib/*.

* --etcdir=[directory] set directory where are GTK config files are (this works
  only on Linux). Path must be absolute to file `steamsky`. Example `./steamsky
  --etcdir=/home/user/tmp/etc`. Default value is 
  *[path to game directory]/etc/*.

Of course, you can set all parameters together: `./steamsky --datadir=somedir/
--savedir=otherdir/ --docdir=anotherdir/`

Paths to directories can be absolute or relative where file `steamsky` is. For
Windows, use `steamsky.exe` instead `./steamsky`.

## Modding Support
For detailed informations about modifying various game elements or debugging the
game, see [MODDING.md](bin/doc/MODDING.md)

## Contributing to project
For detailed informations about contributing to the project (bugs reporting, ideas
propositions, code conduct, etc), see [CONTRIBUTING.md](bin/doc/CONTRIBUTING.md)

## License
Game is available under [GPLv3](bin/doc/COPYING) license.

More documentation about game (changelog, license) you can find in
[doc](bin/doc) directory.

That's all for now, as usual, probably I forgot about something important ;)

Bartek thindil Jasicki
