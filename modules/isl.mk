################################################################################
# isl modules
################################################################################

isl_dist_url  := https://libisl.sourceforge.io/isl-0.24.tar.xz
isl_dist_sum  := ff6bdcff839e1cd473f2a0c1e4dd4a3612ec6fee4544ccbc62b530a7248db2cf93b4b99bf493a86ddf2aba00e768927265d5d411f92061ea85fd7929073428e8
isl_dist_name := $(notdir $(isl_dist_url))
isl_vers      := $(patsubst isl-%.tar.xz,%,$(isl_dist_name))
isl_brief     := Manipulating sets and relations of integer points bounded by linear constraints
isl_home      := http://isl.gforge.inria.fr/

define isl_desc
isl is a library for manipulating sets and relations of integer points bounded
by linear constraints. Supported operations on sets include intersection, union,
set difference, emptiness check, convex hull, (integer) affine hull, integer
projection, and computing the lexicographic minimum using parametric integer
programming. It also includes an ILP solver based on generalized basis
reduction.
endef

define fetch_isl_dist
$(call download_csum,$(isl_dist_url),\
                     $(isl_dist_name),\
                     $(isl_dist_sum))
endef
$(call gen_fetch_rules,isl,isl_dist_name,fetch_isl_dist)

define xtract_isl
$(call rmrf,$(srcdir)/isl)
$(call untar,$(srcdir)/isl,\
             $(FETCHDIR)/$(isl_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,isl,xtract_isl)

$(call gen_dir_rules,isl)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define isl_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/isl/configure --prefix='$(strip $(2))' \
                        $(3) \
                        $(verbose)
endef

# $(1): targets base name / module name
define isl_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         all \
         $(verbose)
endef

# $(1): targets base name / module name
define isl_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): make targets and variables
# $(3): optional install destination directory
define isl_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(libtool_flags) \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define isl_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
define isl_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         check
endef

isl_common_args := \
	--enable-silent-rules \
	--enable-static \
	--enable-shared \
	--with-gnu-ld \
	--with-int=gmp \
	--with-gmp=build \
	--without-gcc-arch

isl_common_host_args := \
	$(isl_common_args) \
	--with-sysroot='$(bstrapdir)' \
	--with-gmp-builddir=$(builddir)/bstrap-host_gmp \
	$(config_build_tools)

################################################################################
# Bootstrapping definitions
################################################################################

isl_bstrap_host_args := \
	$(isl_common_host_args) \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS)'

$(call gen_deps,bstrap-host_isl,bstrap-host_gmp)

config_bstrap-host_isl    = $(call isl_config_cmds,bstrap-host_isl,\
                                                   $(bstrapdir),\
                                                   $(isl_bstrap_host_args))
build_bstrap-host_isl     = $(call isl_build_cmds,bstrap-host_isl)
clean_bstrap-host_isl     = $(call isl_clean_cmds,bstrap-host_isl)
install_bstrap-host_isl   = $(call isl_install_cmds,bstrap-host_isl,\
                                                    install-strip)
uninstall_bstrap-host_isl = $(call isl_uninstall_cmds,bstrap-host_isl,\
                                                      $(bstrapdir))
check_bstrap-host_isl     = $(call isl_check_cmds,bstrap-host_isl)

$(call gen_config_rules_with_dep,bstrap-host_isl,isl,config_bstrap-host_isl)
$(call gen_clobber_rules,bstrap-host_isl)
$(call gen_build_rules,bstrap-host_isl,build_bstrap-host_isl)
$(call gen_clean_rules,bstrap-host_isl,clean_bstrap-host_isl)
$(call gen_install_rules,bstrap-host_isl,install_bstrap-host_isl)
$(call gen_uninstall_rules,bstrap-host_isl,uninstall_bstrap-host_isl)
$(call gen_check_rules,bstrap-host_isl,check_bstrap-host_isl)
$(call gen_dir_rules,bstrap-host_isl)

