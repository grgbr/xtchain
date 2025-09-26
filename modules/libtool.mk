################################################################################
# libtool modules
#
# Requires the following bookworm packages to build:
# help2man
################################################################################

libtool_dist_url  := https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz
libtool_dist_sum  := eed207094bcc444f4bfbb13710e395e062e3f1d312ca8b186ab0cbd22dc92ddef176a0b3ecd43e02676e37bd9e328791c59a38ef15846d4eae15da4f20315724
libtool_dist_name := $(notdir $(libtool_dist_url))
libtool_vers      := $(patsubst libtool-%.tar.xz,%,$(libtool_dist_name))
libtool_brief     := The GNU Portable Library Tool
libtool_home      := https://www.gnu.org/software/libtool/

define libtool_desc
GNU Libtool is a generic library support script that hides the complexity of
using shared libraries behind a consistent, portable interface.
endef

define fetch_libtool_dist
$(call download_csum,$(libtool_dist_url),\
                     $(libtool_dist_name),\
                     $(libtool_dist_sum))
endef
$(call gen_fetch_rules,libtool,libtool_dist_name,fetch_libtool_dist)

define xtract_libtool
$(call rmrf,$(srcdir)/libtool)
$(call untar,$(srcdir)/libtool,\
             $(FETCHDIR)/$(libtool_dist_name),\
             --strip-components=1)
$(call patch,$(srcdir)/libtool,\
             $(PATCHDIR)/libtool-2.5.4-000-fix_sysroot_paths_being_encoded_into_rpath.patch \
             $(PATCHDIR)/libtool-2.5.4-001-ltmain_in_dont_encode_rpath_which_match_default_lin.patch \
             $(PATCHDIR)/libtool-2.5.4-002-avoid_relinking_when_cross_compiling_its_poi.patch)
endef
$(call gen_xtract_rules,libtool,xtract_libtool)

$(call gen_dir_rules,libtool)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define libtool_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/libtool/configure --prefix='$(strip $(2))' $(3) $(verbose)
endef

# $(1): targets base name / module name
define libtool_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) all $(verbose)
endef

# $(1): targets base name / module name
define libtool_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): optional install destination directory
define libtool_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         install \
         $(if $(strip $(2)),DESTDIR='$(strip $(2))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define libtool_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
define libtool_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check
endef

libtool_common_args := \
	--build='$(BUILD_UPLET)' \
	--host='$(TARGET_UPLET)' \
	--program-prefix='$(TARGET_UPLET)-' \
	--enable-silent-rules \
	--enable-shared \
	--enable-static \
	--disable-ltdl-install \
	--with-gnu-ld \
	$(call config_target_tools,$(stagedir)) \
	CPPFLAGS='$(call xclude_flags,$(fortify_flags),$(TARGET_CPPFLAGS))' \
	CFLAGS='$(call xclude_flags,$(fortify_flags),$(TARGET_CFLAGS))' \
	CXXFLAGS='$(call xclude_flags,$(fortify_flags),$(TARGET_CXXFLAGS))' \
	LDFLAGS='$(call xclude_flags,$(fortify_flags),$(TARGET_LDFLAGS))'

################################################################################
# Staging libtool definitions
################################################################################

libtool_stage_host_args := $(libtool_common_args) \
                           --with-sysroot='$(stage_sysroot)'

$(call gen_deps,stage-host_libtool,stage-host_gcc)

config_stage-host_libtool    = $(call libtool_config_cmds,\
                                      stage-host_libtool,\
                                      $(stagedir),\
                                      $(libtool_stage_host_args))
build_stage-host_libtool     = $(call libtool_build_cmds,stage-host_libtool)
clean_stage-host_libtool     = $(call libtool_clean_cmds,stage-host_libtool)
install_stage-host_libtool   = $(call libtool_install_cmds,stage-host_libtool)
uninstall_stage-host_libtool = $(call libtool_uninstall_cmds,\
                                      stage-host_libtool,\
                                      $(stagedir))
check_stage-host_libtool     = $(call libtool_check_cmds,stage-host_libtool)

$(call gen_config_rules_with_dep,stage-host_libtool,\
                                 libtool,\
                                 config_stage-host_libtool)
$(call gen_clobber_rules,stage-host_libtool)
$(call gen_build_rules,stage-host_libtool,build_stage-host_libtool)
$(call gen_clean_rules,stage-host_libtool,clean_stage-host_libtool)
$(call gen_install_rules,stage-host_libtool,install_stage-host_libtool)
$(call gen_uninstall_rules,stage-host_libtool,uninstall_stage-host_libtool)
$(call gen_check_rules,stage-host_libtool,check_stage-host_libtool)
$(call gen_dir_rules,stage-host_libtool)

################################################################################
# Final libtool definitions
################################################################################

libtool_final_host_args := $(libtool_common_args) \
                           --with-sysroot='$(final_sysroot)'

$(call gen_deps,final-host_libtool,final-host_gcc)

config_final-host_libtool    = $(call libtool_config_cmds,\
                                      final-host_libtool,\
                                      $(PREFIX),\
                                      $(libtool_final_host_args))
build_final-host_libtool     = $(call libtool_build_cmds,final-host_libtool)
clean_final-host_libtool     = $(call libtool_clean_cmds,final-host_libtool)
install_final-host_libtool   = $(call libtool_install_cmds,final-host_libtool,\
                                                           $(finaldir))
uninstall_final-host_libtool = $(call libtool_uninstall_cmds,\
                                      final-host_libtool,\
                                      $(PREFIX),\
                                      $(finaldir))
check_final-host_libtool     = $(call libtool_check_cmds,final-host_libtool)

$(call gen_config_rules_with_dep,final-host_libtool,\
                                 libtool,\
                                 config_final-host_libtool)
$(call gen_clobber_rules,final-host_libtool)
$(call gen_build_rules,final-host_libtool,build_final-host_libtool)
$(call gen_clean_rules,final-host_libtool,clean_final-host_libtool)
$(call gen_install_rules,final-host_libtool,install_final-host_libtool)
$(call gen_uninstall_rules,final-host_libtool,uninstall_final-host_libtool)
$(call gen_check_rules,final-host_libtool,check_final-host_libtool)
$(call gen_dir_rules,final-host_libtool)
