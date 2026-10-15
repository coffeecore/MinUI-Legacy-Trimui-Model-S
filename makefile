JOBS ?= 2
export JOBS

# minui/makefile

.PHONY: clean

BUILD_TIME!=date +%Y%m%d
RELEASE_PATH=./release
RELEASE_BASE=MinUI-$(BUILD_TIME)
RELEASE_DOT!=find release/. -name "$(RELEASE_BASE)*.zip" -printf '.' | wc -m
RELEASE_NAME=$(RELEASE_BASE)-$(RELEASE_DOT)
BUILD_PATH=./build
PAYLOAD_PATH=$(BUILD_PATH)/PAYLOAD
ROMS_PATH=$(BUILD_PATH)/Roms

PICOARCH_SOURCE := $(CURDIR)/third-party/picoarch
PICOARCH_MAKE_ARGS := \
	platform=trimui \
	CROSS_COMPILE=$(CROSS_COMPILE) \
	CXX=$(CROSS_COMPILE)g++ \
	CC_FOR_BUILD=gcc \
	CXX_FOR_BUILD=g++

CROSS_COMPILE ?= /opt/trimui-toolchain/bin/arm-buildroot-linux-gnueabi-
SYSROOT ?= /opt/trimui-toolchain/arm-buildroot-linux-gnueabi/sysroot

#--------------------------------------
all: readme sys emus tools zip
#--------------------------------------

lib:
	cd ./src/libmsettings && make
	cd ./src/libmmenu && make

readme:
	mkdir -p "$(BUILD_PATH)"
	echo "$(RELEASE_NAME)" > "$(BUILD_PATH)/version.txt"
	fmt -w 40 -s "src/MinUI/readme.txt" > "$(BUILD_PATH)/readme.txt"

sys: lib
	mkdir -p "$(PAYLOAD_PATH)"
	mkdir -p "$(PAYLOAD_PATH)/System"
	mkdir -p "$(PAYLOAD_PATH)/System/bin"
	mkdir -p "$(PAYLOAD_PATH)/System/lib"
	echo "$(RELEASE_NAME)" > "$(PAYLOAD_PATH)/System/version.txt"
	cd ./third-party/SDL-1.2 && ./make.sh
	cd ./TrimuiUpdate/ && make
	cp -R ./TrimuiUpdate/installer/. "$(PAYLOAD_PATH)"
	cd ./src/keymon && make
	cd ./src/MinUI && make
	cd ./src/show && make
	cd ./src/confirm && make
	cd ./src/flipbook && make
	cp -R "paks/System.pak" 			"$(PAYLOAD_PATH)/System"
	cp -R "paks/Update.pak" 			"$(PAYLOAD_PATH)/System"
	cp "src/MinUI/MinUI" 				"$(PAYLOAD_PATH)/System/System.pak"
	cp -R "res" "$(PAYLOAD_PATH)/System"
	cp "src/show/show" 						"$(PAYLOAD_PATH)/System/bin"
	cp "src/confirm/confirm" 				"$(PAYLOAD_PATH)/System/bin"
	cp "src/flipbook/flipbook" 				"$(PAYLOAD_PATH)/System/bin"
	cp "src/keymon/keymon"					"$(PAYLOAD_PATH)/System/bin"
	cp "src/needs-swap.sh"					"$(PAYLOAD_PATH)/System/bin/needs-swap"
	cp "src/libmsettings/libmsettings.so"	"$(PAYLOAD_PATH)/System/lib"
	cp "src/libmmenu/libmmenu.so"			"$(PAYLOAD_PATH)/System/lib"
	cp "third-party/SDL-1.2/build/.libs/libSDL-1.2.so.0.11.5" "$(PAYLOAD_PATH)/System/lib/libSDL-1.2.so.0"

#--------------------------------------
emus: gb pm ngp gg snes ps gba nes gen pce swan lynx standalone-emus

standalone-emus: gx4000 stella retro8 gngeo
#--------------------------------------

emu:
	mkdir -p "$(PAYLOAD_PATH)/Emus"

