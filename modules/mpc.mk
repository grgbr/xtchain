################################################################################
# mpc modules
################################################################################

mpc_dist_url  := https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
mpc_dist_sum  := 3279f813ab37f47fdcc800e4ac5f306417d07f539593ca715876e43e04896e1d5bceccfb288ef2908a3f24b760747d0dbd0392a24b9b341bc3e12082e5c836ee
mpc_dist_name := $(notdir $(mpc_dist_url))
mpc_vers      := $(patsubst mpc-%.tar.gz,%,$(mpc_dist_name))
mpc_brief     := Multiple precision complex floating-point library
mpc_home      := https://www.multiprecision.org/mpc/

define mpc_desc
MPC is a portable library written in C for arbitrary precision arithmetic on
complex numbers providing correct rounding. For the time being, it contains all
arithmetic operations over complex numbers, the exponential and the logarithm
functions, the trigonometric and hyperbolic functions.

Ultimately, it should implement a multiprecision equivalent of the ISO C99
standard.
endef

define fetch_mpc_dist
$(call download_csum,$(mpc_dist_url),\
                     $(mpc_dist_name),\
                     $(mpc_dist_sum))
endef
$(call gen_fetch_rules,mpc,mpc_dist_name,fetch_mpc_dist)

define xtract_mpc
$(call rmrf,$(srcdir)/mpc)
$(call untar,$(srcdir)/mpc,\
             $(FETCHDIR)/$(mpc_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,mpc,xtract_mpc)

$(call gen_dir_rules,mpc)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define mpc_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/mpc/configure --prefix='$(strip $(2))' \
                        $(3) \
                        $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and arguments
define mpc_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(verbose)
endef

# $(1): targets base name / module name
define mpc_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and variables
# $(3): optional install destination directory
define mpc_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(2) \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define mpc_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
define mpc_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check $(2)
endef

mpc_common_args := \
	--enable-silent-rules \
	--enable-static \
	--enable-shared \
	--with-gnu-ld \

mpc_host_common_args := \
	$(mpc_common_args) \
	--with-gmp='$(bstrapdir)' \
	--with-mpfr='$(bstrapdir)' \
	$(config_build_tools)

################################################################################
# Bootstrapping definitions
################################################################################

mpc_bstrap_host_args := \
	$(mpc_host_common_args) \
	MISSING='/bin/true' \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS)'

$(call gen_deps,bstrap-host_mpc,bstrap-host_mpfr)

config_bstrap-host_mpc    = $(call mpc_config_cmds,bstrap-host_mpc,\
                                                   $(bstrapdir),\
                                                   $(mpc_bstrap_host_args))
build_bstrap-host_mpc     = $(call mpc_build_cmds,bstrap-host_mpc,all)
clean_bstrap-host_mpc     = $(call mpc_clean_cmds,bstrap-host_mpc)
install_bstrap-host_mpc   = $(call mpc_install_cmds,bstrap-host_mpc,\
                                                    install-strip)
uninstall_bstrap-host_mpc = $(call mpc_uninstall_cmds,bstrap-host_mpc,\
                                                      $(bstrapdir))
check_bstrap-host_mpc     = $(call mpc_check_cmds,bstrap-host_mpc)

$(call gen_config_rules_with_dep,bstrap-host_mpc,mpc,config_bstrap-host_mpc)
$(call gen_clobber_rules,bstrap-host_mpc)
$(call gen_build_rules,bstrap-host_mpc,build_bstrap-host_mpc)
$(call gen_clean_rules,bstrap-host_mpc,clean_bstrap-host_mpc)
$(call gen_install_rules,bstrap-host_mpc,install_bstrap-host_mpc)
$(call gen_uninstall_rules,bstrap-host_mpc,uninstall_bstrap-host_mpc)
$(call gen_check_rules,bstrap-host_mpc,check_bstrap-host_mpc)
$(call gen_dir_rules,bstrap-host_mpc)

################################################################################
# Final host definitions
################################################################################

