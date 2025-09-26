# See https://wiki.osdev.org/Hosted_GCC_Cross-Compiler

$(warning check gcc plugins install path and implement uninstall)

################################################################################
# gcc modules
#
# Requires the following bookworm packages to build:
# chrpath
#
# TODO:
# Understand if --with-system-libunwind is really required and how it is
# integrated with glibc libunwind support.
#
# For libstdc++ settings, see:
#     https://gcc.gnu.org/onlinedocs/libstdc++/manual/configure.html
################################################################################

gcc_dist_url  := https://ftp.gnu.org/gnu/gcc/gcc-14.3.0/gcc-14.3.0.tar.xz
gcc_dist_sum  := cb4e3259640721bbd275c723fe4df53d12f9b1673afb3db274c22c6aa457865dccf2d6ea20b4fd4c591f6152e6d4b87516c402015900f06ce9d43af66d3b7a93
gcc_dist_name := $(notdir $(gcc_dist_url))
gcc_vers      := $(patsubst gcc-%.tar.xz,%,$(gcc_dist_name))
gcc_vers_maj  := $(word 1,$(subst .,$(space),$(gcc_vers)))
gcc_brief     := GNU compiler collection
gcc_home      := https://gcc.gnu.org/

define gcc_desc
The GNU Compiler Collection includes front ends for C, C++, Objective-C,
Fortran, Ada, Go, and D, as well as libraries for these languages
(libstdc++,...). GCC was originally written as the compiler for the GNU
operating system. The GNU system was developed to be 100% free software, free in
the sense that it respects the user\'s freedom.

We strive to provide regular, high quality releases, which we want to work well
on a variety of native and cross targets (including GNU/Linux), and encourage
everyone to contribute changes or help testing GCC. Our sources are readily and
freely available via Git and weekly snapshots.
endef

define fetch_gcc_dist
$(call download_csum,$(gcc_dist_url),$(gcc_dist_name),$(gcc_dist_sum))
endef
$(call gen_fetch_rules,gcc,gcc_dist_name,fetch_gcc_dist)

# Patches:
# * gcc-14.3.0-000-fix_build_with_glibc_2_42.patch:
#   patch from gcc git tree: https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d32ece49d32b00448d967e7dbc6900fb25cbc775
#   see Gentoo bug retport: https://bugs.gentoo.org/953044
define xtract_gcc
$(call rmrf,$(srcdir)/gcc)
$(call untar,$(srcdir)/gcc,\
             $(FETCHDIR)/$(gcc_dist_name),\
             --strip-components=1)
$(call patch,$(srcdir)/gcc,\
             $(PATCHDIR)/gcc-14.3.0-000-fix_build_with_glibc_2_42.patch)
endef
$(call gen_xtract_rules,gcc,xtract_gcc)

$(call gen_dir_rules,gcc)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define gcc_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/gcc/configure --prefix='$(strip $(2))' \
                        $(3) \
                        $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and arguments
define gcc_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and arguments
define gcc_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and arguments
define gcc_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# Fix unexpected RPATH / RUNPATH of target libraries passed in argument
# $(1): sysroot directory
# $(2): library base file patterns
define gcc_cleanup_sysroot_libs_rpath
for l in $$(realpath $(addprefix $(strip $(1))/lib/,$(2)) | sort -u); \
do \
	type=$$(file --brief --mime $$l); \
	if [ "$$type" = "application/x-sharedlib; charset=binary" ]; then \
		$(CHRPATH) --delete $$l; \
	fi; \
done
endef

# Install lto plugin for binutils nm / ar / ranlib usage
# $(1): build / install prefix
# $(2): optional install destination directory
define gcc_install_plugins_cmds
$(call mkdir,$(strip $(2))$(strip $(1))/lib/bfd-plugins); \
$(call slink,\
       ../../libexec/gcc/$(TARGET_UPLET)/$(gcc_vers_maj)/liblto_plugin.so,\
       $(strip $(2))$(strip $(1))/lib/bfd-plugins/liblto_plugin.so); \
$(call mkdir,$(strip $(2))$(strip $(1))/$(TARGET_UPLET)/lib/bfd-plugins); \
$(call slink,\
       ../../../libexec/gcc/$(TARGET_UPLET)/$(gcc_vers_maj)/liblto_plugin.so,\
       $(strip $(2))$(strip $(1))/$(TARGET_UPLET)/lib/bfd-plugins/liblto_plugin.so)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): make target and arguments
define gcc_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          $(3) \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(2)))
endef

# $(1): targets base name / module name
#
# See <gcc_source>/INSTALL/test.html for more informations
define gcc_check_cmds
#+env PATH="$(stagedir)/bin:$(PATH)" \
# $(MAKE) -j1 --directory $(builddir)/$(strip $(1)) check $(2)
endef

