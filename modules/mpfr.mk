################################################################################
# mpfr modules
################################################################################

mpfr_dist_url  := https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz
mpfr_dist_sum  := 1bd1c349741a6529dfa53af4f0da8d49254b164ece8a46928cdb13a99460285622d57fe6f68cef19c6727b3f9daa25ddb3d7d65c201c8f387e421c7f7bee6273
mpfr_dist_name := $(notdir $(mpfr_dist_url))
mpfr_vers      := $(patsubst mpfr-%.tar.xz,%,$(mpfr_dist_name))
mpfr_brief     := Multiple precision floating-point computation
mpfr_home      := https://www.mpfr.org/

define mpfr_desc
MPFR provides a library for multiple-precision floating-point computation with
correct rounding. The computation is both efficient and has a well-defined
semantics. It copies the good ideas from the ANSI/IEEE-754 standard for
double-precision floating-point arithmetic (53-bit mantissa).
endef

define fetch_mpfr_dist
$(call download_csum,$(mpfr_dist_url),\
                     $(mpfr_dist_name),\
                     $(mpfr_dist_sum))
endef
$(call gen_fetch_rules,mpfr,mpfr_dist_name,fetch_mpfr_dist)

define xtract_mpfr
$(call rmrf,$(srcdir)/mpfr)
$(call untar,$(srcdir)/mpfr,\
             $(FETCHDIR)/$(mpfr_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,mpfr,xtract_mpfr)

$(call gen_dir_rules,mpfr)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define mpfr_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/mpfr/configure --prefix='$(strip $(2))' \
                         $(3) \
                         $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and variables
define mpfr_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
define mpfr_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and variables
# $(3): optional install destination directory
define mpfr_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define mpfr_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
# $(2): make arguments
define mpfr_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check $(2)
endef

mpfr_common_args := \
	--enable-silent-rules \
	--enable-static \
	--enable-shared \
	--disable-assert \
	--enable-gmp-internals \
	--enable-thread-safe \
	--with-gnu-ld

mpfr_host_common_args := \
	$(mpfr_common_args) \
	--with-gmp-build='$(builddir)/bstrap-host_gmp' \
	--enable-decimal-float=yes \
	--enable-float128 \
	$(config_build_tools)

################################################################################
# Bootstrapping definitions
################################################################################

mpfr_bstrap_host_args := \
	$(mpfr_host_common_args) \
	MISSING='/bin/true' \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS)'

$(call gen_deps,bstrap-host_mpfr,bstrap-host_gmp)

config_bstrap-host_mpfr    = $(call mpfr_config_cmds,bstrap-host_mpfr,\
                                                     $(bstrapdir),\
                                                     $(mpfr_bstrap_host_args))
build_bstrap-host_mpfr     = $(call mpfr_build_cmds,bstrap-host_mpfr,all)
clean_bstrap-host_mpfr     = $(call mpfr_clean_cmds,bstrap-host_mpfr)
install_bstrap-host_mpfr   = $(call mpfr_install_cmds,bstrap-host_mpfr,\
                                                      install-strip)
uninstall_bstrap-host_mpfr = $(call mpfr_uninstall_cmds,bstrap-host_mpfr,\
                                                        $(bstrapdir))
check_bstrap-host_mpfr     = $(call mpfr_check_cmds,bstrap-host_mpfr)

$(call gen_config_rules_with_dep,bstrap-host_mpfr,mpfr,config_bstrap-host_mpfr)
$(call gen_clobber_rules,bstrap-host_mpfr)
$(call gen_build_rules,bstrap-host_mpfr,build_bstrap-host_mpfr)
$(call gen_clean_rules,bstrap-host_mpfr,clean_bstrap-host_mpfr)
$(call gen_install_rules,bstrap-host_mpfr,install_bstrap-host_mpfr)
$(call gen_uninstall_rules,bstrap-host_mpfr,uninstall_bstrap-host_mpfr)
$(call gen_check_rules,bstrap-host_mpfr,check_bstrap-host_mpfr)
$(call gen_dir_rules,bstrap-host_mpfr)