################################################################################
# Final host definitions
################################################################################

isl_final_host_args := \
	$(isl_common_host_args) \
	CPPFLAGS='$(BUILD_CPPFLAGS) -I$(bstrapdir)/include' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS) -L$(bstrapdir)/lib -Wl,-rpath,$(PREFIX)/lib' \
	LT_SYS_LIBRARY_PATH='$(bstrapdir)/lib'

$(call gen_deps,final-host_isl,bstrap-host_gmp)

config_final-host_isl    = $(call isl_config_cmds,final-host_isl, \
                                                  $(PREFIX), \
                                                  $(isl_final_host_args))
build_final-host_isl     = $(call isl_build_cmds,final-host_isl)
clean_final-host_isl     = $(call isl_clean_cmds,final-host_isl)

define install_final-host_isl
$(call isl_install_cmds,final-host_isl,install,$(finaldir))
$(SED) -i 's;$(bstrapdir);$(PREFIX);g' $(finaldir)$(PREFIX)/lib/libisl.la
endef

uninstall_final-host_isl = $(call isl_uninstall_cmds,final-host_isl,$(PREFIX),$(finaldir))
check_final-host_isl     = $(call isl_check_cmds,final-host_isl)

$(call gen_config_rules_with_dep,final-host_isl,isl,config_final-host_isl)
$(call gen_clobber_rules,final-host_isl)
$(call gen_build_rules,final-host_isl,build_final-host_isl)
$(call gen_clean_rules,final-host_isl,clean_final-host_isl)
$(call gen_install_rules,final-host_isl,install_final-host_isl)
$(call gen_uninstall_rules,final-host_isl,uninstall_final-host_isl)
$(call gen_check_rules,final-host_isl,check_final-host_isl)
$(call gen_dir_rules,final-host_isl)

################################################################################
# Final target definitions
################################################################################

isl_final_target_args := \
	$(isl_common_args) \
	$(ISL_FINAL_TARGET_ARGS) \
	--host='$(TARGET_UPLET)' \
	--with-sysroot='$(final_sysroot)' \
	--with-gmp-builddir='$(builddir)/final-target_gmp' \
	$(call config_target_tools,$(stagedir)) \
	CPPFLAGS='$(TARGET_CPPFLAGS) --sysroot=$(final_sysroot)' \
	CFLAGS='$(TARGET_CFLAGS)' \
	CXXFLAGS='$(TARGET_CXXFLAGS)' \
	LDFLAGS='$(TARGET_LDFLAGS) --sysroot=$(final_sysroot)'

$(call gen_deps,final-target_isl,final-target_gmp)

config_final-target_isl    = $(call isl_config_cmds,final-target_isl,\
                                                    $(TARGET_PREFIX),\
                                                    $(isl_final_target_args))
build_final-target_isl     = \
	$(call isl_build_cmds,\
	       final-target_isl,\
	       all LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool')
clean_final-target_isl     = $(call isl_clean_cmds,final-target_isl)
install_final-target_isl   = $(call isl_install_cmds,final-target_isl,\
                                                     install,\
                                                     $(final_sysroot))

uninstall_final-target_isl = $(call isl_uninstall_cmds,final-target_isl,\
                                                       $(TARGET_PREFIX),\
                                                       $(final_sysroot))
check_final-target_isl     = $(call isl_check_cmds,final-target_isl)

$(call gen_config_rules_with_dep,final-target_isl,isl,config_final-target_isl)
$(call gen_clobber_rules,final-target_isl)
$(call gen_build_rules,final-target_isl,build_final-target_isl)
$(call gen_clean_rules,final-target_isl,clean_final-target_isl)
$(call gen_install_rules,final-target_isl,install_final-target_isl)
$(call gen_uninstall_rules,final-target_isl,uninstall_final-target_isl)
$(call gen_check_rules,final-target_isl,check_final-target_isl)
$(call gen_dir_rules,final-target_isl)
