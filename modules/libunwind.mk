################################################################################
# libunwind modules
################################################################################

libunwind_dist_url  := https://github.com/libunwind/libunwind/releases/download/v1.8.2/libunwind-1.8.2.tar.gz
libunwind_dist_sum  := f1ff26763c1b2e68948413c4aec22303b6c886425a8264eb65fbd58fc202f79c7b04bd4784bd8499850d08933f0e363cfa3a7d177efdadc223ed0254bc381345
libunwind_dist_name := $(notdir $(libunwind_dist_url))
libunwind_vers      := $(patsubst libunwind-%.tar.gz,%,$(libunwind_dist_name))
libunwind_brief     := The libunwind project
libunwind_home      := https://www.nongnu.org/libunwind/

define libunwind_desc
libunwind is a portable and efficient C API for determining the current call
chain of ELF program threads of execution and for resuming execution at any
point in that call chain. The API supports both local (same process) and remote
(other process) operation.
endef

define fetch_libunwind_dist
$(call download_csum,$(libunwind_dist_url),\
                     $(libunwind_dist_name),\
                     $(libunwind_dist_sum))
endef
$(call gen_fetch_rules,libunwind,libunwind_dist_name,fetch_libunwind_dist)

define xtract_libunwind
$(call rmrf,$(srcdir)/libunwind)
$(call untar,$(srcdir)/libunwind,\
             $(FETCHDIR)/$(libunwind_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,libunwind,xtract_libunwind)

$(call gen_dir_rules,libunwind)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define libunwind_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/libunwind/configure --prefix='$(strip $(2))' $(3) $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and variables
define libunwind_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
define libunwind_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and variables
# $(3): optional install destination directory
define libunwind_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define libunwind_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
define libunwind_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check $(2)
endef

libunwind_common_args := --build='$(BUILD_UPLET)' \
                         --host='$(TARGET_UPLET)' \
                         --enable-silent-rules \
                         --enable-shared \
                         --enable-static \
                         --with-gnu-ld \
                         --disable-msabi-support \
                         --enable-coredump \
                         --enable-ptrace \
                         --enable-nto \
                         --enable-setjmp \
                         --enable-cxx-exceptions \
                         --enable-debug-frame \
                         $(call config_target_tools,$(stagedir))

################################################################################
# Staging libunwind definitions
################################################################################

libunwind_stage_target_args := $(libunwind_common_args) \
                        --with-sysroot='$(stage_sysroot)' \
                        --disable-documentation \
                        CPPFLAGS='$(TARGET_CPPFLAGS)' \
                        CFLAGS='$(TARGET_CFLAGS)' \
                        CXXFLAGS='$(TARGET_CXXFLAGS)' \
                        LDFLAGS='$(TARGET_LDFLAGS)'

$(call gen_deps,stage-target_libunwind,stage-host_gcc)

config_stage-target_libunwind    = $(call libunwind_config_cmds,\
                                          stage-target_libunwind,\
                                          $(TARGET_PREFIX),\
                                          $(libunwind_stage_target_args))
build_stage-target_libunwind     = $(call libunwind_build_cmds,\
                                          stage-target_libunwind,\
                                          all)
clean_stage-target_libunwind     = $(call libunwind_clean_cmds,\
                                          stage-target_libunwind)
install_stage-target_libunwind   = $(call libunwind_install_cmds,\
                                          stage-target_libunwind,\
                                          install,\
                                          $(stage_sysroot))
uninstall_stage-target_libunwind = $(call libunwind_uninstall_cmds,\
                                          stage-target_libunwind,\
                                          $(TARGET_PREFIX),\
                                          $(stage_sysroot))
check_stage-target_libunwind     = $(call libunwind_check_cmds,\
                                          stage-target_libunwind)

$(call gen_config_rules_with_dep,stage-target_libunwind,\
                                 libunwind,\
                                 config_stage-target_libunwind)
$(call gen_clobber_rules,stage-target_libunwind)
$(call gen_build_rules,stage-target_libunwind,build_stage-target_libunwind)
$(call gen_clean_rules,stage-target_libunwind,clean_stage-target_libunwind)
$(call gen_install_rules,stage-target_libunwind,install_stage-target_libunwind)
$(call gen_uninstall_rules,stage-target_libunwind,\
                           uninstall_stage-target_libunwind)
$(call gen_check_rules,stage-target_libunwind,check_stage-target_libunwind)
$(call gen_dir_rules,stage-target_libunwind)

################################################################################
# Final libunwind definitions
#
# TODO: refine config flags ?
# --enable-minidebuginfo  Enables support for LZMA-compressed symbol tables
# --enable-block-signals  Block signals before performing mutex operations
# --enable-conservative-checks Validate all memory addresses before use
################################################################################

libunwind_final_target_args := \
	$(libunwind_common_args) \
	--with-sysroot='$(final_sysroot)' \
	--enable-documentation \
	--enable-zlibdebuginfo \
	CPPFLAGS='$(TARGET_CPPFLAGS) --sysroot=$(final_sysroot)' \
	CFLAGS='$(TARGET_CFLAGS)' \
	CXXFLAGS='$(TARGET_CXXFLAGS)' \
	LDFLAGS='$(TARGET_LDFLAGS) --sysroot=$(final_sysroot)'

$(call gen_deps,final-target_libunwind,stage-host_libtool final-target_zlib)

config_final-target_libunwind    = $(call libunwind_config_cmds,\
                                   final-target_libunwind,\
                                   $(TARGET_PREFIX),\
                                   $(libunwind_final_target_args))
build_final-target_libunwind     = \
	$(call libunwind_build_cmds,\
	       final-target_libunwind,\
	       all \
	       LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool' \
	       $(libtool_flags))
clean_final-target_libunwind     = $(call libunwind_clean_cmds,\
                                          final-target_libunwind)
install_final-target_libunwind   = \
	$(call libunwind_install_cmds,\
	       final-target_libunwind,\
	       install \
	       LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool' \
	       $(libtool_flags),\
	       $(final_sysroot))
uninstall_final-target_libunwind = $(call libunwind_uninstall_cmds,\
                                   final-target_libunwind,\
                                   $(TARGET_PREFIX),\
                                   $(final_sysroot))
check_final-target_libunwind     = $(call libunwind_check_cmds,\
                                          final-target_libunwind)

$(call gen_config_rules_with_dep,final-target_libunwind,\
                                 libunwind,\
                                 config_final-target_libunwind)
$(call gen_clobber_rules,final-target_libunwind)
$(call gen_build_rules,final-target_libunwind,build_final-target_libunwind)
$(call gen_clean_rules,final-target_libunwind,clean_final-target_libunwind)
$(call gen_install_rules,final-target_libunwind,install_final-target_libunwind)
$(call gen_uninstall_rules,final-target_libunwind,\
                           uninstall_final-target_libunwind)
$(call gen_check_rules,final-target_libunwind,check_final-target_libunwind)
$(call gen_dir_rules,final-target_libunwind)
