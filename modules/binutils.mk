################################################################################
# binutils modules
#
# Requires the following bookworm packages to build:
# libmsgpack-dev
# libxxhash-dev
################################################################################

binutils_dist_url  := https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.lz
binutils_dist_sum  := 87f1b5017ed2702a1af8f07f0ddd110289df56ec70643813b3e31922c01de590922ce3009f0dbc149ea4074dbe2f0927ec8ec83aeedd83734b7523a4e3221cff
binutils_dist_name := $(notdir $(binutils_dist_url))
binutils_vers      := $(patsubst binutils-%.tar.lz,%,$(binutils_dist_name))
binutils_brief     := GNU assembler, linker and binary utilities
binutils_home      := https://www.gnu.org/software/binutils/

define binutils_desc
The programs in this package are used to assemble, link and manipulate binary
and object files. They may be used in conjunction with a compiler and various
libraries to build programs.
endef

define fetch_binutils_dist
$(call download_csum,$(binutils_dist_url),\
                     $(binutils_dist_name),\
                     $(binutils_dist_sum))
endef
$(call gen_fetch_rules,binutils,binutils_dist_name,fetch_binutils_dist)

define xtract_binutils
$(call rmrf,$(srcdir)/binutils)
$(call untar,$(srcdir)/binutils,\
             $(FETCHDIR)/$(binutils_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,binutils,xtract_binutils)

$(call gen_dir_rules,binutils)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define binutils_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/binutils/configure --prefix='$(strip $(2))' \
                             $(3) \
                             $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional make arguments
define binutils_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         all \
         $(2) \
         $(verbose)
endef

# $(1): targets base name / module name
define binutils_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional make arguments
# $(3): optional install destination directory
define binutils_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(if $(3),DESTDIR='$(3)') \
         $(libtool_flags) \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define binutils_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
define binutils_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         check \
         $(2)
endef

# --disable-new-dtags:
#   Make sure RPATH takes precedence over LD_LIBRARY_PATH and RUNPATH at
#   runtime.
binutils_common_args := --build="$(BUILD_UPLET)" \
                        --host="$(BUILD_UPLET)" \
                        --with-pkgversion='$(pkgvers)' \
                        --with-bugurl='$(pkgurl)' \
                        --enable-silent-rules \
                        --enable-static \
                        --enable-plugins \
                        --enable-checking \
                        --disable-multilib \
                        --enable-ld=default \
                        --disable-gold \
                        --disable-gprofng \
                        --enable-year2038 \
                        --enable-threads \
                        --enable-deterministic-archives \
                        --disable-new-dtags \
                        --enable-initfini-array \
                        --enable-default-hash-style=gnu \
                        --enable-textrel-check=yes \
                        --enable-error-handling-script \
                        --enable-relro \
                        --enable-memory-seal \
                        --enable-secureplt \
                        --enable-install-libbfd \
                        --enable-install-libiberty \
                        --enable-libssp \
                        --enable-lto \
                        --enable-host-pie \
                        --enable-vtable-verify \
                        --with-system-zlib \
                        --with-zstd \
                        --with-xxhash \
                        --enable-warn-execstack \
                        --enable-warn-rwx-segments \
                        --enable-default-execstack=no \
                        $(config_build_tools)

################################################################################
# Bootstrapping definitions
################################################################################

binutils_bstrap_host_args := \
	$(binutils_common_args) \
	--with-sysroot='$(bstrap_sysroot)' \
	--without-debuginfod \
	--disable-nls \
	MAKEINFO='/bin/true' \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS)' \
	$(BINUTILS_BSTRAP_TARGET_ARGS)

$(call gen_deps,bstrap-host_binutils,bstrap-host_mpc bstrap-host_isl)

config_bstrap-host_binutils    = $(call binutils_config_cmds,\
                                        bstrap-host_binutils,\
                                        $(bstrapdir),\
                                        $(binutils_bstrap_host_args))
build_bstrap-host_binutils     = $(call binutils_build_cmds,\
                                        bstrap-host_binutils,\
                                        MAKEINFO='/bin/true')
clean_bstrap-host_binutils     = $(call binutils_clean_cmds,\
                                        bstrap-host_binutils)
install_bstrap-host_binutils   = $(call binutils_install_cmds,\
                                        bstrap-host_binutils,\
                                        install-strip MAKEINFO='/bin/true')
uninstall_bstrap-host_binutils = $(call binutils_uninstall_cmds,\
                                        bstrap-host_binutils,\
                                        $(bstrapdir))
check_bstrap-host_binutils     = $(call binutils_check_cmds,\
                                        bstrap-host_binutils)

$(call gen_config_rules_with_dep,bstrap-host_binutils,\
                                 binutils,\
                                 config_bstrap-host_binutils)
$(call gen_clobber_rules,bstrap-host_binutils)
$(call gen_build_rules,bstrap-host_binutils,build_bstrap-host_binutils)
$(call gen_clean_rules,bstrap-host_binutils,clean_bstrap-host_binutils)
$(call gen_install_rules,bstrap-host_binutils,install_bstrap-host_binutils)
$(call gen_uninstall_rules,bstrap-host_binutils,uninstall_bstrap-host_binutils)
$(call gen_check_rules,bstrap-host_binutils,check_bstrap-host_binutils)
$(call gen_dir_rules,bstrap-host_binutils)

