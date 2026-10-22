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

RELEASE_DATE := $(shell TZ=Europe/Paris date +%Y%m%d)
VARIANT_RELEASE_BASE := MinUI-$(RELEASE_DATE)-0

MINUI_BASE_PAK_COUNT := 23
PICOARCH_PAK_COUNT := 27
PICOARCH_TOTAL_PAK_COUNT := 50

PICOARCH_SOURCE := $(CURDIR)/third-party/picoarch
PICOARCH_MAKE_ARGS := \
	platform=trimui \
	CROSS_COMPILE=$(CROSS_COMPILE) \
	CXX=$(CROSS_COMPILE)g++ \
	CC_FOR_BUILD=gcc \
	CXX_FOR_BUILD=g++

CROSS_COMPILE ?= /opt/trimui-toolchain/bin/arm-buildroot-linux-gnueabi-
SYSROOT ?= /opt/trimui-toolchain/arm-buildroot-linux-gnueabi/sysroot

OD_COMMANDER_BUILD := $(BUILD_PATH)/od-commander

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
	mkdir -p "$(ROMS_PATH)"
	cp "configs/roms-map.txt" "$(ROMS_PATH)/map.txt"

gb: emu
	mkdir -p "$(ROMS_PATH)/GB"
	cd ./third-party/gambatte-dms && $(MAKE) -j$(JOBS)
	cp -R "paks/GB.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/gambatte-dms/gambatte-dms" "$(PAYLOAD_PATH)/Emus/GB.pak"
	
	mkdir -p "$(ROMS_PATH)/GBC"
	cp -R "paks/GBC.pak" "$(PAYLOAD_PATH)/Emus"

pm: emu
	mkdir -p "$(ROMS_PATH)/POKEMINI"
	cd ./third-party/pokemini/platform/trimui && $(MAKE) -j$(JOBS)
	cp -R "paks/POKEMINI.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/pokemini/platform/trimui/pokemini" "$(PAYLOAD_PATH)/Emus/POKEMINI.pak"

ngp: emu
	mkdir -p "$(ROMS_PATH)/NGP"
	cd ./third-party/race && $(MAKE) -j$(JOBS)
	cp -R "paks/NGP.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/race/race-od" "$(PAYLOAD_PATH)/Emus/NGP.pak"
	
	mkdir -p "$(ROMS_PATH)/NGPC"
	cp -R "paks/NGPC.pak" "$(PAYLOAD_PATH)/Emus"

gg: emu
	mkdir -p "$(ROMS_PATH)/GG"
	cd ./third-party/sms_sdl && $(MAKE) -j$(JOBS)
	cp -R "paks/GG.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/sms_sdl/sms_sdl" "$(PAYLOAD_PATH)/Emus/GG.pak"
	
	mkdir -p "$(ROMS_PATH)/MS"
	cp -R "paks/MS.pak" "$(PAYLOAD_PATH)/Emus"

snes: emu
	mkdir -p "$(ROMS_PATH)/SFC"
	cd ./third-party/snes9x2002 && $(MAKE) -j$(JOBS)
	cp -R "paks/SFC.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/snes9x2002/snes9x2002" "$(PAYLOAD_PATH)/Emus/SFC.pak"

ps: emu
	mkdir -p "$(ROMS_PATH)/PS"
	if [ ! -f ./third-party/pcsx_rearmed/config.mak ]; then cd ./third-party/pcsx_rearmed && CROSS_COMPILE=/opt/trimui-toolchain/bin/arm-buildroot-linux-gnueabi- ./configure --platform=trimui; fi
	cd ./third-party/pcsx_rearmed && $(MAKE) -j$(JOBS)
	cp -R "paks/PS.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/pcsx_rearmed/pcsx" "$(PAYLOAD_PATH)/Emus/PS.pak"

gba: emu
	mkdir -p "$(ROMS_PATH)/GBA"
	cd ./third-party/picogpsp && $(MAKE) -j$(JOBS)
	cp -R "paks/GBA.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/picogpsp/picogpsp" "$(PAYLOAD_PATH)/Emus/GBA.pak"
	
nes: emu
	mkdir -p "$(ROMS_PATH)/FC"
	cd ./third-party/fceux && $(MAKE) -j$(JOBS)
	cp -R "paks/FC.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/fceux/fceux/fceux.dge" "$(PAYLOAD_PATH)/Emus/FC.pak"
	cp "third-party/fceux/fceux/backdrop.png" "$(PAYLOAD_PATH)/Emus/FC.pak"
	cp "third-party/fceux/fceux/sp.bmp" "$(PAYLOAD_PATH)/Emus/FC.pak"
	cp -R "third-party/fceux/fceux/palettes" "$(PAYLOAD_PATH)/Emus/FC.pak"