gb: emu
	mkdir -p "$(ROMS_PATH)/Game Boy"
	cd ./third-party/gambatte-dms && $(MAKE) -j$(JOBS)
	cp -R "paks/Game Boy.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/gambatte-dms/gambatte-dms" "$(PAYLOAD_PATH)/Emus/Game Boy.pak"
	
	mkdir -p "$(ROMS_PATH)/Game Boy Color"
	cp -R "paks/Game Boy Color.pak" "$(PAYLOAD_PATH)/Emus"

pm: emu
	mkdir -p "$(ROMS_PATH)/Pokemon Mini"
	cd ./third-party/pokemini/platform/trimui && $(MAKE) -j$(JOBS)
	cp -R "paks/Pokemon Mini.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/pokemini/platform/trimui/pokemini" "$(PAYLOAD_PATH)/Emus/Pokemon Mini.pak"

ngp: emu
	mkdir -p "$(ROMS_PATH)/Neo Geo Pocket"
	cd ./third-party/race && $(MAKE) -j$(JOBS)
	cp -R "paks/Neo Geo Pocket.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/race/race-od" "$(PAYLOAD_PATH)/Emus/Neo Geo Pocket.pak"
	
	mkdir -p "$(ROMS_PATH)/Neo Geo Pocket Color"
	cp -R "paks/Neo Geo Pocket Color.pak" "$(PAYLOAD_PATH)/Emus"

gg: emu
	mkdir -p "$(ROMS_PATH)/Game Gear"
	cd ./third-party/sms_sdl && $(MAKE) -j$(JOBS)
	cp -R "paks/Game Gear.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/sms_sdl/sms_sdl" "$(PAYLOAD_PATH)/Emus/Game Gear.pak"
	
	mkdir -p "$(ROMS_PATH)/Master System"
	cp -R "paks/Master System.pak" "$(PAYLOAD_PATH)/Emus"

snes: emu
	mkdir -p "$(ROMS_PATH)/Super Nintendo"
	cd ./third-party/snes9x2002 && $(MAKE) -j$(JOBS)
	cp -R "paks/Super Nintendo.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/snes9x2002/snes9x2002" "$(PAYLOAD_PATH)/Emus/Super Nintendo.pak"

ps: emu
	mkdir -p "$(ROMS_PATH)/PlayStation"
	if [ ! -f ./third-party/pcsx_rearmed/config.mak ]; then cd ./third-party/pcsx_rearmed && CROSS_COMPILE=/opt/trimui-toolchain/bin/arm-buildroot-linux-gnueabi- ./configure --platform=trimui; fi
	cd ./third-party/pcsx_rearmed && $(MAKE) -j$(JOBS)
	cp -R "paks/PlayStation.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/pcsx_rearmed/pcsx" "$(PAYLOAD_PATH)/Emus/PlayStation.pak"

gba: emu
	mkdir -p "$(ROMS_PATH)/Game Boy Advance"
	cd ./third-party/picogpsp && $(MAKE) -j$(JOBS)
	cp -R "paks/Game Boy Advance.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/picogpsp/picogpsp" "$(PAYLOAD_PATH)/Emus/Game Boy Advance.pak"
	
nes: emu
	mkdir -p "$(ROMS_PATH)/Nintendo"
	cd ./third-party/fceux && $(MAKE) -j$(JOBS)
	cp -R "paks/Nintendo.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/fceux/fceux/fceux.dge" "$(PAYLOAD_PATH)/Emus/Nintendo.pak"
	cp "third-party/fceux/fceux/backdrop.png" "$(PAYLOAD_PATH)/Emus/Nintendo.pak"
	cp "third-party/fceux/fceux/sp.bmp" "$(PAYLOAD_PATH)/Emus/Nintendo.pak"
	cp -R "third-party/fceux/fceux/palettes" "$(PAYLOAD_PATH)/Emus/Nintendo.pak"