_gcc_xcluded_flags := $(fortify_flags) $(ssp_flags) $(pie_flags) $(lto_flags)

define gcc_target_cppflags
CPPFLAGS_FOR_TARGET='$(call xclude_flags,$(_gcc_xcluded_flags),\
                                         $(TARGET_CPPFLAGS))'
endef

define gcc_target_cflags
CFLAGS_FOR_TARGET='$(call xclude_flags,$(_gcc_xcluded_flags),\
                                       $(TARGET_CFLAGS))'
endef

define gcc_target_cxxflags
CXXFLAGS_FOR_TARGET='$(call xclude_flags,$(_gcc_xcluded_flags),\
                                         $(TARGET_CXXFLAGS))'
endef

define gcc_target_ldflags
LDFLAGS_FOR_TARGET='$(call xclude_flags,$(_gcc_xcluded_flags),\
                                        $(TARGET_LDFLAGS))'
endef

# Expand to target specific configure flags used to build (target) gcc
# $(1): pathname to stage prefix directory
define gcc_target_flags
$(call gcc_tools_for_target,$(strip $(1))) \
$(gcc_target_cppflags) \
$(gcc_target_cflags) \
$(gcc_target_cxxflags) \
$(gcc_target_ldflags)
endef

# Watch out ! Keep this as a recursively defined variable since glibc_vers is
# defined itself as a recursive variable !
#
# --enable-default-ssp gcc_cv_libc_provides_ssp=yes:
# * build with stack protector enabled (including target libraries) by telling
#   gcc build logic that glibc comes with its own `__stack_chk_fail()'
#   implementation
# * DO NOT give gcc configure script the `--enable-libssp' option as it would
#   defeat the above setting and would lessen the SSP support coverage !!!
gcc_common_args  = --build='$(BUILD_UPLET)' \
                   --host='$(BUILD_UPLET)' \
                   --with-pkgversion='$(pkgvers)' \
                   --with-bugurl='$(pkgurl)' \
                   --with-glibc-version='$(glibc_vers)' \
                   --with-gcc-major-version-only \
                   --with-native-system-header-dir='/include' \
                   --enable-silent-rules \
                   --enable-static \
                   --enable-shared \
                   --with-gnu-as \
                   --with-gnu-ld \
                   --disable-gold \
                   --enable-ld \
                   --enable-year2038 \
                   --disable-multilib \
                   --disable-multiarch \
                   --enable-checking \
                   --with-gmp='$(bstrapdir)' \
                   --with-mpfr='$(bstrapdir)' \
                   --with-mpc='$(bstrapdir)' \
                   --with-isl='$(bstrapdir)' \
                   --with-system-zlib \
                   --with-zstd \
                   --enable-plugin \
                   --enable-default-hash-style=gnu \
                   --with-linker-hash-style=gnu \
                   --enable-gnu-unique-object \
                   --enable-threads=posix \
                   --enable-tls \
                   --enable-default-ssp \
                   gcc_cv_libc_provides_ssp=yes \
                   --enable-default-pie \
                   --enable-host-pie \
                   --enable-secureplt \
                   --enable-lto \
                   --disable-new-dtags \
                   --enable-__cxa_atexit \
                   --enable-libatomic \
                   --enable-libstdcxx \
                   --enable-clocale=gnu \
                   --enable-libvtv \
                   --disable-libada \
                   --disable-libgm2 \
                   $(config_build_tools) \
                   CPPFLAGS='$(BUILD_CPPFLAGS)' \
                   CFLAGS='$(BUILD_CFLAGS)' \
                   CXXFLAGS='$(BUILD_CXXFLAGS)' \
                   LDFLAGS='$(BUILD_LDFLAGS)'

################################################################################
# Bootstrapping definitions
################################################################################

gcc_bstrap_host_args  = \
	$(gcc_common_args) \
	--with-sysroot='$(bstrap_sysroot)' \
	--with-gxx-include-dir='$(bstrap_sysroot)/include/c++/$(gcc_vers_maj)' \
	--with-toolexeclibdir='$(bstrap_sysroot)/lib' \
	--disable-bootstrap \
	--disable-nls \
	--disable-gprofng \
	--without-headers \
	--disable-libsanitizer \
	--disable-libgomp \
	--disable-libquadmath \
	--disable-libquadmath-support \
	--enable-languages=c,c++,lto \
	MAKEINFO='/bin/true' \
	$(call gcc_target_flags,$(bstrapdir)) \
	$(GCC_BSTRAP_TARGET_ARGS)

$(call gen_deps,bstrap-host_gcc_core,bstrap-host_binutils bstrap-target_linux)

