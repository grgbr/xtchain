################################################################################
# zlib modules
#
# TODO: move to zlib-ng (https://github.com/zlib-ng/zlib-ng) ?
################################################################################

zlib_dist_url  := https://zlib.net/zlib-1.3.1.tar.xz
zlib_dist_sum  := 1e8e70b362d64a233591906a1f50b59001db04ca14aaffad522198b04680be501736e7d536b4191e2f99767e7001ca486cd802362cca2be05d5d409b83ea732d
zlib_dist_name := $(notdir $(zlib_dist_url))
zlib_vers      := $(patsubst zlib-%.tar.xz,%,$(zlib_dist_name))
zlib_brief     := Zlib compression library and tools.
zlib_home      := https://zlib.net/

define zlib_desc
Zlib is a free, general-purpose, legally unencumbered lossless data-compression
library for use on virtually any computer hardware and operating system.
endef

define fetch_zlib_dist
$(call download_csum,$(zlib_dist_url),\
                     $(zlib_dist_name),\
                     $(zlib_dist_sum))
endef
$(call gen_fetch_rules,zlib,zlib_dist_name,fetch_zlib_dist)

define xtract_zlib
$(call rmrf,$(srcdir)/zlib)
$(call untar,$(srcdir)/zlib,\
             $(FETCHDIR)/$(zlib_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,zlib,xtract_zlib)

$(call gen_dir_rules,zlib)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure environment
# $(4): configure arguments
define zlib_config_cmds
cd $(builddir)/$(strip $(1)) && \
env $(3) $(srcdir)/zlib/configure --prefix='$(strip $(2))' \
                                  $(4) \
                                  $(verbose)
endef

# $(1): targets base name / module name
define zlib_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) all $(verbose)
endef

# $(1): targets base name / module name
define zlib_clean_cmds
-+$(MAKE) --ignore-errors --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          clean \
          $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional install destination directory
define zlib_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         install \
         $(if $(strip $(2)),DESTDIR='$(strip $(2))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define zlib_uninstall_cmds
-+$(MAKE) --ignore-errors --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
define zlib_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check $(2)
endef

################################################################################
# Final zlib definitions
################################################################################

zlib_final_target_env := \
	CROSS_PREFIX='$(stagedir)/bin/$(TARGET_UPLET)-' \
	$(call config_target_tools,$(stagedir)) \
	CPPFLAGS='$(TARGET_CPPFLAGS) --sysroot=$(final_sysroot)' \
	CFLAGS='$(call xclude_flags,$(o_flags),$(TARGET_CFLAGS)) -O3' \
	CXXFLAGS='$(call xclude_flags,$(o_flags),$(TARGET_CXXFLAGS)) -O3' \
	LDFLAGS='$(call xclude_flags,$(o_flags),$(TARGET_LDFLAGS)) \
	         --sysroot=$(final_sysroot)'

zlib_final_target_args := --uname=linux

$(call gen_deps,final-target_zlib,final-host_gcc)

config_final-target_zlib    = $(call zlib_config_cmds,final-target_zlib,\
                                                      $(TARGET_PREFIX),\
                                                      $(zlib_final_target_env),\
                                                      $(zlib_final_target_args))
build_final-target_zlib     = $(call zlib_build_cmds,final-target_zlib)
clean_final-target_zlib     = $(call zlib_clean_cmds,final-target_zlib)
install_final-target_zlib   = $(call zlib_install_cmds,\
                                     final-target_zlib,\
                                     $(final_sysroot))
uninstall_final-target_zlib = $(call zlib_uninstall_cmds,\
                                     final-target_zlib,\
                                     $(TARGET_PREFIX),\
                                     $(final_sysroot))
check_final-target_zlib     = $(call zlib_check_cmds,final-target_zlib)

$(call gen_config_rules_with_dep,final-target_zlib,\
                                 zlib,\
                                 config_final-target_zlib)
$(call gen_clobber_rules,final-target_zlib)
$(call gen_build_rules,final-target_zlib,build_final-target_zlib)
$(call gen_clean_rules,final-target_zlib,clean_final-target_zlib)
$(call gen_install_rules,final-target_zlib,install_final-target_zlib)
$(call gen_uninstall_rules,final-target_zlib,uninstall_final-target_zlib)
$(call gen_check_rules,final-target_zlib,check_final-target_zlib)
$(call gen_dir_rules,final-target_zlib)