gen: emu
	mkdir -p "$(ROMS_PATH)/Genesis"
	mkdir -p "$(ROMS_PATH)/Sega CD"
	mkdir -p "$(ROMS_PATH)/Sega 32X"
	if [ ! -f ./third-party/picodrive/config.mak ]; then cd ./third-party/picodrive && CROSS_COMPILE=/opt/trimui-toolchain/bin/arm-buildroot-linux-gnueabi- ./configure --platform=trimui; fi
	cd ./third-party/picodrive && $(MAKE) -j$(JOBS)
	cp -R "paks/Genesis.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/Sega CD.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/Sega 32X.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/picodrive/PicoDrive" "$(PAYLOAD_PATH)/Emus/Genesis.pak"
	cp -R "third-party/picodrive/platform/trimui/skin" "$(PAYLOAD_PATH)/Emus/Genesis.pak"

pce: emu
	mkdir -p "$(ROMS_PATH)/TurboGrafx-16"
	mkdir -p "$(ROMS_PATH)/TurboGrafx-CD"
	cd ./third-party/temper/SDL && $(MAKE) -j$(JOBS)
	cp -R "paks/TurboGrafx-16.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/TurboGrafx-CD.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/temper/SDL/temper" "$(PAYLOAD_PATH)/Emus/TurboGrafx-16.pak"

swan: emu
	mkdir -p "$(ROMS_PATH)/WonderSwan"
	mkdir -p "$(ROMS_PATH)/WonderSwan Color"
	cd ./third-party/oswan && $(MAKE) -j$(JOBS)
	cp -R "paks/WonderSwan.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/WonderSwan Color.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/oswan/oswan" "$(PAYLOAD_PATH)/Emus/WonderSwan.pak"

lynx: emu
	mkdir -p "$(ROMS_PATH)/Lynx"
	cd ./third-party/handy-rs97 && $(MAKE) -j$(JOBS)
	cp -R "paks/Lynx.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/handy-rs97/handy" "$(PAYLOAD_PATH)/Emus/Lynx.pak"

gx4000: lib emu
	mkdir -p "$(ROMS_PATH)/GX4000"
	cd ./third-party/arnold && $(MAKE) -j$(JOBS)
	cp -R "paks/GX4000.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/arnold/arnold" "$(PAYLOAD_PATH)/Emus/GX4000.pak/arnold"

stella: emu
	mkdir -p "$(ROMS_PATH)/Atari 2600"
	test -f "$(SYSROOT)/usr/lib/libSDL.a"
	test -f "$(SYSROOT)/usr/lib/libpng.a"
	cp "configs/stella.mak" "third-party/stella/config.mak"
	cd ./third-party/stella && $(MAKE) -j$(JOBS) \
		CROSS_COMPILE="$(CROSS_COMPILE)" \
		SYSROOT="$(SYSROOT)"
	cp -R "paks/Atari 2600.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/stella/stella" "$(PAYLOAD_PATH)/Emus/Atari 2600.pak/stella"

retro8: emu
	mkdir -p "$(ROMS_PATH)/PICO-8"
	cd ./third-party/retro8 && $(MAKE) -j$(JOBS)
	cp -R "paks/PICO-8.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/retro8/retro8" "$(PAYLOAD_PATH)/Emus/PICO-8.pak/retro8"

gngeo: lib emu
	mkdir -p "$(ROMS_PATH)/Neo Geo"
	test -f "$(SYSROOT)/usr/lib/libts-1.0.so.0"
	test -f "$(SYSROOT)/usr/lib/libz.so.1"
	cd ./third-party/gngeo && $(MAKE) -f Makefile.trimui \
		CROSS_COMPILE="$(CROSS_COMPILE)" \
		SYSROOT="$(SYSROOT)" \
		MMENU_DIR="$(CURDIR)/src/libmmenu"
	cp -R "paks/Neo Geo.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/gngeo/gngeo" "$(PAYLOAD_PATH)/Emus/Neo Geo.pak/gngeo"
	mkdir -p "$(PAYLOAD_PATH)/Emus/Neo Geo.pak/lib"
	cp -L $(SYSROOT)/usr/lib/libts-1.0.so* \
		"$(PAYLOAD_PATH)/Emus/Neo Geo.pak/lib/"
	cp -L "$(SYSROOT)/usr/lib/libz.so.1" \
		"$(PAYLOAD_PATH)/Emus/Neo Geo.pak/lib/libz.so.1"
	@if [ -d "$(SYSROOT)/usr/lib/ts" ]; then \
		cp -aL "$(SYSROOT)/usr/lib/ts" \
			"$(PAYLOAD_PATH)/Emus/Neo Geo.pak/lib/"; \
	fi

