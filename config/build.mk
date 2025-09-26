BUILD_UPLET           := $(shell /usr/share/autoconf/build-aux/config.guess)
BUILD_ARCH            := native
BUILD_CPU             := native
BUILD_MACHINE_FLAGS   := -march=$(BUILD_ARCH) -mtune=$(BUILD_CPU)
BUILD_OPTIM_CPPFLAGS  := -DNDEBUG
# Use -ffat-lto-objects to make sure that strip(1) works properly with LTO
# generated artefacts.
BUILD_OPTIM_CFLAGS    := -g -O2 \
                         -flto=auto -ffat-lto-objects -fuse-linker-plugin
BUILD_OPTIM_CXXFLAGS  :=
BUILD_OPTIM_LDFLAGS   := -g -O2 \
                         -flto=auto -Wl,-z,combreloc -Wl,--hash-style=gnu
BUILD_CPPFLAGS        := $(BUILD_MACHINE_FLAGS) \
                         $(BUILD_OPTIM_CPPFLAGS) \
                         $(BUILD_HARDEN_CPPFLAGS)
BUILD_CFLAGS          := $(BUILD_CPPFLAGS) \
                         $(BUILD_OPTIM_CFLAGS) \
                         $(BUILD_HARDEN_CFLAGS)
BUILD_CXXFLAGS        := $(BUILD_CFLAGS) \
                         $(BUILD_OPTIM_CXXFLAGS) \
                         $(BUILD_HARDEN_CXXFLAGS)
BUILD_LDFLAGS         := $(BUILD_MACHINE_FLAGS) \
                         $(BUILD_OPTIM_LDFLAGS) \
                         $(BUILD_HARDEN_LDFLAGS)

BUILD_PKG_CONFIG_PATH :=

BUILD_M4              := m4
BUILD_CPP             := cpp
BUILD_AS              := as
BUILD_CC              := gcc
BUILD_CXX             := g++
BUILD_LD              := ld
BUILD_AR              := gcc-ar
BUILD_NM              := gcc-nm
BUILD_OBJCOPY         := objcopy
BUILD_OBJDUMP         := objdump
BUILD_RANLIB          := gcc-ranlib
BUILD_READELF         := readelf
BUILD_STRIP           := strip
BUILD_BISON           := bison
BUILD_YACC            := bison -y
BUILD_FLEX            := flex
BUILD_LEX             := flex
BUILD_PKG_CONFIG      := pkg-config
BUILD_GPERF           := gperf
BUILD_PYTHON          := python3
