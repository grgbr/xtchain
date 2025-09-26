TARGET_CPU              := cortex-a9
TARGET_UPLET            := armv7_a38x-xtchain-linux-gnueabihf
TARGET_LINUX_ARCH       := arm
TARGET_PREFIX           :=

################################################################################
################################################################################
################################################################################

# See:
# https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html
$(warning FIXME: refine glibc build flags)
TARGET_MACHINE_FLAGS   := -march=armv7-a+mp+sec+neon-fp16 \
                          -mtune=cortex-a9 \
                          -mhard-float \
                          -mfpu=neon-fp16 \
                          -marm \
                          -mno-thumb-interwork

TARGET_OPTIM_CPPFLAGS  := -DNDEBUG
TARGET_OPTIM_CFLAGS    := -O2 -flto=auto -fuse-linker-plugin
TARGET_OPTIM_CXXFLAGS  := $(TARGET_OPTIM_CFLAGS)
TARGET_OPTIM_LDFLAGS   := -O2 \
                          -Wl,-as-needed \
                          -Wl,-z,combreloc \
                          -Wl,--hash-style=gnu

TARGET_HARDEN_CPPFLAGS := -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS
TARGET_HARDEN_CFLAGS   := -Wa,--noexecstack \
                          -fstack-protector-strong --param=ssp-buffer-size=4 \
                          -fstack-clash-protection \
                          -ftrivial-auto-var-init=zero \
                          -fzero-call-used-regs=leafy-gpr-arg \
                          -fasynchronous-unwind-tables
## As of gcc 10.2.1 -fvtable-verify cannot be specified together with lto
## See https://gcc.gnu.org/legacy-ml/gcc-patches/2019-09/msg00222.html
#TARGET_HARDEN_CXXFLAGS += -fvtable-verify=std
# -Wl,--disable-new-dtags:
#    Ensure that RPATH is honored before LD_LIBRARY_PATH at runtime.
TARGET_HARDEN_LDFLAGS  := -Wl,-z,now \
                          -Wl,-z,relro \
                          -Wl,-z,noexecstack \
                          -Wl,-z,separate-code \
                          -Wl,--rosegment \
                          -Wl,-z,memory-seal \
                          -Wl,--disable-new-dtags

TARGET_CPPFLAGS        := $(TARGET_MACHINE_FLAGS) \
                          $(TARGET_OPTIM_CPPFLAGS) \
                          $(TARGET_HARDEN_CPPFLAGS)
TARGET_CFLAGS          := -ggdb3 \
                          $(TARGET_CPPFLAGS) \
                          $(TARGET_OPTIM_CFLAGS) \
                          $(TARGET_HARDEN_CFLAGS)
TARGET_CXXFLAGS        := -ggdb3 \
                          $(TARGET_CFLAGS) \
                          $(TARGET_OPTIM_CXXFLAGS) \
                          $(TARGET_HARDEN_CXXFLAGS)
TARGET_LDFLAGS         := -ggdb3 \
                          $(TARGET_MACHINE_FLAGS) \
                          $(TARGET_OPTIM_LDFLAGS) \
                          $(TARGET_HARDEN_LDFLAGS)

################################################################################
# Binutils
################################################################################

# Note:
# --with-cpu: sets target processor, expects argument that may be given to
#             gas -mcpu option.
#
# Basically set Cortex-a9 / Armv7-a with mpcore, security, NEON v1, VFPv3 with
# half-precision floating-point conversion operations support.
#
# See <binutils>/gas/tc-arm.c to see CPU / architectural features enabled.
# See 'ARM Options' section of gas info page for available options.
#
# Do we need to set --with-arch configure option ??!
#
# As of binutils 2.44, for this platform, the following config flags incur check
# target failures:
#    --enable-separate-code --enable-rosegment
#    --enable-generate-build-notes
BINUTILS_BSTRAP_TARGET_ARGS := --target='$(TARGET_UPLET)' \
                               --with-cpu='$(TARGET_CPU)' \
                               --enable-separate-code --enable-rosegment \
                               --enable-generate-build-notes
BINUTILS_STAGE_TARGET_ARGS := $(BINUTILS_BSTRAP_TARGET_ARGS)
BINUTILS_FINAL_TARGET_ARGS := $(BINUTILS_BSTRAP_TARGET_ARGS)

################################################################################
# GCC
################################################################################

## Name of cross GCC test simalator.
## See https://gcc.gnu.org/simtest-howto.html
#TARGET_GCC_SIM          := arm-sim

GCC_BSTRAP_TARGET_ARGS := --target='$(TARGET_UPLET)' \
                          --with-arch=armv7-a+mp+sec+neon-fp16 \
                          --with-tune=cortex-a9 \
                          --with-fpu=neon-fp16 \
                          --with-float=hard \
                          --with-mode=arm \
                          --disable-interwork \
                          --disable-softfloat \
                          --with-tls=gnu2
GCC_STAGE_TARGET_ARGS := $(GCC_BSTRAP_TARGET_ARGS)
GCC_FINAL_TARGET_ARGS := $(GCC_BSTRAP_TARGET_ARGS)

################################################################################
# Glibc
################################################################################

# --with-cpu=armv7:
#     tell configure to build armv7 submachine based sysdeps
# libc_cv_cc_submachine=:
#     since we want to pass machine specific target build flags (TARGET_CFLAGS
#     and co.), tell configure not to include `-march=armv7' build flag induced
#     by the --with-cpu option given above.
#
# Note: static PIE support not implemented for ARMv7 sysdeps
GLIBC_BSTRAP_TARGET_ARGS := --host='$(TARGET_UPLET)' \
                            --target='$(TARGET_UPLET)' \
                            --with-cpu='armv7' \
                            libc_cv_cc_submachine=
GLIBC_STAGE_TARGET_ARGS := $(GLIBC_BSTRAP_TARGET_ARGS)
GLIBC_FINAL_TARGET_ARGS := $(GLIBC_BSTRAP_TARGET_ARGS)

GDB_FINAL_TARGET_ARGS := --target='$(TARGET_UPLET)' \
                         --without-libipt \
                         CPPFLAGS_FOR_TARGET='$(TARGET_CPPFLAGS)' \
                         CFLAGS_FOR_TARGET='$(TARGET_CFLAGS)' \
                         CXXFLAGS_FOR_TARGET='$(TARGET_CXXFLAGS)' \
                         LDFLAGS_FOR_TARGET='$(TARGET_LDFLAGS)'

GDBSERVER_FINAL_TARGET_ARGS := --without-intel-pt


GMP_FINAL_TARGET_ARGS :=
MPFR_FINAL_TARGET_ARGS :=
MPC_FINAL_TARGET_ARGS :=
ISL_FINAL_TARGET_ARGS :=