################################################################################
# Final host definitions
################################################################################

mpfr_final_host_args := \
	$(mpfr_host_common_args) \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS) -Wl,-rpath,$(PREFIX)/lib' \
	LT_SYS_LIBRARY_PATH="$(bstrapdir)/lib"

$(call gen_deps,final-host_mpfr,bstrap-host_gmp)

config_final-host_mpfr    = $(call mpfr_config_cmds,final-host_mpfr,\
                                                    $(PREFIX),\
                                                    $(mpfr_final_host_args))
build_final-host_mpfr     = $(call mpfr_build_cmds,final-host_mpfr,all)
clean_final-host_mpfr     = $(call mpfr_clean_cmds,final-host_mpfr)
install_final-host_mpfr   = $(call mpfr_install_cmds,final-host_mpfr,\
                                                     install,\
                                                     $(finaldir))

uninstall_final-host_mpfr = $(call mpfr_uninstall_cmds,final-host_mpfr,\
                                                       $(PREFIX),\
                                                       $(finaldir))
check_final-host_mpfr     = $(call mpfr_check_cmds,final-host_mpfr)

$(call gen_config_rules_with_dep,final-host_mpfr,mpfr,config_final-host_mpfr)
$(call gen_clobber_rules,final-host_mpfr)
$(call gen_build_rules,final-host_mpfr,build_final-host_mpfr)
$(call gen_clean_rules,final-host_mpfr,clean_final-host_mpfr)
$(call gen_install_rules,final-host_mpfr,install_final-host_mpfr)
$(call gen_uninstall_rules,final-host_mpfr,uninstall_final-host_mpfr)
$(call gen_check_rules,final-host_mpfr,check_final-host_mpfr)
$(call gen_dir_rules,final-host_mpfr)

################################################################################
# Final target definitions
################################################################################

mpfr_final_target_args := \
	$(mpfr_common_args) \
	$(MPFR_FINAL_TARGET_ARGS) \
	--host='$(TARGET_UPLET)' \
	--with-sysroot='$(final_sysroot)' \
	--with-gmp-build='$(builddir)/final-target_gmp' \
	$(call config_target_tools,$(stagedir)) \
	CPPFLAGS='$(TARGET_CPPFLAGS)' \
	CFLAGS='$(TARGET_CFLAGS)' \
	CXXFLAGS='$(TARGET_CXXFLAGS)' \
	LDFLAGS='$(TARGET_LDFLAGS)'

$(call gen_deps,final-target_mpfr,final-target_gmp)

config_final-target_mpfr    = $(call mpfr_config_cmds,final-target_mpfr,\
                                                      $(TARGET_PREFIX),\
                                                      $(mpfr_final_target_args))
build_final-target_mpfr     = \
	$(call mpfr_build_cmds,\
	       final-target_gmp,\
	       all LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool')

clean_final-target_mpfr     = $(call mpfr_clean_cmds,final-target_mpfr)

install_final-target_mpfr = \
	$(call mpfr_install_cmds,\
	       final-target_mpfr,\
	       install LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool',\
	       $(final_sysroot))

uninstall_final-target_mpfr = $(call mpfr_uninstall_cmds,final-target_mpfr,\
                                                         $(TARGET_PREFIX),\
                                                         $(final_sysroot))
check_final-target_mpfr     = $(call mpfr_check_cmds,final-target_mpfr)

$(call gen_config_rules_with_dep,final-target_mpfr,mpfr,config_final-target_mpfr)
$(call gen_clobber_rules,final-target_mpfr)
$(call gen_build_rules,final-target_mpfr,build_final-target_mpfr)
$(call gen_clean_rules,final-target_mpfr,clean_final-target_mpfr)
$(call gen_install_rules,final-target_mpfr,install_final-target_mpfr)
$(call gen_uninstall_rules,final-target_mpfr,uninstall_final-target_mpfr)
$(call gen_check_rules,final-target_mpfr,check_final-target_mpfr)
$(call gen_dir_rules,final-target_mpfr)
