################################################################################
# gmp modules
################################################################################

gmp_dist_url  := https://gmplib.org/download/gmp/gmp-6.2.1.tar.lz
gmp_dist_sum  := 40e1c80d1a2eda0ea190ba2a27e7bfe718ee1fc685082b4f2251f108ffbec94272199b35cf6df217c9f6f10ac4132eaf3c5014a9e25db0592b94f7f1ddd4994f
gmp_dist_name := $(notdir $(gmp_dist_url))
gmp_vers      := $(patsubst gmp-%.tar.lz,%,$(gmp_dist_name))
gmp_brief     := Multiprecision arithmetic library
gmp_home      := http://gmplib.org/

define gmp_desc
GNU MP is a programmer\'s library for arbitrary precision arithmetic (ie, a
bignum package).  It can operate on signed integer, rational, and floating point
numeric types.
endef

define fetch_gmp_dist
$(call download_csum,$(gmp_dist_url),$(gmp_dist_name),$(gmp_dist_sum))
endef
$(call gen_fetch_rules,gmp,gmp_dist_name,fetch_gmp_dist)

define xtract_gmp
$(call rmrf,$(srcdir)/gmp)
$(call untar,$(srcdir)/gmp,\
             $(FETCHDIR)/$(gmp_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,gmp,xtract_gmp)

$(call gen_dir_rules,gmp)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define gmp_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/gmp/configure --prefix='$(strip $(2))' $(3) $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and variables
define gmp_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
define gmp_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and variables
# $(3): optional install destination directory
define gmp_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(libtool_flags) \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): make target and variables
# $(4): optional install destination directory
define gmp_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          $(3) \
          $(if $(4),DESTDIR='$(4)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(4))$(strip $(2)))
endef

# $(1): targets base name / module name
define gmp_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check
endef

gmp_common_args := \
	--enable-silent-rules \
	--enable-static \
	--enable-shared \
	--with-gnu-ld \
	--disable-assert \
	--enable-cxx \
	--enable-assembly \
	--enable-fft \
	--enable-fat

gmp_host_common_args := \
	$(gmp_common_args) \
	$(config_build_tools) \
	ABI='$(build_mach_bits)' \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS)'

################################################################################
# Bootstrapping definitions
################################################################################

gmp_bstrap_host_args := $(gmp_host_common_args) \
                        MISSING='/bin/true'

config_bstrap-host_gmp    = $(call gmp_config_cmds,bstrap-host_gmp,\
                                                   $(bstrapdir),\
                                                   $(gmp_bstrap_host_args))
build_bstrap-host_gmp     = $(call gmp_build_cmds,bstrap-host_gmp,all)
clean_bstrap-host_gmp     = $(call gmp_clean_cmds,bstrap-host_gmp)
install_bstrap-host_gmp   = $(call gmp_install_cmds,bstrap-host_gmp,\
                                                    install-strip)
uninstall_bstrap-host_gmp = $(call gmp_uninstall_cmds,bstrap-host_gmp,\
                                                      $(bstrapdir),\
                                                      uninstall)
check_bstrap-host_gmp     = $(call gmp_check_cmds,bstrap-host_gmp)

$(call gen_config_rules_with_dep,bstrap-host_gmp,gmp,config_bstrap-host_gmp)
$(call gen_clobber_rules,bstrap-host_gmp)
$(call gen_build_rules,bstrap-host_gmp,build_bstrap-host_gmp)
$(call gen_clean_rules,bstrap-host_gmp,clean_bstrap-host_gmp)
$(call gen_install_rules,bstrap-host_gmp,install_bstrap-host_gmp)
$(call gen_uninstall_rules,bstrap-host_gmp,uninstall_bstrap-host_gmp)
$(call gen_check_rules,bstrap-host_gmp,check_bstrap-host_gmp)
$(call gen_dir_rules,bstrap-host_gmp)

################################################################################
# Final host definitions
################################################################################

host_gmp_final_args := $(gmp_host_common_args)

config_final-host_gmp    = $(call gmp_config_cmds,final-host_gmp,\
                                                  $(PREFIX),\
                                                  $(host_gmp_final_args))
build_final-host_gmp     = $(call gmp_build_cmds,final-host_gmp,all)
clean_final-host_gmp     = $(call gmp_clean_cmds,final-host_gmp)
install_final-host_gmp   = $(call gmp_install_cmds,final-host_gmp,\
                                                   install,\
                                                   $(finaldir))
uninstall_final-host_gmp = $(call gmp_uninstall_cmds,final-host_gmp,\
                                                     $(PREFIX),\
                                                     uninstall,\
                                                     $(finaldir))
check_final-host_gmp     = $(call gmp_check_cmds,final-host_gmp)

$(call gen_config_rules_with_dep,final-host_gmp,gmp,config_final-host_gmp)
$(call gen_clobber_rules,final-host_gmp)
$(call gen_build_rules,final-host_gmp,build_final-host_gmp)
$(call gen_clean_rules,final-host_gmp,clean_final-host_gmp)
$(call gen_install_rules,final-host_gmp,install_final-host_gmp)
$(call gen_uninstall_rules,final-host_gmp,uninstall_final-host_gmp)
$(call gen_check_rules,final-host_gmp,check_final-host_gmp)
$(call gen_dir_rules,final-host_gmp)

################################################################################
# Final target definitions
################################################################################

gmp_final_target_args := \
	$(gmp_common_args) \
	--host='$(TARGET_UPLET)' \
	--with-sysroot='$(final_sysroot)' \
	$(GMP_FINAL_TARGET_ARGS) \
	CC_FOR_BUILD='$(BUILD_CC)' \
	CPP_FOR_BUILD='$(BUILD_CPP)' \
	$(call config_target_tools,$(stagedir)) \
	CPPFLAGS='$(TARGET_CPPFLAGS)' \
	CFLAGS='$(TARGET_CFLAGS)' \
	CXXFLAGS='$(TARGET_CXXFLAGS)' \
	LDFLAGS='$(TARGET_LDFLAGS)'

$(call gen_deps,final-target_gmp,final-host_gcc stage-host_libtool)

config_final-target_gmp    = $(call gmp_config_cmds,final-target_gmp,\
                                                    $(TARGET_PREFIX),\
                                                    $(gmp_final_target_args))
build_final-target_gmp     = \
	$(call gmp_build_cmds,\
	       final-target_gmp,\
	       all LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool')
clean_final-target_gmp     = $(call gmp_clean_cmds,final-target_gmp)
install_final-target_gmp   = \
	$(call gmp_install_cmds,\
	       final-target_gmp,\
	       install LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool',\
	       $(final_sysroot))
uninstall_final-target_gmp = \
	$(call gmp_uninstall_cmds,\
	       final-target_gmp,\
	       $(TARGET_PREFIX),\
	       uninstall LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool',\
	       $(final_sysroot))
check_final-target_gmp     = $(call gmp_check_cmds,final-target_gmp)

$(call gen_config_rules_with_dep,final-target_gmp,gmp,config_final-target_gmp)
$(call gen_clobber_rules,final-target_gmp)
$(call gen_build_rules,final-target_gmp,build_final-target_gmp)
$(call gen_clean_rules,final-target_gmp,clean_final-target_gmp)
$(call gen_install_rules,final-target_gmp,install_final-target_gmp)
$(call gen_uninstall_rules,final-target_gmp,uninstall_final-target_gmp)
$(call gen_check_rules,final-target_gmp,check_final-target_gmp)
$(call gen_dir_rules,final-target_gmp)
