################################################################################
# glibc modules
################################################################################

glibc_dist_url  := https://ftp.gnu.org/gnu/glibc/glibc-2.42.tar.xz
glibc_dist_sum  := 73a617db8e0f0958c0575f7a1c5a35b72b7e070b6cbdd02a9bb134995ca7ca0909f1e50d7362c53d2572d72f1879bb201a61d5275bac16136895d9a34ef0c068
glibc_dist_name := $(notdir $(glibc_dist_url))
# Watch out ! Keep this as a recursive variable definition !!
# The whole build process depends on it !
glibc_vers       = $(patsubst glibc-%.tar.xz,%,$(glibc_dist_name))
glibc_brief     := GNU C library
glibc_home      := https://www.gnu.org/software/libc/

define glibc_desc
The GNU C Library provides the core libraries for the GNU system and GNU/Linux
systems, as well as many other systems that use Linux as the kernel. These
libraries provide critical APIs including ISO C11, POSIX.1-2008, BSD,
OS-specific APIs and more. These APIs include such foundational facilities as
open, read, write, malloc, printf, getaddrinfo, dlopen, pthread_create, crypt,
login, exit and more.
endef

define fetch_glibc_dist
$(call download_csum,$(glibc_dist_url),$(glibc_dist_name),$(glibc_dist_sum))
endef
$(call gen_fetch_rules,glibc,glibc_dist_name,fetch_glibc_dist)