#--------------------------------------
tools: bridge commander reload stock tips clock # zero
#--------------------------------------

tool:
	mkdir -p "$(PAYLOAD_PATH)/Tools"

bridge: tool
	cp -R "paks/USB Bridge.pak" "$(PAYLOAD_PATH)/Tools"

commander: tool
	cd ./third-party/DinguxCommander && $(MAKE) -j$(JOBS)
	cp -R "paks/Commander.pak" "$(PAYLOAD_PATH)/Tools"
	cp "third-party/DinguxCommander/output/trimui/DinguxCommander" "$(PAYLOAD_PATH)/Tools/Commander.pak"
	cp -R "third-party/DinguxCommander/res" "$(PAYLOAD_PATH)/Tools/Commander.pak"

poweroff: tool
	cp -R "paks/Power Off.pak" "$(PAYLOAD_PATH)/Tools"

stock: tool
	cp -R "paks/Stock UI.pak" "$(PAYLOAD_PATH)/Tools"

reload: tool
	cp -R "paks/Reload MinUI.pak" "$(PAYLOAD_PATH)/Tools"

tips: tool
	cp -R "paks/Tips.pak" "$(PAYLOAD_PATH)/Tools"

clock: tool
	cd ./src/clock && make
	cp -R "paks/Clock.pak" "$(PAYLOAD_PATH)/Tools"
	cp "src/clock/clock" "$(PAYLOAD_PATH)/Tools/Clock.pak"

zero: tool
	cp -R "paks/Zero Stock.pak" "$(PAYLOAD_PATH)/Tools"

#--------------------------------------

zip:
	mkdir -p "$(RELEASE_PATH)"
	cd "$(PAYLOAD_PATH)" && rm -f ../TrimuiUpdate_MinUI.zip
	cd "$(PAYLOAD_PATH)" && zip -r ../TrimuiUpdate_MinUI.zip . -x "*.DS_Store"
	cd "$(BUILD_PATH)" && zip -r ../release/$(RELEASE_NAME).zip readme.txt version.txt Roms TrimuiUpdate_MinUI.zip

#--------------------------------------

.PHONY: picoarch-paks picoarch-tool

picoarch-paks:
	PICOARCH_BUILD="$(PICOARCH_BUILD)" \
	PICOARCH_OUTPUT="$(PICOARCH_OUTPUT)" \
	PICOARCH_PAKS_OUTPUT="$(PICOARCH_PAKS_OUTPUT)" \
	./scripts/picoarch/package-paks.sh

picoarch-tool:
	PICOARCH_BUILD="$(PICOARCH_BUILD)" \
	PICOARCH_OUTPUT="$(PICOARCH_OUTPUT)" \
	PICOARCH_TOOL_OUTPUT="$(PICOARCH_TOOL_OUTPUT)" \
	./scripts/picoarch/package-tool.sh

.PHONY: picoarch-frontend

picoarch-frontend:
	test -n "$(PICOARCH_BUILD)"
	test -d "$(PICOARCH_BUILD)"
	test -x "$(SYSROOT)/usr/bin/sdl-config"
	test -f "$(MINUI_MMENU_BUILD)/mmenu.h"

	PATH="$(SYSROOT)/usr/bin:$$PATH" \
		$(MAKE) -C "$(PICOARCH_BUILD)" \
		platform=trimui \
		MINUI=1 \
		CROSS_COMPILE="$(CROSS_COMPILE)" \
		CC="$(CROSS_COMPILE)gcc --sysroot=$(SYSROOT) -I$(MINUI_MMENU_BUILD)" \
		CXX="$(CROSS_COMPILE)g++ --sysroot=$(SYSROOT) -I$(MINUI_MMENU_BUILD)" \
		picoarch

	test -x "$(PICOARCH_BUILD)/picoarch"

.PHONY: picoarch-prepare

