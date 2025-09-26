TARGET_CPU                  := x86-64
TARGET_UPLET                := x86_64-pc-linux-gnu
# Enable the following config flags ??
#    --enable-generate-build-notes
#    --enable-x86-used-note
BINUTILS_BSTRAP_TARGET_ARGS := $(bstrap_config_flags) \
                               --target='$(TARGET_UPLET)' \
                               --enable-64-bit-bfd \
                               --with-cpu='$(TARGET_CPU)' \
                               --enable-x86-relax-relocations \
                               --enable-x86-tls-check \
                               --disable-softfloat \
                               --enable-64-bit-bfd \
                               --enable-separate-code --enable-rosegment \
                               --enable-mark-plt \
                               --enable-cet

# TODO: to add to GCC_TARGET_ARGS:
#--enable-decimal-float=yes

# TODO: to add to GLIBC_TARGET_ARGS:
# --enable-sframe
#
# TODO: to add to GDB_TARGET_ARGS:
#  --enable-decimal-float=yes
#  --with-intel-pt   include Intel Processor Trace support (auto/yes/no)
#  --with-libipt-... search for libipt in DIR/include and DIR/lib
#  --with-amd-dbgapi support for the amd-dbgapi target (yes / no / auto)

# TODO: to add to GDBSERVER_TARGET_ARGS:
# --enable-inprocess-agent

# TODO: to add to GMP_FINAL_TARGET_ARGS:
# $(if $(mach_is_64bits),ABI=64)

# TODO: to add to MPFR_FINAL_TARGET_ARGS:
#--enable-decimal-float=yes

# TODO: to add to GCC args ?:
# Do not include --enable-cet since failing to build with gcc-7 at bootstrapping
# time. Do not enable it during stage / final steps since we do not build a
# hardened toolchain anyway.
# --enable-cet: fails to build with old gcc
#gcc_common_x86_64_args := --with-arch=native \
#                          --with-cpu=native \
#                          --with-tune=native \
#                          --with-fpmath=avx \
#                          --disable-softfloat