################################################################################
# Staging definitions
################################################################################

binutils_stage_host_args := \
	$(binutils_common_args) \
	--with-sysroot='$(stage_sysroot)' \
	--enable-shared \
	--without-debuginfod \
	--disable-nls \
	--with-gmp='$(bstrapdir)' \
	--with-mpfr='$(bstrapdir)' \
	--with-mpc='$(bstrapdir)' \
	--with-isl='$(bstrapdir)' \
	MAKEINFO='/bin/true' \
	$(call pkg_config_path,$(bstrapdir)) \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS)' \
	$(BINUTILS_STAGE_TARGET_ARGS)

$(call gen_deps,stage-host_binutils,bstrap-host_mpc bstrap-host_isl)

config_stage-host_binutils    = $(call binutils_config_cmds,\
                                       stage-host_binutils,\
                                       $(stagedir),\
                                       $(binutils_stage_host_args))
build_stage-host_binutils     = $(call binutils_build_cmds,\
                                       stage-host_binutils,\
                                       MAKEINFO='/bin/true')
clean_stage-host_binutils     = $(call binutils_clean_cmds,stage-host_binutils)
install_stage-host_binutils   = $(call binutils_install_cmds,\
                                       stage-host_binutils,\
                                       install-strip MAKEINFO='/bin/true')
uninstall_stage-host_binutils = $(call binutils_uninstall_cmds,\
                                       stage-host_binutils,\
                                       $(stagedir))
check_stage-host_binutils     = $(call binutils_check_cmds,stage-host_binutils)

$(call gen_config_rules_with_dep,stage-host_binutils,\
                                 binutils,\
                                 config_stage-host_binutils)
$(call gen_clobber_rules,stage-host_binutils)
$(call gen_build_rules,stage-host_binutils,build_stage-host_binutils)
$(call gen_clean_rules,stage-host_binutils,clean_stage-host_binutils)
$(call gen_install_rules,stage-host_binutils,install_stage-host_binutils)
$(call gen_uninstall_rules,stage-host_binutils,uninstall_stage-host_binutils)
$(call gen_check_rules,stage-host_binutils,check_stage-host_binutils)
$(call gen_dir_rules,stage-host_binutils)

################################################################################
# Final definitions
################################################################################

binutils_final_host_args := \
	$(binutils_common_args) \
	--with-sysroot='$(PREFIX)$(target_sysroot)' \
	--with-build-sysroot='$(stage_sysroot)' \
	--enable-shared \
	--enable-nls \
	--with-debuginfod \
	--with-msgpack \
	--enable-colored-disassembly \
	--with-gmp='$(bstrapdir)' \
	--with-mpfr='$(bstrapdir)' \
	--with-mpc='$(bstrapdir)' \
	--with-isl='$(bstrapdir)' \
	$(call pkg_config_path,$(stagedir)) \
	CPPFLAGS='$(BUILD_CPPFLAGS) -I$(stagedir)/include' \
	CFLAGS='$(BUILD_CFLAGS) -I$(stagedir)/include' \
	CXXFLAGS='$(BUILD_CXXFLAGS) -I$(stagedir)/include' \
	LDFLAGS='$(BUILD_LDFLAGS)' \
	$(BINUTILS_FINAL_TARGET_ARGS)

$(call gen_deps,final-host_binutils,\
                bstrap-host_mpc bstrap-host_isl stage-host_elfutils)

config_final-host_binutils    = $(call binutils_config_cmds,\
                                       final-host_binutils,\
                                       $(PREFIX),\
                                       $(binutils_final_host_args))
build_final-host_binutils     = $(call binutils_build_cmds,\
                                       final-host_binutils)
clean_final-host_binutils     = $(call binutils_clean_cmds,\
                                       final-host_binutils)
install_final-host_binutils   = $(call binutils_install_cmds,\
                                       final-host_binutils,\
                                       install,\
                                       $(finaldir))
uninstall_final-host_binutils = $(call binutils_uninstall_cmds,\
                                       final-host_binutils,\
                                       $(PREFIX),\
                                       $(finaldir))
check_final-host_binutils     = $(call binutils_check_cmds,final-host_binutils)

$(call gen_config_rules_with_dep,final-host_binutils,\
                                 binutils,\
                                 config_final-host_binutils)
$(call gen_clobber_rules,final-host_binutils)
$(call gen_build_rules,final-host_binutils,build_final-host_binutils)
$(call gen_clean_rules,final-host_binutils,clean_final-host_binutils)
$(call gen_install_rules,final-host_binutils,install_final-host_binutils)
$(call gen_uninstall_rules,final-host_binutils,uninstall_final-host_binutils)
$(call gen_check_rules,final-host_binutils,check_final-host_binutils)
$(call gen_dir_rules,final-host_binutils)