picoarch-prepare:
	test -n "$(PICOARCH_BUILD)"
	test -f "$(PICOARCH_SOURCE)/Makefile"

	@REV="$$(git -C "$(PICOARCH_SOURCE)" rev-parse HEAD)"; \
	STAMP="$(PICOARCH_BUILD)/.prepared"; \
	if [ ! -f "$$STAMP" ] || \
	   [ "$$(cat "$$STAMP" 2>/dev/null)" != "$$REV" ]; then \
		echo "Preparing PicoArch $$REV"; \
		rm -rf "$(PICOARCH_BUILD)"; \
		mkdir -p "$(dir $(PICOARCH_BUILD))"; \
		cp -a "$(PICOARCH_SOURCE)" "$(PICOARCH_BUILD)"; \
		echo "$$REV" > "$$STAMP"; \
	fi

# -----------------------------------------------------------------------------
# Groups
# -----------------------------------------------------------------------------

.PHONY: picoarch-validated
picoarch-validated: picoarch-prepare \
	picoarch-fceumm \
	picoarch-gambatte \
	picoarch-gngeo \
	picoarch-gpsp \
	picoarch-handy \
	picoarch-picodrive \
	picoarch-mame2000 \
	picoarch-pcsx-rearmed \
	picoarch-beetle-pce-fast \
	picoarch-bluemsx \
	picoarch-fmsx \
	picoarch-gme \
	picoarch-mednafen-ngp \
	picoarch-mednafen-wswan \
	picoarch-pokemini \
	picoarch-quicknes \
	picoarch-smsplus-gx \
	picoarch-snes9x2002 \
	picoarch-snes9x2005 \
	picoarch-stella2014 \
	picoarch-mame2003


# -----------------------------------------------------------------------------
# FCEUmm
# -----------------------------------------------------------------------------

.PHONY: picoarch-fceumm
picoarch-fceumm: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		fceumm_libretro.so

.PHONY: picoarch-clean-fceumm
picoarch-clean-fceumm: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-fceumm

# -----------------------------------------------------------------------------
# Gambatte
# -----------------------------------------------------------------------------

.PHONY: picoarch-gambatte
picoarch-gambatte: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		gambatte_libretro.so

.PHONY: picoarch-clean-gambatte
picoarch-clean-gambatte: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-gambatte

# -----------------------------------------------------------------------------
# gpSP
# -----------------------------------------------------------------------------

.PHONY: picoarch-gpsp
picoarch-gpsp: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		gpsp_libretro.so

.PHONY: picoarch-clean-gpsp
picoarch-clean-gpsp: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-gpsp


# -----------------------------------------------------------------------------
# PicoDrive
# -----------------------------------------------------------------------------

.PHONY: picoarch-picodrive
picoarch-picodrive: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		picodrive_libretro.so

.PHONY: picoarch-clean-picodrive
picoarch-clean-picodrive: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-picodrive


# -----------------------------------------------------------------------------
# MAME 2000
# -----------------------------------------------------------------------------

.PHONY: picoarch-mame2000
picoarch-mame2000: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		mame2000_libretro.so

.PHONY: picoarch-clean-mame2000
picoarch-clean-mame2000: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-mame2000

# -----------------------------------------------------------------------------
# MAME 2003
# -----------------------------------------------------------------------------

.PHONY: picoarch-mame2003
picoarch-mame2003: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		mame2003_libretro.so

.PHONY: picoarch-clean-mame2003
picoarch-clean-mame2003: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-mame2003

# -----------------------------------------------------------------------------
# PCSX-ReARMed
# -----------------------------------------------------------------------------

.PHONY: picoarch-pcsx-rearmed
picoarch-pcsx-rearmed: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		pcsx_rearmed_libretro.so

.PHONY: picoarch-clean-pcsx-rearmed
picoarch-clean-pcsx-rearmed: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-pcsx_rearmed


# -----------------------------------------------------------------------------
# Beetle PCE Fast
# -----------------------------------------------------------------------------

.PHONY: picoarch-beetle-pce-fast
picoarch-beetle-pce-fast: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		beetle-pce-fast_libretro.so