mpc_final_host_args := \
	$(mpc_host_common_args) \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS) -Wl,-rpath,$(PREFIX)/lib' \
	LT_SYS_LIBRARY_PATH='$(bstrapdir)/lib'

$(call gen_deps,final-host_mpc,bstrap-host_mpfr)

config_final-host_mpc    = $(call mpc_config_cmds,final-host_mpc,\
                                                  $(PREFIX),\
                                                  $(mpc_final_host_args))
build_final-host_mpc     = $(call mpc_build_cmds,final-host_mpc,all)
clean_final-host_mpc     = $(call mpc_clean_cmds,final-host_mpc)

define install_final-host_mpc
$(call mpc_install_cmds,final-host_mpc,install,$(finaldir))
$(SED) -i 's;$(bstrapdir);$(PREFIX);g' $(finaldir)$(PREFIX)/lib/libmpc.la
endef

uninstall_final-host_mpc = $(call mpc_uninstall_cmds,final-host_mpc,\
                                                     $(PREFIX),\
                                                     $(finaldir))
check_final-host_mpc     = $(call mpc_check_cmds,final-host_mpc)

$(call gen_config_rules_with_dep,final-host_mpc,mpc,config_final-host_mpc)
$(call gen_clobber_rules,final-host_mpc)
$(call gen_build_rules,final-host_mpc,build_final-host_mpc)
$(call gen_clean_rules,final-host_mpc,clean_final-host_mpc)
$(call gen_install_rules,final-host_mpc,install_final-host_mpc)
$(call gen_uninstall_rules,final-host_mpc,uninstall_final-host_mpc)
$(call gen_check_rules,final-host_mpc,check_final-host_mpc)
$(call gen_dir_rules,final-host_mpc)

################################################################################
# Final target definitions
################################################################################

mpc_final_target_args := \
	$(mpc_common_args) \
	$(MPC_FINAL_TARGET_ARGS) \
	--host='$(TARGET_UPLET)' \
	--with-sysroot='$(final_sysroot)' \
	$(call config_target_tools,$(stagedir)) \
	CPPFLAGS='$(TARGET_CPPFLAGS) --sysroot=$(final_sysroot)' \
	CFLAGS='$(TARGET_CFLAGS)' \
	CXXFLAGS='$(TARGET_CXXFLAGS)' \
	LDFLAGS='$(TARGET_LDFLAGS) --sysroot=$(final_sysroot)'

$(call gen_deps,final-target_mpc,final-target_mpfr)

config_final-target_mpc    = $(call mpc_config_cmds,final-target_mpc,\
                                                    $(TARGET_PREFIX),\
                                                    $(mpc_final_target_args))
build_final-target_mpc     = \
	$(call mpc_build_cmds,\
	       final-target_mpc,\
	       all LIBTOOL='$(stagedir)/bin/$(TARGET_UPLET)-libtool')
clean_final-target_mpc     = $(call mpc_clean_cmds,final-target_mpc)
install_final-target_mpc   = $(call mpc_install_cmds,final-target_mpc,\
                                                     install,\
                                                     $(final_sysroot))

uninstall_final-target_mpc = $(call mpc_uninstall_cmds,final-target_mpc,\
                                                       $(TARGET_PREFIX),\
                                                       $(final_sysroot))
check_final-target_mpc     = $(call mpc_check_cmds,final-target_mpc)

$(call gen_config_rules_with_dep,final-target_mpc,mpc,config_final-target_mpc)
$(call gen_clobber_rules,final-target_mpc)
$(call gen_build_rules,final-target_mpc,build_final-target_mpc)
$(call gen_clean_rules,final-target_mpc,clean_final-target_mpc)
$(call gen_install_rules,final-target_mpc,install_final-target_mpc)
$(call gen_uninstall_rules,final-target_mpc,uninstall_final-target_mpc)
$(call gen_check_rules,final-target_mpc,check_final-target_mpc)
$(call gen_dir_rules,final-target_mpc)