gen: emu
	mkdir -p "$(ROMS_PATH)/MD"
	mkdir -p "$(ROMS_PATH)/SCD"
	mkdir -p "$(ROMS_PATH)/32X"
	if [ ! -f ./third-party/picodrive/config.mak ]; then cd ./third-party/picodrive && CROSS_COMPILE=/opt/trimui-toolchain/bin/arm-buildroot-linux-gnueabi- ./configure --platform=trimui; fi
	cd ./third-party/picodrive && $(MAKE) -j$(JOBS)
	cp -R "paks/MD.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/SCD.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/32X.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/picodrive/PicoDrive" "$(PAYLOAD_PATH)/Emus/MD.pak"
	mkdir -p "$(PAYLOAD_PATH)/Emus/MD.pak/skin"
	cp -R \
		"third-party/picodrive/platform/opendingux/data/skin/." \
		"$(PAYLOAD_PATH)/Emus/MD.pak/skin/"

pce: emu
	mkdir -p "$(ROMS_PATH)/PCE"
	mkdir -p "$(ROMS_PATH)/PCECD"
	cd ./third-party/temper/SDL && $(MAKE) -j$(JOBS)
	cp -R "paks/PCE.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/PCECD.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/temper/SDL/temper" "$(PAYLOAD_PATH)/Emus/PCE.pak"

swan: emu
	mkdir -p "$(ROMS_PATH)/WS"
	mkdir -p "$(ROMS_PATH)/WSC"
	cd ./third-party/oswan && $(MAKE) -j$(JOBS)
	cp -R "paks/WS.pak" "$(PAYLOAD_PATH)/Emus"
	cp -R "paks/WSC.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/oswan/oswan" "$(PAYLOAD_PATH)/Emus/WS.pak"

lynx: emu
	mkdir -p "$(ROMS_PATH)/LYNX"
	cd ./third-party/handy-rs97 && $(MAKE) -j$(JOBS)
	cp -R "paks/LYNX.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/handy-rs97/handy" "$(PAYLOAD_PATH)/Emus/LYNX.pak"

gx4000: lib emu
	mkdir -p "$(ROMS_PATH)/GX4000"
	cd ./third-party/arnold && $(MAKE) -j$(JOBS)
	cp -R "paks/GX4000.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/arnold/arnold" "$(PAYLOAD_PATH)/Emus/GX4000.pak/arnold"

stella: emu
	mkdir -p "$(ROMS_PATH)/ATARI2600"
	test -f "$(SYSROOT)/usr/lib/libSDL.a"
	test -f "$(SYSROOT)/usr/lib/libpng.a"
	cp "configs/stella.mak" "third-party/stella/config.mak"
	cd ./third-party/stella && $(MAKE) -j$(JOBS) \
		CROSS_COMPILE="$(CROSS_COMPILE)" \
		SYSROOT="$(SYSROOT)"
	cp -R "paks/ATARI2600.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/stella/stella" "$(PAYLOAD_PATH)/Emus/ATARI2600.pak/stella"

retro8: emu
	mkdir -p "$(ROMS_PATH)/PICO8"
	cd ./third-party/retro8 && $(MAKE) -j$(JOBS)
	cp -R "paks/PICO8.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/retro8/retro8" "$(PAYLOAD_PATH)/Emus/PICO8.pak/retro8"

gngeo: lib emu
	mkdir -p "$(ROMS_PATH)/NEOGEO"
	mkdir -p "./build/Bios/gngeo"
	test -f "$(SYSROOT)/usr/lib/libts-1.0.so.0"
	test -f "$(SYSROOT)/usr/lib/libz.so.1"
	cd ./third-party/gngeo && $(MAKE) -f Makefile.trimui \
		CROSS_COMPILE="$(CROSS_COMPILE)" \
		SYSROOT="$(SYSROOT)" \
		MMENU_DIR="$(CURDIR)/src/libmmenu"
	cp -R "paks/NEOGEO.pak" "$(PAYLOAD_PATH)/Emus"
	cp "third-party/gngeo/gngeo" "$(PAYLOAD_PATH)/Emus/NEOGEO.pak/gngeo"
	mkdir -p "$(PAYLOAD_PATH)/Emus/NEOGEO.pak/lib"
	cp -L $(SYSROOT)/usr/lib/libts-1.0.so* \
		"$(PAYLOAD_PATH)/Emus/NEOGEO.pak/lib/"
	cp -L "$(SYSROOT)/usr/lib/libz.so.1" \
		"$(PAYLOAD_PATH)/Emus/NEOGEO.pak/lib/libz.so.1"
	@if [ -d "$(SYSROOT)/usr/lib/ts" ]; then \
		cp -aL "$(SYSROOT)/usr/lib/ts" \
			"$(PAYLOAD_PATH)/Emus/NEOGEO.pak/lib/"; \
	fi