define xtract_glibc
$(call rmrf,$(srcdir)/glibc)
$(call untar,$(srcdir)/glibc,\
             $(FETCHDIR)/$(glibc_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,glibc,xtract_glibc)

$(call gen_dir_rules,glibc)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define glibc_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/glibc/configure --prefix='$(strip $(2))' $(3) $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional make target and arguments
define glibc_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional make target and arguments
define glibc_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional make target and arguments
define glibc_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

################################################################################
# Bootstrap glibc startup files definitions
#
# Bootstrap C library headers and objects required to build libgcc which is
# itself required to build a complete cross GCC.
# Therefore, the bstrap-target_glibc logic installs the following components
# under the target sysroot directory, i.e. $(bstrap_sysroot):
# - libc development header files
# - "*crt*" C startup object files
# - and finally, an initial "empty" dummy libc library.
################################################################################

$(warning FIXME: glibc configure args)
#GPROF=gprof
#GPROF='$(bstrapdir)/bin/$(TARGET_UPLET)'
#AWK=
#SED=
#BISON=
#PYTHON=
#MAKEINFO=
#MSGFMT=
#--enable-memory-tagging may be enabled on AArch64 systems with the MTE
#extension
#--enable-cet may be enabled for intel

_glibc_xcluded_flags := $(fortify_flags) $(ssp_flags) $(pie_flags) $(lto_flags)

define glibc_target_cppflags
CPPFLAGS='$(call xclude_flags,$(_glibc_xcluded_flags),$(TARGET_CPPFLAGS))'
endef

define glibc_target_cflags
CFLAGS='$(call xclude_flags,$(_glibc_xcluded_flags),$(TARGET_CFLAGS))'
endef

define glibc_target_cxxflags
CXXFLAGS='$(call xclude_flags,$(_glibc_xcluded_flags),$(TARGET_CXXFLAGS))'
endef

define glibc_target_ldflags
LDFLAGS='$(call xclude_flags,$(_glibc_xcluded_flags),$(TARGET_LDFLAGS))'
endef

# Expand to target specific configure flags used to build (target) glibc
# $(1): pathname to stage prefix directory
define glibc_target_flags
$(call config_target_tools,$(strip $(1))) \
$(glibc_target_cppflags) \
$(glibc_target_cflags) \
$(glibc_target_cxxflags) \
$(glibc_target_ldflags)
endef

# --enable-fortify-source=yes:
#      Build with maximum fortify source level supported by the target
#      architecture.
glibc_bstrap_target_args = --build='$(BUILD_UPLET)' \
                           --with-pkgversion='$(pkgvers)' \
                           --with-bugurl='$(pkgurl)' \
                           --with-headers='$(bstrap_sysroot)/include' \
                           --enable-kernel='$(linux-head_vers)' \
                           --enable-shared \
                           --enable-default-pie \
                           --enable-bind-now \
                           --enable-stack-protector=strong \
                           --enable-fortify-source=yes \
                           --disable-multi-arch \
                           --disable-build-nscd \
                           --disable-nscd \
                           --without-selinux \
                           BUILD_CC='$(BUILD_CC)' \
                           BUILD_CPPFLAGS='$(BUILD_CPPFLAGS)' \
                           BUILD_CFLAGS='$(BUILD_CFLAGS)' \
                           BUILD_LDFLAGS='$(BUILD_LDFLAGS)' \
                           $(call glibc_target_flags,$(bstrapdir)) \
                           $(GLIBC_BSTRAP_TARGET_ARGS)

$(call gen_deps,bstrap-target_glibc_startup,bstrap-host_gcc_core)

define config_bstrap-target_glibc_startup
$(call mkdir,$(builddir)/bstrap-target_glibc)
$(call glibc_config_cmds,bstrap-target_glibc,\
                         $(TARGET_PREFIX),\
                         $(glibc_bstrap_target_args))
endef

define build_bstrap-target_glibc_startup
# Build crt C startup object files required to build libgcc
$(call glibc_build_cmds,bstrap-target_glibc,csu/subdir_lib)
# Build libc header files
$(call glibc_install_cmds,bstrap-target_glibc,\
                          install-bootstrap-headers=yes \
                          install_root='$(builddir)/bstrap-target_glibc/.install' \
                          install-headers)
endef

define clean_bstrap-target_glibc_startup
$(call glibc_clean_cmds,bstrap-target_glibc,csu/subdir_clean)
$(RM) -r $(builddir)/bstrap-target_glibc/.install
endef

define install_bstrap-target_glibc_startup
# Install libc header files
$(call glibc_install_cmds,bstrap-target_glibc,\
                          install-bootstrap-headers=yes \
                          install_root='$(bstrap_sysroot)' \
                          install-headers)
$(TOUCH) $(bstrap_sysroot)/include/gnu/stubs.h
# Install crt C startup object files required to build libgcc
$(foreach o,\
          $(wildcard $(builddir)/bstrap-target_glibc/csu/*crt*.o),\
          $(INSTALL) --mode=644 -D $(o) $(bstrap_sysroot)/lib/$(notdir $(o));)
# Build and install an empty dummy libc library file required to build libgcc.
# The gcc invocation disables linking to the (not yet existing) stdlib and
# startfiles to build an empty libc by treating /dev/null as C source input (-x
# c).
$(bstrapdir)/bin/$(TARGET_UPLET)-gcc -nostdlib \
                                     -nostartfiles \
                                     -shared \
                                     -x c /dev/null \
                                     -o $(bstrap_sysroot)/lib/libc.so \
                                     $(verbose)
endef

define uninstall_bstrap-target_glibc_startup
$(RM) $(bstrap_sysroot)/lib/libc.so
$(foreach o,\
          $(wildcard $(builddir)/bstrap-target_glibc/csu/*crt*.o),\
          $(RM) $(bstrap_sysroot)/lib/$(notdir $(o));)
$(call uninstall_from_refdir,$(builddir)/bstrap-target_glibc/.install/include,\
                             $(bstrap_sysroot)/include)
$(RM) $(bstrap_sysroot)/include/gnu/stubs.h
endef

$(call gen_config_rules_with_dep,bstrap-target_glibc_startup,\
                                 glibc,\
                                 config_bstrap-target_glibc_startup)
$(call gen_clobber_rules,bstrap-target_glibc_startup)
$(call gen_build_rules,bstrap-target_glibc_startup,\
                       build_bstrap-target_glibc_startup)
$(call gen_clean_rules,bstrap-target_glibc_startup,\
                       clean_bstrap-target_glibc_startup)
$(call gen_install_rules,bstrap-target_glibc_startup,\
                         install_bstrap-target_glibc_startup)
$(call gen_uninstall_rules,bstrap-target_glibc_startup,\
                           uninstall_bstrap-target_glibc_startup)
$(call gen_dir_rules,bstrap-target_glibc_startup)

################################################################################
# Bootstrap glibc definitions
################################################################################

define build_bstrap-target_glibc
+$(MAKE) --directory $(builddir)/bstrap-target_glibc all $(verbose)
endef

define clean_bstrap-target_glibc
+$(MAKE) --directory $(builddir)/bstrap-target_glibc clean $(verbose)
$(RM) $(stampdir)/bstrap-target_glibc_startup/built
endef

define install_bstrap-target_glibc
+$(MAKE) --directory $(builddir)/bstrap-target_glibc \
         install \
         install_root='$(builddir)/bstrap-target_glibc/.install' \
         $(verbose)
+$(MAKE) --directory $(builddir)/bstrap-target_glibc \
         install \
         install_root='$(bstrap_sysroot)' \
         $(verbose)
endef

define uninstall_bstrap-target_glibc
$(call uninstall_from_refdir,$(builddir)/bstrap-target_glibc/.install,\
                             $(bstrap_sysroot))
$(RM) $(stampdir)/bstrap-target_glibc_startup/installed
endef

define clobber_bstrap-target_glibc
$(RM) -r $(builddir)/bstrap-target_glibc_startup
$(RM) -r $(stampdir)/bstrap-target_glibc_startup
endef

$(call gen_deps,bstrap-target_glibc,bstrap-target_libgcc)

$(call gen_config_rules_with_dep,bstrap-target_glibc,glibc)
$(call gen_clobber_rules,bstrap-target_glibc,clobber_bstrap-target_glibc)
$(call gen_build_rules,bstrap-target_glibc,build_bstrap-target_glibc)
$(call gen_clean_rules,bstrap-target_glibc,clean_bstrap-target_glibc)
$(call gen_install_rules,bstrap-target_glibc,install_bstrap-target_glibc)
$(call gen_uninstall_rules,bstrap-target_glibc,uninstall_bstrap-target_glibc)
$(call gen_dir_rules,bstrap-target_glibc)

################################################################################
# Staging glibc definitions
#
# For more infos about glibc configure arguments, see:
# https://www.gnu.org/software/libc/manual/html_node/Configuring-and-compiling.html
#
# TODO:
# build with libunwind support ? libc_cv_cc_with_libunwind=yes ?
#      Declares that libunwind support is available without running the
#      configure test for it: that test would fail as it requires glibc already
#      installed (otherwise the linker cannot link the test program).
#  have_libaudit needed by nscd only (disabled here)
#  have_libcap: needed by nscd and pt_chown (both disabled)
# --with-nonshared-cflags=cflags
# --with-rtld-early-cflags=cflags
#  libc_cv_cxx_thread_local='no'
#  libc_extra_cflags
#  libc_extra_cppflags
################################################################################

glibc_stage_target_args = --build='$(BUILD_UPLET)' \
                          --with-pkgversion='$(pkgvers)' \
                          --with-bugurl='$(pkgurl)' \
                          --with-headers='$(stage_sysroot)/include' \
                          --enable-kernel='$(linux-head_vers)' \
                          --enable-shared \
                          --enable-default-pie \
                          --enable-bind-now \
                          --enable-stack-protector=all \
                          --enable-fortify-source=yes \
                          --disable-multi-arch \
                          --disable-build-nscd \
                          --disable-nscd \
                          --enable-memory-tagging \
                          $(call glibc_target_flags,$(bstrapdir)) \
                          $(GLIBC_STAGE_TARGET_ARGS)

$(call gen_deps,stage-target_glibc,stage-target_linux)

config_stage-target_glibc = $(call glibc_config_cmds,stage-target_glibc,\
                                                     $(TARGET_PREFIX),\
                                                     $(glibc_stage_target_args))
build_stage-target_glibc  = $(call glibc_build_cmds,stage-target_glibc,all)
clean_stage-target_glibc  = $(call glibc_clean_cmds,stage-target_glibc,clean)

define install_stage-target_glibc
+$(MAKE) --directory $(builddir)/stage-target_glibc \
         install \
         install_root='$(builddir)/stage-target_glibc/.install' \
         $(verbose)
+$(MAKE) --directory $(builddir)/stage-target_glibc \
         install \
         install_root='$(stage_sysroot)' \
         $(verbose)
endef

define uninstall_stage-target_glibc
$(call uninstall_from_refdir,$(builddir)/stage-target_glibc/.install,\
                             $(stage_sysroot))
endef

$(call gen_config_rules_with_dep,stage-target_glibc,glibc,config_stage-target_glibc)
$(call gen_clobber_rules,stage-target_glibc)
$(call gen_build_rules,stage-target_glibc,build_stage-target_glibc)
$(call gen_clean_rules,stage-target_glibc,clean_stage-target_glibc)
$(call gen_install_rules,stage-target_glibc,install_stage-target_glibc)
$(call gen_uninstall_rules,stage-target_glibc,uninstall_stage-target_glibc)
$(call gen_dir_rules,stage-target_glibc)

################################################################################
# Final glibc definitions
#
# For more infos about glibc configure arguments, see:
# https://www.gnu.org/software/libc/manual/html_node/Configuring-and-compiling.html
#
# TODO: see staging config args comments
################################################################################

glibc_final_target_args = --build='$(BUILD_UPLET)' \
                          --with-pkgversion='$(pkgvers)' \
                          --with-bugurl='$(pkgurl)' \
                          --with-headers='$(stage_sysroot)/include' \
                          --enable-kernel='$(linux-head_vers)' \
                          --enable-shared \
                          --enable-default-pie \
                          --enable-bind-now \
                          --enable-stack-protector=all \
                          --enable-fortify-source=yes \
                          --disable-multi-arch \
                          --disable-build-nscd \
                          --disable-nscd \
                          --enable-memory-tagging \
                          $(call glibc_target_flags,$(stagedir)) \
                          libc_cv_cc_with_libunwind=yes \
                          $(GLIBC_FINAL_TARGET_ARGS)

$(call gen_deps,final-target_glibc,\
                stage-host_gcc stage-target_libunwind final-target_linux)

config_final-target_glibc = $(call glibc_config_cmds,final-target_glibc,\
                                                     $(TARGET_PREFIX),\
                                                     $(glibc_final_target_args))
build_final-target_glibc  = $(call glibc_build_cmds,final-target_glibc,all)
clean_final-target_glibc  = $(call glibc_clean_cmds,final-target_glibc,clean)

define install_final-target_glibc
+$(MAKE) --directory $(builddir)/final-target_glibc \
         install \
         install_root='$(builddir)/final-target_glibc/.install' \
         $(verbose)
+$(MAKE) --directory $(builddir)/final-target_glibc \
         install \
         install_root='$(finaldir)/$(PREFIX)$(target_sysroot)' \
         $(verbose)
endef

define uninstall_final-target_glibc
$(call uninstall_from_refdir,$(builddir)/final-target_glibc/.install,\
                             $(finaldir)/$(PREFIX)$(target_sysroot))
endef

$(call gen_config_rules_with_dep,final-target_glibc,glibc,\
                                 config_final-target_glibc)
$(call gen_clobber_rules,final-target_glibc)
$(call gen_build_rules,final-target_glibc,build_final-target_glibc)
$(call gen_clean_rules,final-target_glibc,clean_final-target_glibc)
$(call gen_install_rules,final-target_glibc,install_final-target_glibc)
$(call gen_uninstall_rules,final-target_glibc,uninstall_final-target_glibc)
$(call gen_dir_rules,final-target_glibc)
