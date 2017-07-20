# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New enemy ships: huge inquisition ship mk III and advanced huge inquisition
  ship mk III
- New goals: gain max reputation in 3 bases, gain max reputation in 5 bases,
  gain max reputation in 7 bases, gain max reputation in 10 bases, gain max
  reputation in 15 bases, gain max reputation in 20 bases, gain max reputation
  in 25 bases, gain max reputation in 50 bases, destroy 250 ships, destroy 500
  ships, destroy 1000 ships, destroy 1500 ships, destroy 2000 ships, destroy
  2500 ships, discover 1500 fields of map, discover 2000 fields of map,
  discover 2500 fields of map, discover 5000 fields of map, discover 7500
  fields of map, discover 10000 fields of map, visit 75 bases, visit 100 bases
  and visit 125 bases
- Hall of fame which made saves from previous version incompatible
- Charges for docking
- Info about amount of owned materials in crafting screen
- Option to set ship movement keys
- Option to set map manipulation keys
- Option to set menu shortcut keys
- Showing current keys in help
- Warnings about lack of fuel/food/drinks
- Warnings about low level of fuel/food/drinks
- Option to set when show warnings about low level fuel/food/drinks
- Limited and randomly changing amount of money in bases
- Limited and randomly changing amount of items in bases
- Showing current money name in help
- Showing current fuel name in help

### Changed
- Updated REAMDE.md
- Updated interface
- Updated help
- Updated MODDING.md
- Name of ship modules from cargo bay to small cargo bay

### Fixed
- Not working 'Wait Orders' entry in main menu
- Crafting interface
- Crash on redrawing main menu after resize screen
- Info about having materials/tools in crafting screen
- Typo in info about tools in crafting screen
- Crash in crafting screen when more than one tools is used in recipe
- Possible crash when showing help text
- Few misspellings in help
- Crash on showing ship cargo

## [1.3] - 2017-06-25

### Added
- New ship modules: huge steel engine and advanced huge steel engine
- New enemy ships: small pirates ship mk III, small undead ship mk III, small
  clockwork drone mk III, pirate ship mk III, armored pirate ship mk III, small
  attacking drone mk III, attacking clockwork drone mk III, armored attacking
  drone mk III, small inquisition ship mk III, inquisition ship mk III, armored
  inquisition ship mk III, large clockwork drone mk III, large pirate ship mk
  III, undead ship mk III, large undead ship mk III, large inquisition ship mk
  III, large attacking drone mk III, advanced attacking drone mk III, advanced
  pirate ship mk III, advanced undead ship mk III, advanced inquisition ship mk
  III, huge pirate ship mk III, advanced huge pirate ship mk III, huge undead
  ship mk III, huge attacking drone mk III, advanced huge undead ship mk III
  and advanced huge attacking drone mk III
- Info about amount of destroyed ships to game statistics
- Auto center map after set destination for player ship (and option to enable
  or disable it)
- Auto set skybase as player ship destination after finished mission (and
  option to enable or disable it)
- Auto finish missions when player ship is near corresponding skybase (and
  option to enable or disable it)
- End game after losing all fuel during fly
- Option to set location of game directories via console parameters
- Coloring messages which made saves from previous versions incompatible
- New type of missions: transport of passengers
- New random event: brawl in base
- Player goals (achievements)
- Option to resign from game
- More detailed info about finished missions in game statistics
- More detailed info about finished crafting orders in game statistics
- Random modules upgrades to enemy ships

### Changed
- Updated interface
- Fuel usage during bad weather event depends on ship engines fuel usage
- Updated help
- Amount of gained/lost reputation from finished missions
- Updated MODDING.md
- Ship require fuel to undock from base
- Updated README.md

### Fixed
- Crash in empty list of missions
- Typo in advanced huge iron engine description
- Don't finish mission if ship can't dock to base
- Showing info about event and mission on this same map cell
- Crash when asking for events in bases
- Count max allowed amount when selling items
- Changing workplace when manufacturing
- Searching for ammunition during combat for enemy ship
- User interface for buying recipes in bases
- Selling items in bases when more than one of that item type is in cargo
- Stop crafting orders when workplace module is destroyed
- Stop upgrading module when it is destroyed
- Crash when can't load game data
- Info about minimal screen size
- Gun for advanced inquisition ship mk II
- Gaining reputation with bases

## [1.2] - 2017-05-28

