################################################################################
# elfutils modules
#
# Requires the following bookworm packages to build:
#     libjson-c-dev libcurl4-gnutls-dev libsysprof-4-dev libzstd-dev liblzma-dev
#     libbz2-dev zlib1g-dev libarchive-dev libsqlite3-dev libmicrohttpd-dev
################################################################################

elfutils_dist_url  := https://sourceware.org/elfutils/ftp/0.193/elfutils-0.193.tar.bz2
elfutils_dist_sum  := 557e328e3de0d2a69d09c15a9333f705f3233584e2c6a7d3ce855d06a12dc129e69168d6be64082803630397bd64e1660a8b5324d4f162d17922e10ddb367d76
elfutils_dist_name := $(notdir $(elfutils_dist_url))
elfutils_vers      := $(patsubst elfutils-%.tar.bz2,%,$(elfutils_dist_name))
elfutils_brief     := The elfutils project
elfutils_home      := https://sourceware.org/elfutils/

define elfutils_desc
elfutils is a collection of utilities and libraries to read, create and modify
ELF binary files, find and handle DWARF debug data, symbols, thread state and
stacktraces for processes and core files on GNU/Linux.
endef

define fetch_elfutils_dist
$(call download_csum,$(elfutils_dist_url),\
                     $(elfutils_dist_name),\
                     $(elfutils_dist_sum))
endef
$(call gen_fetch_rules,elfutils,elfutils_dist_name,fetch_elfutils_dist)

define xtract_elfutils
$(call rmrf,$(srcdir)/elfutils)
$(call untar,$(srcdir)/elfutils,\
             $(FETCHDIR)/$(elfutils_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,elfutils,xtract_elfutils)

$(call gen_dir_rules,elfutils)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define elfutils_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/elfutils/configure --prefix='$(strip $(2))' $(3) $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional make arguments
define elfutils_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         all \
         $(2) \
         $(verbose)
endef

# $(1): targets base name / module name
define elfutils_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and arguments
# $(3): optional install destination directory
define elfutils_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define elfutils_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
define elfutils_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check $(2)
endef

elfutils_common_args := --enable-silent-rules \
                        --enable-deterministic-archives \
                        --with-gnu-ld \
                        --disable-install-elfh \
                        --enable-libdebuginfod \
                        --enable-debuginfod \
                        --enable-stacktrace \
                        --enable-year2038 \
                        --with-zlib \
                        --with-bzlib \
                        --with-lzma \
                        --with-zstd \
                        $(config_build_tools)

################################################################################
# Staging elfutils definitions
################################################################################

elfutils_stage_host_args := \
	$(elfutils_common_args) \
	--disable-nls \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS) -Wno-werror' \
	CXXFLAGS='$(BUILD_CXXFLAGS) -Wno-werror' \
	LDFLAGS='$(BUILD_LDFLAGS)'

config_stage-host_elfutils    = $(call elfutils_config_cmds,\
                                  stage-host_elfutils,\
                                  $(stagedir),\
                                  $(elfutils_stage_host_args))
build_stage-host_elfutils     = $(call elfutils_build_cmds,\
                                       stage-host_elfutils,\
                                       stacktrace_no_Werror=yes)
clean_stage-host_elfutils     = $(call elfutils_clean_cmds,stage-host_elfutils)
install_stage-host_elfutils   = $(call elfutils_install_cmds,\
                                       stage-host_elfutils,\
                                       install-strip)
uninstall_stage-host_elfutils = $(call elfutils_uninstall_cmds,\
                                       stage-host_elfutils,\
                                       $(stagedir))
check_stage-host_elfutils     = $(call elfutils_check_cmds,stage-host_elfutils)

$(call gen_config_rules_with_dep,stage-host_elfutils,\
                                 elfutils,\
                                 config_stage-host_elfutils)
$(call gen_clobber_rules,stage-host_elfutils)
$(call gen_build_rules,stage-host_elfutils,build_stage-host_elfutils)
$(call gen_clean_rules,stage-host_elfutils,clean_stage-host_elfutils)
$(call gen_install_rules,stage-host_elfutils,install_stage-host_elfutils)
$(call gen_uninstall_rules,stage-host_elfutils,uninstall_stage-host_elfutils)
$(call gen_check_rules,stage-host_elfutils,check_stage-host_elfutils)
$(call gen_dir_rules,stage-host_elfutils)

################################################################################
# Final elfutils definitions
################################################################################

elfutils_final_host_args := \
	$(elfutils_common_args) \
	--enable-nls \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS) -Wno-werror' \
	CXXFLAGS='$(BUILD_CXXFLAGS) -Wno-werror' \
	LDFLAGS='$(BUILD_LDFLAGS) -Wl,-rpath,$(PREFIX)/lib'

config_final-host_elfutils    = $(call elfutils_config_cmds,\
                                  final-host_elfutils,\
                                  $(PREFIX),\
                                  $(elfutils_final_host_args))
build_final-host_elfutils     = $(call elfutils_build_cmds,\
                                       final-host_elfutils,\
                                       stacktrace_no_Werror=yes)
clean_final-host_elfutils     = $(call elfutils_clean_cmds,final-host_elfutils)
install_final-host_elfutils   = $(call elfutils_install_cmds,\
                                       final-host_elfutils,\
                                       install,\
                                       $(finaldir))
uninstall_final-host_elfutils = $(call elfutils_uninstall_cmds,\
                                       final-host_elfutils,\
                                       $(PREFIX),\
                                       $(finaldir))
check_final-host_elfutils     = $(call elfutils_check_cmds,final-host_elfutils)

$(call gen_config_rules_with_dep,final-host_elfutils,\
                                 elfutils,\
                                 config_final-host_elfutils)
$(call gen_clobber_rules,final-host_elfutils)
$(call gen_build_rules,final-host_elfutils,build_final-host_elfutils)
$(call gen_clean_rules,final-host_elfutils,clean_final-host_elfutils)
$(call gen_install_rules,final-host_elfutils,install_final-host_elfutils)
$(call gen_uninstall_rules,final-host_elfutils,uninstall_final-host_elfutils)
$(call gen_check_rules,final-host_elfutils,check_final-host_elfutils)
$(call gen_dir_rules,final-host_elfutils)
