# About the MinUI Project

_MinUI is a custom launcher for the [Trimui Model S](http://www.trimui.com/) (aka the PowKiddy A66, sigh)._

![MinUI main menu](github/minui.png) ![MinUI in-emulator menu](github/libmmenu-sonic.png)

I love this little device. I think the hardware is great and that the official firmware has a lot of ambitious ideas. I even like its UI design. I just wish it were more focused on its unique strengths. Where it shines is handheld games (though home console emulation has come a long way since I originally wrote this). Game Boy. Pokémon Mini. Neo Geo Pocket. Game Gear. (Sorry Japanese friends, I have no experience with the Wonder Swan!) Anything that can be scaled at least 1.5x on its tiny 2" screen (sorry Game Boy Advance). I love that it offers a consistent in-game menu with access to save states (and system-wide volume and brightness button combos). But I think locking players out of each emulator's unique settings was a mistake. MinUI addresses those shortcomings.

You can [grab the latest version here](https://github.com/shauninman/MinUI/releases).

## About paks

In MinUI, applications, programs, or executables are called "paks". A pak is just a folder with the pak extension that contains a launch script. It may also contain an executable and resources required by that executable. 

When you open a rom from a console folder in Roms, MinUI runs the launch script in the corresponding pak in the Emus folder. For example, when you open /Roms/Game Boy/Tetris.gb, MinUI runs /Emus/Game Boy.pak/launch.sh which in turn launches /Emus/Game Boy.pak/gambatte-dms. You can rename the consoles in the Roms folder freely _but you must also rename the corresponding pak in the Emus folder._

Non-emulator programs live in Tools. Native games live in Games.


## For developers

I'd love for you to add the custom in-game menu to your emulator. It can be done in a way that allows the same binary run on non-MinUI devices too. Check out my [libmmenu repo](https://github.com/shauninman/libmmenu) for simple implementation details.

## Todo

- Add Collections
- Add map system
- Prepare relase with separate zip : Base, Emulators, Tools. Emulators standalone and picoarch

## Documentation

## Supported systems

| System | Emulator | Picoarch | Comment
| --- | --- | --- | --- |
| Arcade |  | mame2000 / fbalpha2012 |  |
| Atari Lynx | handy-rs97 |  |  |
| MSX |  | bluemsx / fmsx |  |
| NEC TurboGrafx-16 | temper | bettle-pce-fast |  |
| NEC TurboGrafx-CD | temper | bettle-pce-fast |  |
| Nintendo Entertainment System | fceux | fceumm / quicknes |  |
| Nintendo Game Boy | gambatte-dms | gambatte |  |
| Nintendo Game Boy Advance | picogpsp | gpsp |  |
| Nintendo Game Boy Color | gambatte-dms | gambatte |  |
| Nintendo Super Nintendo Entertainment System | snes9x2002 | snes9x2002 |  |
| Pokemon Mini | pokemini |  |  |
| Sega 32X | picodrive |  |  |
| Sega CD | picodrive |  |  |
| Sega Game Gear | sms_sdl | smsplus-gx |  |
| Sega Genesis | picodrive |  |  |
| Sega Master System | sms_sdl | smsplus-gx |  |
| SNK Neo Geo Pocket | race-od |  |  |
| SNK Neo Geo Pocket Color | race-od |  |  |
| Sony Playstation | pcsx_rearmed |  |  |
| WonderSwan | oswan |  |  |
| WonderSwan Color | oswan | bettle-pce-fast |  |


### Disabled a folder

You can hide ROM folders, just add `.disabled` in its name at the end.