### Added
- New ship modules: small steel turret, steel battering ram, small steel
  battering ram, small advanced steel engine, medium steel engine, small
  advanced steel hull, medium steel hull, medium advanced steel engine,
  large steel engine, large advanced steel engine, small steel furnace,
  advanced medium steel hull, large steel hull, advanced large steel hull,
  steel armor, heavy steel armor, steel turret, small steel greenhouse,
  small steel water collector, small steel medical room, advanced steel cabin,
  extended steel cabin, luxury steel cabin, heavy steel turret, heavy steel
  battering ram, small steel workshop, huge steel hull and advanced huge steel
  hull
- Option to set which item type is used for delivery missions items
- Option to set which item type is used as drinks
- Option to set which item type is used as corpses
- Option to set which ship is used as player ship
- Option to set which item type is used as tools for upgrade/repair modules
- Option to set which item type is used as tools for cleaning ship
- Option to set which item type is used as tools for healing crew members or
  medicines delivery for diseased bases
- Option to set which item type is used as tools for for deconstructing items
- Option to set which items types are used as food by crew members
- Option to set which item type is used as fuel
- Option to set which item is used as moneys
- Ask for rest if needed after ship move
- Support for many help files
- Option to auto rest when pilot/engineer is too tired to work
- Ability to set game options in game
- Option to set default ship speed after undock from base
- Read starting recipes from ships data file
- Option to heal wounded crew members in bases
- Last 5 messages to sky map

### Changed
- Updated MODDING.md
- Faster gaining reputation in bases
- Gain more reputation from finished missions
- Updated interface
- Updated help
- Updated recipes data
- How ships speed is calculated to prevent some bugs
- Amount of gained/lost reputation from deliver medicines to diseased bases
  depends on amount of delivered medicines
- Updated README.md

### Fixed
- Counting enemy evasion during combat
- Crash in combat when chance to hit is very small
- Typo in small advanced iron engine description
- Don't start upgrades if no upgrading material in cargo
- Crashes on delivering medical supplies to bases
- Info about abandoned bases on map
- Showing others/missions messages
- Crash on removing damaged items
- Info about lack of food/drinks in ship cargo
- Showing this same deconstruct option few times
- Sending crew member on break on selling cabin
- Crash on damaging tools during ship upgrade
- Info about free/taken guns
- Gunner back to work from rest when more than one gun is used
- Crash on overloaded ship
- Crash when recipe don't have set difficulty
- Repair selected module in bases
- Crash on repair whole ship in bases
- Showing dialog with long messages
- Crash on updating population in bases
- Showing bases coordinates on bases list

## [1.1] - 2017-04-30

### Added
- New enemy ships: tiny inquisition ship mk II, small inquisition ship mk II,
  inquisition ship mk II, armored inquisition ship mk II, large clockwork drone
  mk II, large pirate ship mk II, undead ship mk II, large undead ship mk II,
  large inquisition ship mk II, large attacking drone mk II, advanced attacking
  drone mk II, advanced pirate ship mk II, advanced undead ship mk II,
  advanced inquisition ship mk II, huge pirate ship mk II, advanced huge pirate
  ship mk II, huge undead ship mk II, huge attacking drone mk II, advanced huge
  undead ship mk II, advanced huge attacking drone mk II, huge inquisition ship
  mk II and advanced huge inquisition ship mk II
- Support for many data files of this same objects types which made saves from
  1.0 incompatible
- Starting priorities of orders for player ship crew
- New ship modules: small steel hull, light steel armor, small steel engine,
  basic steel cabin, steel cockpit, small steel alchemy lab and steel cargo bay
- Fast auto travel option
- Option to wait selected by player minutes

### Changed
- Merged fields lootmin and lootmax in ships data
- Updated MODDING.md
- Reduced needed experience for next skill level
- Updated README.md
- Moved documentation to separated directory
- Impact of randomness in combat
- Updated help
- Updated interface

### Fixed
- Crash on buying recipes of items with zero price in bases
- Cursor mark on map
- Ship orders entry in main menu
- Read default player/ship name from configuration when none entered in new
  game form
- Some ships data
- Merging damaged items
- Recipes for Andrae and Illandru logs
- Killing gunner on direct hit in gun
- Removing gun on destroying turret
- Crash on read changelog file
- Counting player accuracy during combat
- Crash on player death from starvation/dehydration
