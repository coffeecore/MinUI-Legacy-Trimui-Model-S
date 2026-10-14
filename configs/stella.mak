# Stella 3.9.3 - Trimui Model S

CXX := $(CROSS_COMPILE)g++
CXXFLAGS := -O2
LD := $(CXX)

LIBS += -L$(SYSROOT)/usr/lib -lSDL -lpng -lz -lm -lpthread -ldl

RANLIB := $(CROSS_COMPILE)ranlib
INSTALL := install
AR := $(CROSS_COMPILE)ar cru
MKDIR := mkdir -p
ECHO := printf
CAT := cat
RM := rm -f
RM_REC := rm -f -r
ZIP := zip -q
CP := cp
WIN32PATH :=
STRIP := $(CROSS_COMPILE)strip
WINDRES := windres

MODULES += src/unix src/debugger src/debugger/gui src/yacc src/cheat
EXEEXT :=

PREFIX := /usr
BINDIR := /usr/bin
DOCDIR := /usr/share/doc/stella
DATADIR := /usr/share
PROFILE :=

HAVE_GCC = 1
HAVE_GCC3 = 1
CXX_UPDATE_DEP_FLAG = -MMD -MF "$(*D)/$(DEPDIR)/$(*F).d" -MQ "$@" -MP

INCLUDES += \
	-Isrc/emucore \
	-Isrc/common \
	-Isrc/common/tv_filters \
	-Isrc/gui \
	-Isrc/unix \
	-Isrc/debugger \
	-Isrc/debugger/gui \
	-Isrc/yacc \
	-Isrc/cheat \
	-I$(SYSROOT)/usr/include/SDL \
	-D_GNU_SOURCE=1 \
	-D_REENTRANT

DEFINES += \
	-DUNIX \
	-DBSPF_UNIX \
	-DHAVE_GETTIMEOFDAY \
	-DHAVE_INTTYPES \
	-DWINDOWED_SUPPORT \
	-DSOUND_SUPPORT \
	-DDEBUGGER_SUPPORT \
	-DSNAPSHOT_SUPPORT \
	-DJOYSTICK_SUPPORT \
	-DCHEATCODE_SUPPORT \
	-DTHUMB_SUPPORT

LDFLAGS += -L$(SYSROOT)/usr/lib