define config_bstrap-host_gcc_core
$(call mkdir,$(builddir)/bstrap-host_gcc)
$(call gcc_config_cmds,bstrap-host_gcc,$(bstrapdir),$(gcc_bstrap_host_args))
endef

build_bstrap-host_gcc_core     = $(call gcc_build_cmds,bstrap-host_gcc,all-gcc)
clean_bstrap-host_gcc_core     = $(call gcc_clean_cmds,bstrap-host_gcc,clean)

define install_bstrap-host_gcc_core
$(call gcc_install_cmds,bstrap-host_gcc,install-gcc)
$(call gcc_install_plugins_cmds,$(bstrapdir))
endef

uninstall_bstrap-host_gcc_core = $(call gcc_uninstall_cmds,bstrap-host_gcc,\
                                                           $(bstrapdir),\
                                                           uninstall)
check_bstrap-host_gcc_core     = $(call gcc_check_cmds,bstrap-host_gcc)

$(call gen_config_rules_with_dep,bstrap-host_gcc_core,gcc,\
                                 config_bstrap-host_gcc_core)
$(call gen_build_rules,bstrap-host_gcc_core,build_bstrap-host_gcc_core)
$(call gen_clean_rules,bstrap-host_gcc_core,clean_bstrap-host_gcc_core)
$(call gen_install_rules,bstrap-host_gcc_core,install_bstrap-host_gcc_core)
$(call gen_uninstall_rules,bstrap-host_gcc_core,uninstall_bstrap-host_gcc_core)
$(call gen_check_rules,bstrap-host_gcc_core,check_bstrap-host_gcc_core)
$(call gen_dir_rules,bstrap-host_gcc_core)

################################################################################
# Bootstrap libgcc definitions
################################################################################

$(call gen_deps,bstrap-target_libgcc,bstrap-target_glibc_startup)

build_bstrap-target_libgcc     = $(call gcc_build_cmds,bstrap-host_gcc,\
                                                       all-target-libgcc)
clean_bstrap-target_libgcc     = $(call gcc_clean_cmds,bstrap-host_gcc,\
                                                       clean-target-libgcc)

define install_bstrap-target_libgcc
$(call gcc_install_cmds,bstrap-host_gcc,install-target-libgcc)
endef

define uninstall_bstrap-target_libgcc
$(call gcc_uninstall_cmds,bstrap-host_gcc,$(bstrapdir),uninstall-target-libgcc)
endef

$(call gen_config_rules_with_dep,bstrap-target_libgcc,gcc)
$(call gen_build_rules,bstrap-target_libgcc,build_bstrap-target_libgcc)
$(call gen_clean_rules,bstrap-target_libgcc,clean_bstrap-target_libgcc)
$(call gen_install_rules,bstrap-target_libgcc,install_bstrap-target_libgcc)
$(call gen_uninstall_rules,bstrap-target_libgcc,uninstall_bstrap-target_libgcc)
$(call gen_dir_rules,bstrap-target_libgcc)

################################################################################
# Bootstrap full gcc definitions
################################################################################

$(call gen_deps,bstrap-host_gcc,bstrap-target_glibc)

build_bstrap-host_gcc = $(call gcc_build_cmds,bstrap-host_gcc,all)

define clean_bstrap-host_gcc
$(call gcc_clean_cmds,bstrap-host_gcc,clean)
$(RM) $(stampdir)/bstrap-target_libgcc/built
$(RM) $(stampdir)/bstrap-host_gcc_core/built
endef

define install_bstrap-host_gcc
$(call gcc_install_cmds,bstrap-host_gcc,install-strip)
$(call gcc_cleanup_sysroot_libs_rpath,\
       $(bstrap_sysroot),\
       libasan.so.* libstdc++.so.* libubsan.so.*)
endef

define uninstall_bstrap-host_gcc
$(call gcc_uninstall_cmds,bstrap-host_gcc,$(bstrapdir),uninstall)
$(RM) $(stampdir)/bstrap-target_libgcc/installed
$(RM) $(stampdir)/bstrap-host_gcc_core/installed
endef

define clobber_bstrap-host_gcc
$(RM) -r $(builddir)/bstrap-target_libgcc
$(RM) -r $(stampdir)/bstrap-target_libgcc
$(RM) -r $(builddir)/bstrap-host_gcc_core
$(RM) -r $(stampdir)/bstrap-host_gcc_core
endef

$(call gen_config_rules_with_dep,bstrap-host_gcc,gcc)
$(call gen_clobber_rules,bstrap-host_gcc,clobber_bstrap-host_gcc)
$(call gen_build_rules,bstrap-host_gcc,build_bstrap-host_gcc)
$(call gen_clean_rules,bstrap-host_gcc,clean_bstrap-host_gcc)
$(call gen_install_rules,bstrap-host_gcc,install_bstrap-host_gcc)
$(call gen_uninstall_rules,bstrap-host_gcc,uninstall_bstrap-host_gcc)
$(call gen_dir_rules,bstrap-host_gcc)