#--------------------------------------
tools: bridge commander od-commander reload stock tips clock # zero
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

od-commander: tool
	rm -rf "$(OD_COMMANDER_BUILD)"

	/usr/bin/cmake \
		-S "./third-party/od-commander" \
		-B "$(OD_COMMANDER_BUILD)" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_TOOLCHAIN_FILE=/opt/trimui-toolchain/usr/share/buildroot/toolchainfile.cmake \
		-DTARGET_PLATFORM=host \
		-DUSE_SDL2=OFF \
		-DWITH_SYSTEM_SDL_TTF=ON \
		-DWITH_SYSTEM_SDL_GFX=OFF \
		-DASAN=OFF \
		-DUBSAN=OFF

	/usr/bin/cmake --build "$(OD_COMMANDER_BUILD)" -j$(JOBS)

	cp -R "paks/OD Commander.pak" "$(PAYLOAD_PATH)/Tools"
	cp "$(OD_COMMANDER_BUILD)/commander" "$(PAYLOAD_PATH)/Tools/OD Commander.pak/commander"
	cp -R "third-party/od-commander/res" "$(PAYLOAD_PATH)/Tools/OD Commander.pak"

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

.PHONY: validate-minui-payload

validate-minui-payload:
	test -d "$(PAYLOAD_PATH)/System"
	test -d "$(PAYLOAD_PATH)/Emus"
	test -d "$(PAYLOAD_PATH)/Tools"
	test -d "$(ROMS_PATH)"
	test -f "$(BUILD_PATH)/readme.txt"
	test -f "$(BUILD_PATH)/version.txt"

	@COUNT="$$(find "$(PAYLOAD_PATH)/Emus" \
		-mindepth 1 \
		-maxdepth 1 \
		-type d \
		-name '*.pak' \
		| wc -l)"; \
	if [ "$$COUNT" -ne "$(MINUI_BASE_PAK_COUNT)" ]; then \
		echo "ERROR: expected $(MINUI_BASE_PAK_COUNT) base MinUI PAKs, found $$COUNT" >&2; \
		exit 1; \
	fi

	@for pak in \
		"SCD.pak" \
		"32X.pak" \
		"PCECD.pak" \
		"WSC.pak"; do \
		test -d "$(PAYLOAD_PATH)/Emus/$$pak" || { \
			echo "ERROR: missing base MinUI PAK: $$pak" >&2; \
			exit 1; \
		}; \
	done

	# GnGeo is part of base MinUI, so every release needs this directory.
	mkdir -p "$(BUILD_PATH)/Bios/gngeo"

.PHONY: _zip-release

_zip-release:
	test -n "$(RELEASE_FILE)"

	rm -f \
		"$(BUILD_PATH)/TrimuiUpdate_MinUI.zip" \
		"$(BUILD_PATH)/trimui_Minui.zip"

	cd "$(PAYLOAD_PATH)" && \
		zip -qr "../TrimuiUpdate_MinUI.zip" . \
			-x "*.DS_Store"

	mv \
		"$(BUILD_PATH)/TrimuiUpdate_MinUI.zip" \
		"$(BUILD_PATH)/trimui_Minui.zip"

	mkdir -p "$(RELEASE_PATH)"
	rm -f "$(RELEASE_PATH)/$(RELEASE_FILE)"

	cd "$(BUILD_PATH)" && \
		zip -qr "../release/$(RELEASE_FILE)" \
			readme.txt \
			version.txt \
			Roms \
			Bios \
			$(RELEASE_EXTRA_DIRS) \
			trimui_Minui.zip

	unzip -t "$(RELEASE_PATH)/$(RELEASE_FILE)" >/dev/null

.PHONY: release-minui release-picoarch release-all

release-minui:
	$(MAKE) picoarch-clean-payload
	$(MAKE) validate-minui-payload
	$(MAKE) _zip-release \
		RELEASE_FILE="$(VARIANT_RELEASE_BASE)-minui.zip"

release-picoarch:
	# Always start from a clean base MinUI payload.
	$(MAKE) picoarch-clean-payload
	$(MAKE) validate-minui-payload

	$(MAKE) picoarch-payload
	$(MAKE) validate-picoarch-payload

	$(MAKE) _zip-release \
		RELEASE_FILE="$(VARIANT_RELEASE_BASE)-picoarch.zip" \
		RELEASE_EXTRA_DIRS="Saves"