.PHONY: picoarch-clean-beetle-pce-fast
picoarch-clean-beetle-pce-fast: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-beetle-pce-fast

# -----------------------------------------------------------------------------
# blueMSX
# -----------------------------------------------------------------------------

.PHONY: picoarch-bluemsx
picoarch-bluemsx: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		bluemsx_libretro.so

.PHONY: picoarch-clean-bluemsx
picoarch-clean-bluemsx: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-bluemsx

# -----------------------------------------------------------------------------
# fMSX
# -----------------------------------------------------------------------------

.PHONY: picoarch-fmsx
picoarch-fmsx: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		fmsx_libretro.so

.PHONY: picoarch-clean-fmsx
picoarch-clean-fmsx: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-fmsx

# -----------------------------------------------------------------------------
# GME
# -----------------------------------------------------------------------------

.PHONY: picoarch-gme
picoarch-gme: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		gme_libretro.so

.PHONY: picoarch-clean-gme
picoarch-clean-gme: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-gme

# -----------------------------------------------------------------------------
# Mednafen NGP
# -----------------------------------------------------------------------------

.PHONY: picoarch-mednafen-ngp
picoarch-mednafen-ngp: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		mednafen_ngp_libretro.so

.PHONY: picoarch-clean-mednafen-ngp
picoarch-clean-mednafen-ngp: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-mednafen_ngp


# -----------------------------------------------------------------------------
# Mednafen WonderSwan
# -----------------------------------------------------------------------------

.PHONY: picoarch-mednafen-wswan
picoarch-mednafen-wswan: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		mednafen_wswan_libretro.so

.PHONY: picoarch-clean-mednafen-wswan
picoarch-clean-mednafen-wswan: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-mednafen_wswan

# -----------------------------------------------------------------------------
# PokeMini
# -----------------------------------------------------------------------------

.PHONY: picoarch-pokemini
picoarch-pokemini: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		pokemini_libretro.so

.PHONY: picoarch-clean-pokemini
picoarch-clean-pokemini: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-pokemini


# -----------------------------------------------------------------------------
# QuickNES
# -----------------------------------------------------------------------------

.PHONY: picoarch-quicknes
picoarch-quicknes: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		quicknes_libretro.so

.PHONY: picoarch-clean-quicknes
picoarch-clean-quicknes: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-quicknes

# -----------------------------------------------------------------------------
# SMS Plus GX
# -----------------------------------------------------------------------------

.PHONY: picoarch-smsplus-gx
picoarch-smsplus-gx: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		smsplus-gx_libretro.so

.PHONY: picoarch-clean-smsplus-gx
picoarch-clean-smsplus-gx: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-smsplus-gx

# -----------------------------------------------------------------------------
# Snes9x 2002
# -----------------------------------------------------------------------------

.PHONY: picoarch-snes9x2002
picoarch-snes9x2002: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		snes9x2002_libretro.so

.PHONY: picoarch-clean-snes9x2002
picoarch-clean-snes9x2002: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-snes9x2002

# -----------------------------------------------------------------------------
# Snes9x 2005
# -----------------------------------------------------------------------------

.PHONY: picoarch-snes9x2005
picoarch-snes9x2005: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		snes9x2005_libretro.so

.PHONY: picoarch-clean-snes9x2005
picoarch-clean-snes9x2005: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-snes9x2005

# -----------------------------------------------------------------------------
# Stella 2014
# -----------------------------------------------------------------------------

.PHONY: picoarch-stella2014
picoarch-stella2014: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		stella2014_libretro.so

.PHONY: picoarch-clean-stella2014
picoarch-clean-stella2014: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-stella2014

# -----------------------------------------------------------------------------
# Handy
# -----------------------------------------------------------------------------

.PHONY: picoarch-handy
picoarch-handy: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		handy_libretro.so

.PHONY: picoarch-clean-handy
picoarch-clean-handy: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-handy

# -----------------------------------------------------------------------------
# GnGeo
# -----------------------------------------------------------------------------

.PHONY: picoarch-gngeo
picoarch-gngeo: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		SYSROOT="$(SYSROOT)" \
		gngeo_libretro.so

