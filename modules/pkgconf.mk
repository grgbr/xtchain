################################################################################
# pkgconf modules
#
# Requires the following bookworm packages to build:
# kyua
# atf-sh
################################################################################

pkgconf_dist_url  := https://github.com/pkgconf/pkgconf/archive/refs/tags/pkgconf-2.5.1.tar.gz
pkgconf_dist_sum  := 53244f372ea21125a1d97c5b89a84299740b55a66165782e807ed23adab3a07408a1547f1f40156e3060359660d07f49846c8b4893beef10ac9440ab7e8611cc
pkgconf_dist_name := $(notdir $(pkgconf_dist_url))
pkgconf_vers      := $(patsubst pkgconf-%.tar.gz,%,$(pkgconf_dist_name))
pkgconf_brief     := Pkgconf, a compiler and linker metadata toolkit
pkgconf_home      := https://github.com/pkgconf/pkgconf

define pkgconf_desc
pkgconf is a program which helps to configure compiler and linker flags for
development libraries. It is a superset of the functionality provided by
pkg-config from freedesktop.org, but does not provide bug-compatibility with the
original pkg-config.
endef

define fetch_pkgconf_dist
$(call download_csum,$(pkgconf_dist_url),\
                     $(pkgconf_dist_name),\
                     $(pkgconf_dist_sum))
endef
$(call gen_fetch_rules,pkgconf,pkgconf_dist_name,fetch_pkgconf_dist)

define xtract_pkgconf
$(call rmrf,$(srcdir)/pkgconf)
$(call untar,$(srcdir)/pkgconf,\
             $(FETCHDIR)/$(pkgconf_dist_name),\
             --strip-components=1)
if [ ! -x "$(srcdir)/pkgconf/configure" ]; then \
	cd $(srcdir)/pkgconf; \
	./autogen.sh; \
fi
endef
$(call gen_xtract_rules,pkgconf,xtract_pkgconf)

$(call gen_dir_rules,pkgconf)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define pkgconf_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/pkgconf/configure --prefix='$(strip $(2))' $(3) $(verbose)
endef

# $(1): targets base name / module name
define pkgconf_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) all $(verbose)
endef

# $(1): targets base name / module name
define pkgconf_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): prefix
# $(3): optional install destination directory
define pkgconf_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         install \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(verbose)
$(LN) -sf $(TARGET_UPLET)-pkgconf \
          $(strip $(3))$(strip $(2))/bin/$(TARGET_UPLET)-pkg-config
$(LN) -sf $(TARGET_UPLET)-pkgconf.1 \
          $(strip $(3))$(strip $(2))/share/man/man1/$(TARGET_UPLET)-pkg-config.1
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
define pkgconf_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          $(if $(3),DESTDIR='$(3)') \
          $(verbose)
$(RM) $(strip $(3))$(strip $(2))/bin/$(TARGET_UPLET)-pkg-config
$(RM) $(strip $(3))$(strip $(2))/share/man/man1/$(TARGET_UPLET)-pkg-config.1
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
# $(2): optional make arguments
#
# pkgconf tests are based upon the kyua(1) testing framework. Do set HOME and
# TMPDIR environment variable to make sure that all test artefacts are located
# under the build directory. See kyua(1) man page for more infos...
define pkgconf_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         check \
         HOME='$(builddir)/$(strip $(1))' \
         TMPDIR='$(builddir)/$(strip $(1))' \
         $(2)
endef

################################################################################
# Final host pkgconf definitions
################################################################################

pkgconf_final_host_args := \
	--program-prefix='$(TARGET_UPLET)-' \
	--enable-silent-rules \
	--enable-shared \
	--enable-static \
	--with-gnu-ld \
	--with-pkg-config-dir='$(PREFIX)$(target_sysroot)/lib/pkgconfig:$(PREFIX)$(target_sysroot)/share/pkgconfig' \
	--with-system-includedir='$(TARGET_PREFIX)/include' \
	--with-system-libdir='$(TARGET_PREFIX)/lib' \
	CPP='$(BUILD_CPP)' \
	AS='$(BUILD_AS)' \
	CC='$(BUILD_CC)' \
	CXX='$(BUILD_CXX)' \
	AR='$(BUILD_AR)' \
	NM='$(BUILD_NM)' \
	RANLIB='$(BUILD_RANLIB)' \
	OBJCOPY='$(BUILD_OBJCOPY)' \
	OBJDUMP='$(BUILD_OBJDUMP)' \
	READELF='$(BUILD_READELF)' \
	STRIP='$(BUILD_STRIP)' \
	M4='$(BUILD_M4)' \
	PYTHON='$(BUILD_PYTHON)' \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS) -Wl,-rpath,$(PREFIX)/lib'

config_final-host_pkgconf    = $(call pkgconf_config_cmds,\
                                   final-host_pkgconf,\
                                   $(PREFIX),\
                                   $(pkgconf_final_host_args))
build_final-host_pkgconf     = $(call pkgconf_build_cmds,\
                                        final-host_pkgconf)
clean_final-host_pkgconf     = $(call pkgconf_clean_cmds,\
                                        final-host_pkgconf)
install_final-host_pkgconf   = $(call pkgconf_install_cmds,\
                                        final-host_pkgconf,\
                                        $(PREFIX),\
                                        $(finaldir))
uninstall_final-host_pkgconf = $(call pkgconf_uninstall_cmds,\
                                        final-host_pkgconf,\
                                        $(PREFIX),\
                                        $(finaldir))
check_final-host_pkgconf     = $(call pkgconf_check_cmds,\
                                        final-host_pkgconf)

$(call gen_config_rules_with_dep,final-host_pkgconf,\
                                 pkgconf,\
                                 config_final-host_pkgconf)
$(call gen_clobber_rules,final-host_pkgconf)
$(call gen_build_rules,final-host_pkgconf,build_final-host_pkgconf)
$(call gen_clean_rules,final-host_pkgconf,clean_final-host_pkgconf)
$(call gen_install_rules,final-host_pkgconf,install_final-host_pkgconf)
$(call gen_uninstall_rules,final-host_pkgconf,uninstall_final-host_pkgconf)
$(call gen_check_rules,final-host_pkgconf,check_final-host_pkgconf)
$(call gen_dir_rules,final-host_pkgconf)