release-all:
	$(MAKE) release-minui
	$(MAKE) release-picoarch

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
# PicoArch cores
# -----------------------------------------------------------------------------

.PHONY: picoarch-validated
picoarch-validated: picoarch-prepare
	$(MAKE) -C "$(PICOARCH_BUILD)" \
		$(PICOARCH_MAKE_ARGS) \
		SYSROOT="$(SYSROOT)" \
		cores

.PHONY: picoarch-clean-validated
picoarch-clean-validated: picoarch-prepare
	$(MAKE) -C "$(PICOARCH_BUILD)" \
		$(PICOARCH_MAKE_ARGS) \
		SYSROOT="$(SYSROOT)" \
		clean-cores


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

.PHONY: picoarch-payload picoarch-clean-payload

picoarch-payload:
	$(MAKE) picoarch-output
	$(MAKE) picoarch-paks
	$(MAKE) picoarch-tool

	test -n "$(PICOARCH_PAKS_OUTPUT)"
	test -n "$(PICOARCH_TOOL_OUTPUT)"

	@test "$$(find "$(PICOARCH_PAKS_OUTPUT)" \
		-mindepth 1 \
		-maxdepth 1 \
		-type d \
		-name '*-picoarch.pak' \
		| wc -l)" -eq "$(PICOARCH_PAK_COUNT)" || { \
		echo "ERROR: expected $(PICOARCH_PAK_COUNT) PicoArch PAKs" >&2; \
		exit 1; \
	}

	mkdir -p "$(PAYLOAD_PATH)/Emus"
	mkdir -p "$(PAYLOAD_PATH)/Tools"

	cp -a \
		"$(PICOARCH_PAKS_OUTPUT)"/*-picoarch.pak \
		"$(PAYLOAD_PATH)/Emus/"

	rm -rf "$(PAYLOAD_PATH)/Tools/PicoArch.pak"

	cp -a \
		"$(PICOARCH_TOOL_OUTPUT)/Tools/PicoArch.pak" \
		"$(PAYLOAD_PATH)/Tools/"

	mkdir -p "$(BUILD_PATH)/Bios/picoarch"
	mkdir -p "$(BUILD_PATH)/Saves/picoarch"

	@for pak in "$(PICOARCH_PAKS_OUTPUT)"/*-picoarch.pak; do \
		name="$$(basename "$$pak")"; \
		system="$${name%-picoarch.pak}"; \
		mkdir -p "$(ROMS_PATH)/$$system"; \
	done

.PHONY: validate-picoarch-payload

validate-picoarch-payload:
	@test "$$(find "$(PAYLOAD_PATH)/Emus" \
		-mindepth 1 \
		-maxdepth 1 \
		-type d \
		-name '*.pak' \
		| wc -l)" -eq "$(PICOARCH_TOTAL_PAK_COUNT)" || { \
		echo "ERROR: expected $(PICOARCH_TOTAL_PAK_COUNT) total PAKs" >&2; \
		exit 1; \
	}

	@test "$$(find "$(PAYLOAD_PATH)/Emus" \
		-mindepth 1 \
		-maxdepth 1 \
		-type d \
		-name '*-picoarch.pak' \
		| wc -l)" -eq "$(PICOARCH_PAK_COUNT)" || { \
		echo "ERROR: expected $(PICOARCH_PAK_COUNT) PicoArch PAKs" >&2; \
		exit 1; \
	}

	test -d "$(PAYLOAD_PATH)/Tools/PicoArch.pak"
	test -d "$(BUILD_PATH)/Bios/picoarch"
	test -d "$(BUILD_PATH)/Saves/picoarch"

	grep -Fq \
		'ROM_DIR=$${ROM_DIR%-picoarch}' \
		"$(PAYLOAD_PATH)/System/System.pak/update.sh"

picoarch-clean-payload:
	@for pak in "$(PAYLOAD_PATH)/Emus/"*-picoarch.pak; do \
		[ -d "$$pak" ] || continue; \
		name="$$(basename "$$pak")"; \
		system="$${name%-picoarch.pak}"; \
		if [ ! -d "$(PAYLOAD_PATH)/Emus/$$system.pak" ]; then \
			rm -rf "$(ROMS_PATH)/$$system"; \
		fi; \
	done

	rm -rf "$(PAYLOAD_PATH)/Emus/"*-picoarch.pak
	rm -rf "$(PAYLOAD_PATH)/Tools/PicoArch.pak"
	rm -rf "$(BUILD_PATH)/Bios/picoarch"
	rm -rf "$(BUILD_PATH)/Saves/picoarch"


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