.PHONY: picoarch-clean-gngeo
picoarch-clean-gngeo: picoarch-prepare
	$(MAKE) -C $(PICOARCH_BUILD) \
		$(PICOARCH_MAKE_ARGS) \
		clean-gngeo

# -----------------------------------------------------------------------------
# Clean all validated cores
# -----------------------------------------------------------------------------

.PHONY: picoarch-clean-validated
picoarch-clean-validated: \
	picoarch-clean-fceumm \
	picoarch-clean-gambatte \
	picoarch-clean-gngeo \
	picoarch-clean-gpsp \
	picoarch-clean-handy \
	picoarch-clean-picodrive \
	picoarch-clean-mame2000 \
	picoarch-clean-pcsx-rearmed \
	picoarch-clean-beetle-pce-fast \
	picoarch-clean-bluemsx \
	picoarch-clean-fmsx \
	picoarch-clean-gme \
	picoarch-clean-mednafen-ngp \
	picoarch-clean-mednafen-wswan \
	picoarch-clean-pokemini \
	picoarch-clean-quicknes \
	picoarch-clean-smsplus-gx \
	picoarch-clean-snes9x2002 \
	picoarch-clean-snes9x2005 \
	picoarch-clean-stella2014 \
	picoarch-clean-mame2003

.PHONY: picoarch-output

picoarch-output: picoarch-validated picoarch-frontend
	test -n "$(PICOARCH_OUTPUT)"
	test -x "$(PICOARCH_BUILD)/picoarch"

	@test "$$(find "$(PICOARCH_BUILD)" \
		-maxdepth 1 \
		-type f \
		-name '*_libretro.so' \
		| wc -l)" -eq 21 || { \
		echo "ERROR: expected 21 validated PicoArch cores in $(PICOARCH_BUILD)" >&2; \
		exit 1; \
	}

	rm -rf "$(PICOARCH_OUTPUT)"
	mkdir -p "$(PICOARCH_OUTPUT)/cores"

	cp \
		"$(PICOARCH_BUILD)/picoarch" \
		"$(PICOARCH_OUTPUT)/picoarch"

	find "$(PICOARCH_BUILD)" \
		-maxdepth 1 \
		-type f \
		-name '*_libretro.so' \
		-exec cp {} "$(PICOARCH_OUTPUT)/cores/" \;

.PHONY: picoarch-clean-output

picoarch-clean-output:
	test -n "$(PICOARCH_OUTPUT)"
	rm -rf "$(PICOARCH_OUTPUT)"


clean-sys:
	cd ./src/libmmenu && make clean
	cd ./src/MinUI && make clean
	cd ./src/show && make clean
	cd ./src/confirm && make clean
	cd ./src/flipbook && make clean
	cd ./TrimuiUpdate/ && make clean

clean: clean-sys
	cd ./third-party/SDL-1.2 && make distclean
	cd ./third-party/DinguxCommander && make clean
	cd ./third-party/gambatte-dms && make clean
	cd ./third-party/pokemini/platform/trimui && make clean
	cd ./third-party/race && make clean
	cd ./third-party/sms_sdl && make clean
	cd ./third-party/snes9x2002 && make clean
	cd ./third-party/pcsx_rearmed && make clean
	cd ./third-party/picogpsp && make clean
	cd ./third-party/fceux && make clean
	cd ./third-party/picodrive && make clean
	cd ./third-party/temper/SDL && make clean
	cd ./third-party/oswan && make clean
	cd ./third-party/arnold && make clean
	rm -f ./third-party/arnold/arnold
	@if [ -f ./third-party/stella/config.mak ]; then \
		cd ./third-party/stella && $(MAKE) clean; \
	fi
	rm -f ./third-party/stella/config.mak
	rm -f ./third-party/stella/stella
	cd ./third-party/retro8 && $(MAKE) clean
	@if [ -f ./third-party/gngeo/Makefile.trimui ]; then \
		cd ./third-party/gngeo && $(MAKE) -f Makefile.trimui clean; \
	fi
	cd ./src/clock && make clean
	rm -rf ./build