################################################################################
## Staging definitions
################################################################################

gcc_stage_host_args  = \
	$(gcc_common_args) \
	--with-sysroot='$(stage_sysroot)' \
	--disable-bootstrap \
	--disable-nls \
	--disable-gprofng \
	--enable-languages=c,c++,lto \
	--disable-werror \
	--enable-libsanitizer \
	--enable-libgomp \
	--with-gxx-include-dir='$(stage_sysroot)/include/c++/$(gcc_vers_maj)' \
	--with-toolexeclibdir='$(stage_sysroot)/lib' \
	--enable-libstdcxx-threads \
	--enable-vtable-verify \
	--with-system-libunwind \
	MAKEINFO='/bin/true' \
	$(call gcc_target_flags,$(bstrapdir)) \
	$(GCC_STAGE_TARGET_ARGS)

$(call gen_deps,stage-host_gcc,stage-target_glibc stage-host_binutils)

config_stage-host_gcc    = $(call gcc_config_cmds,stage-host_gcc,\
                                                  $(stagedir),\
                                                  $(gcc_stage_host_args))
build_stage-host_gcc     = $(call gcc_build_cmds,stage-host_gcc,all)
clean_stage-host_gcc     = $(call gcc_clean_cmds,stage-host_gcc,clean)
define install_stage-host_gcc
$(call gcc_install_cmds,stage-host_gcc,install-strip)
$(call gcc_cleanup_sysroot_libs_rpath,\
       $(stage_sysroot),\
       libasan.so.* libstdc++.so.* libubsan.so.*)
$(call gcc_install_plugins_cmds,$(stagedir))
endef
uninstall_stage-host_gcc = $(call gcc_uninstall_cmds,stage-host_gcc,\
                                                     $(stagedir),\
                                                     uninstall)

$(call gen_config_rules_with_dep,stage-host_gcc,gcc,config_stage-host_gcc)
$(call gen_clobber_rules,stage-host_gcc)
$(call gen_build_rules,stage-host_gcc,build_stage-host_gcc)
$(call gen_clean_rules,stage-host_gcc,clean_stage-host_gcc)
$(call gen_install_rules,stage-host_gcc,install_stage-host_gcc)
$(call gen_uninstall_rules,stage-host_gcc,uninstall_stage-host_gcc)
$(call gen_dir_rules,stage-host_gcc)

################################################################################
## Final definitions
################################################################################

gcc_final_host_args = \
	$(gcc_common_args) \
	--with-sysroot='$(final_sysroot)' \
	--disable-bootstrap \
	--enable-nls \
	--disable-gprofng \
	--enable-languages=c,c++,lto \
	--disable-werror \
	--enable-libsanitizer \
	--enable-libgomp \
	--with-gxx-include-dir='$(final_sysroot)/include/c++/$(gcc_vers_maj)' \
	--with-toolexeclibdir='$(final_sysroot)/lib' \
	--enable-libstdcxx-threads \
	--enable-vtable-verify \
	--with-system-libunwind \
	$(call gcc_target_flags,$(stagedir)) \
	$(GCC_FINAL_TARGET_ARGS)

$(call gen_deps,final-host_gcc,final-target_glibc stage-target_libunwind)

config_final-host_gcc    = $(call gcc_config_cmds,final-host_gcc,\
                                                  $(finaldir)$(PREFIX),\
                                                  $(gcc_final_host_args))
build_final-host_gcc     = $(call gcc_build_cmds,final-host_gcc,all)
clean_final-host_gcc     = $(call gcc_clean_cmds,final-host_gcc,clean)
define install_final-host_gcc
$(call gcc_install_cmds,final-host_gcc,install)
$(call gcc_cleanup_sysroot_libs_rpath,\
       $(final_sysroot),\
       libasan.so.* libstdc++.so.* libubsan.so.*)
$(call gcc_install_plugins_cmds,$(finaldir)$(PREFIX))
endef
uninstall_final-host_gcc = $(call gcc_uninstall_cmds,final-host_gcc,\
                                                     $(finaldir)$(PREFIX),\
                                                     uninstall)

$(call gen_config_rules_with_dep,final-host_gcc,gcc,config_final-host_gcc)
$(call gen_clobber_rules,final-host_gcc)
$(call gen_build_rules,final-host_gcc,build_final-host_gcc)
$(call gen_clean_rules,final-host_gcc,clean_final-host_gcc)
$(call gen_install_rules,final-host_gcc,install_final-host_gcc)
$(call gen_uninstall_rules,final-host_gcc,uninstall_final-host_gcc)
$(call gen_dir_rules,final-host_gcc)
