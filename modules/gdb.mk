################################################################################
# gdb modules
#
# Requires the following bookworm packages to build:
# libncurses-dev
# librealine-dev
# libpython3-dev
# libsource-highlight-dev
# libbabeltrace-dev
# libxxhash-dev
# zlib1g-dev
# liblzma-dev
# libzstd-dev
# libexpat1-dev
################################################################################

gdb_dist_url  := https://ftp.gnu.org/gnu/gdb/gdb-16.3.tar.xz
gdb_dist_sum  := fffd6689c3405466a179670b04720dc825e4f210a761f63dd2b33027432f8cd5d1c059c431a5ec9e165eedd1901220b5329d73c522f9a444788888c731b29e9c
gdb_dist_name := $(notdir $(gdb_dist_url))
gdb_vers      := $(patsubst gdb-%.tar.xz,%,$(gdb_dist_name))
gdb_brief     := GNU compiler collection
gdb_home      := https://gdb.gnu.org/

define gdb_desc
GDB, the GNU Project debugger, allows you to see what is going on `inside'
another program while it executes -- or what another program was doing at the
moment it crashed.
endef

define fetch_gdb_dist
$(call download_csum,$(gdb_dist_url),$(gdb_dist_name),$(gdb_dist_sum))
endef
$(call gen_fetch_rules,gdb,gdb_dist_name,fetch_gdb_dist)

define xtract_gdb
$(call rmrf,$(srcdir)/gdb)
$(call untar,$(srcdir)/gdb,\
             $(FETCHDIR)/$(gdb_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,gdb,xtract_gdb)

$(call gen_dir_rules,gdb)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define gdb_config_cmds
cd $(builddir)/$(strip $(1)) && \
$(srcdir)/gdb/configure --prefix='$(strip $(2))' \
                        $(3) \
                        $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and arguments
define gdb_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
# $(2): make target and arguments
define gdb_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) $(2) $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
# $(4): make target and arguments
define gdb_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         $(4) \
         $(if $(strip $(3)),DESTDIR='$(strip $(3))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): optional install destination directory
# $(4): make target and arguments
define gdb_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          $(4) \
          $(if $(3),DESTDIR='$(strip $(3))') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(3))$(strip $(2)))
endef

# $(1): targets base name / module name
# $(2): make target and arguments
define gdb_check_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) check $(2)
endef

gdb_common_args := \
	--build='$(BUILD_UPLET)' \
	--with-pkgversion='$(pkgvers)' \
	--with-bugurl='$(pkgurl)' \
	--with-gcc-major-version-only \
	--disable-gprofng \
	--enable-year2038 \
	--enable-libssp \
	--enable-libstdcxx \
	--disable-bootstrap \
	--enable-lto \
	--enable-host-pie \
	--enable-host-shared \
	--enable-vtable-verify \
	--with-system-zlib \
	--with-xxhash \
	--with-zstd \
	--enable-plugins \
	\
	--enable-shared \
	--enable-static \
	--enable-threading \
	--enable-nls \
	--enable-tui \
	--disable-gdbtk \
	--enable-source-highlight \
	--disable-ubsan \
	--enable-libctf \
	--with-gnu-ld \
	--with-debuginfod \
	--with-curses \
	--with-system-readline \
	--with-expat \
	--with-python \
	--without-guile \
	--with-lzma \
	--without-tcl \
	--without-tk \
	--with-x \
	--with-babeltrace

################################################################################
# Final gdb definitions
#
# TODO:
# refine top-level config args:
# --with-stage1-ldflags=FLAGS linker flags for stage1
# --with-boot-ldflags=FLAGS linker flags for stage2 and later
# --with-build-sysroot=SYSROOT use sysroot as the system root during the build
# --with-build-config='NAME NAME2...' use config/NAME.mk build configuration
# --with-build-time-tools=PATH use given path to find target tools during the build
# refine gdb sub-directory config args:
# --enable-targets=TARGETS alternative target configurations
# --with-separate-debug-dir=PATH look for global separate debug info in this path [LIBDIR/debug]
# --with-additional-debug-dirs=PATHs colon-separated list of additional directories to search for separate debug info
# --with-gdb-datadir=PATH look for global separate data files in this path [DATADIR/gdb]
# --with-relocated-sources=PATH automatically relocate this path for source files
# --with-auto-load-dir=PATH directories from which to load auto-loaded scripts [$debugdir:$datadir/auto-load]
# --with-auto-load-safe-path=PATH directories safe to hold auto-loaded files [--with-auto-load-dir]
# --without-auto-load-safe-path do not restrict auto-loaded files locations
#
# See https://sourceware.org/gdb/current/onlinedocs/gdb.html/Configure-Options.html
# See https://sourceware.org/gdb/wiki/BuildingCrossGDBandGDBserver
################################################################################

gdb_final_host_args := \
	$(gdb_common_args) \
	--host='$(BUILD_UPLET)' \
	--with-sysroot='$(stagedir)' \
	--with-gmp='$(bstrapdir)' \
	--with-mpfr='$(bstrapdir)' \
	--with-mpc='$(bstrapdir)' \
	--with-isl='$(bstrapdir)' \
	--with-system-gdbinit='$(PREFIX)/etc/gdb/gdbinit' \
	--with-system-gdbinit-dir='$(PREFIX)/etc/gdb/gdbinit.d' \
	$(config_build_tools) \
	CPPFLAGS='$(BUILD_CPPFLAGS)' \
	CFLAGS='$(BUILD_CFLAGS)' \
	CXXFLAGS='$(BUILD_CXXFLAGS)' \
	LDFLAGS='$(BUILD_LDFLAGS)' \
	$(call pkg_config_path,$(stagedir)) \
	PATH='$(stagedir)/bin:$(PATH)' \
	$(GDB_FINAL_TARGET_ARGS)

$(call gen_deps,final-host_gdb,stage-host_gcc stage-host_elfutils)

config_final-host_gdb    = $(call gdb_config_cmds,final-host_gdb, \
                                                  $(PREFIX), \
                                                  $(gdb_final_host_args))
build_final-host_gdb     = \
	$(call gdb_build_cmds,\
	       final-host_gdb,\
	       all-gdb \
	       lt_cv_sys_lib_dlsearch_path_spec='$(bstrapdir)/lib')
clean_final-host_gdb     = $(call gdb_clean_cmds,final-host_gdb,clean-gdb)
install_final-host_gdb   = $(call gdb_install_cmds,final-host_gdb,\
                                                   $(PREFIX),\
                                                   $(finaldir),\
                                                   install-gdb)
uninstall_final-host_gdb = $(call gdb_uninstall_cmds,final-host_gdb,\
                                                     $(PREFIX),\
                                                     $(finaldir),\
                                                     uninstall)
check_final-host_gdb     = $(call gdb_check_cmds,final-host_gdb,check-gdb)

$(call gen_config_rules_with_dep,final-host_gdb,gdb,config_final-host_gdb)
$(call gen_clobber_rules,final-host_gdb)
$(call gen_build_rules,final-host_gdb,build_final-host_gdb)
$(call gen_clean_rules,final-host_gdb,clean_final-host_gdb)
$(call gen_install_rules,final-host_gdb,install_final-host_gdb)
$(call gen_uninstall_rules,final-host_gdb,uninstall_final-host_gdb)
$(call gen_check_rules,final-host_gdb,check_final-host_gdb)
$(call gen_dir_rules,final-host_gdb)

################################################################################
# Final gdbserver definitions
#
# TODO:
# refine top-level config args:
# --with-stage1-ldflags=FLAGS linker flags for stage1
# --with-boot-ldflags=FLAGS linker flags for stage2 and later
# --with-build-sysroot=SYSROOT use sysroot as the system root during the build
# --with-build-config='NAME NAME2...' use config/NAME.mk build configuration
# --with-build-time-tools=PATH use given path to find target tools during the build
# refine gdb sub-directory config args:
# --enable-targets=TARGETS alternative target configurations
# --with-separate-debug-dir=PATH look for global separate debug info in this path [LIBDIR/debug]
# --with-additional-debug-dirs=PATHs colon-separated list of additional directories to search for separate debug info
# --with-gdb-datadir=PATH look for global separate data files in this path [DATADIR/gdb]
# --with-relocated-sources=PATH automatically relocate this path for source files
# --with-auto-load-dir=PATH directories from which to load auto-loaded scripts [$debugdir:$datadir/auto-load]
# --with-auto-load-safe-path=PATH directories safe to hold auto-loaded files [--with-auto-load-dir]
# --without-auto-load-safe-path do not restrict auto-loaded files locations
#
# See https://sourceware.org/gdb/current/onlinedocs/gdb.html/Configure-Options.html
# See https://sourceware.org/gdb/wiki/BuildingCrossGDBandGDBserver
################################################################################

gdbserver_final_target_args := \
	$(gdb_common_args) \
	--host='$(TARGET_UPLET)' \
	--with-sysroot='$(final_sysroot)' \
	--with-gmp='$(final_sysroot)' \
	--with-mpfr='$(final_sysroot)' \
	--with-system-gdbinit='$(TARGET_PREFIX)/etc/gdb/gdbinit' \
	--with-system-gdbinit-dir='$(TARGET_PREFIX)/etc/gdb/gdbinit.d' \
	$(call config_target_tools,$(stagedir)) \
	$(call pkg_config_path,$(final_sysroot)) \
	CPPFLAGS='$(TARGET_CPPFLAGS) --sysroot=$(final_sysroot)' \
	CFLAGS='$(TARGET_CFLAGS) --sysroot=$(final_sysroot)' \
	CXXFLAGS='$(TARGET_CXXFLAGS) --sysroot=$(final_sysroot)' \
	LDFLAGS='$(TARGET_LDFLAGS) --sysroot=$(final_sysroot)' \
	$(GDBSERVER_FINAL_TARGET_ARGS)

$(call gen_deps,final-target_gdbserver,final-target_mpfr \
                                       final-target_zlib \
                                       final-target_libxxhash \
                                       final-target_isl)

config_final-target_gdbserver    = $(call gdb_config_cmds,\
                                          final-target_gdbserver, \
                                          $(TARGET_PREFIX), \
                                          $(gdbserver_final_target_args))
build_final-target_gdbserver     = $(call gdb_build_cmds,\
                                          final-target_gdbserver,\
                                          all-gdbserver)
clean_final-target_gdbserver     = $(call gdb_clean_cmds,\
                                          final-target_gdbserver,\
                                          clean-gdbserver)
install_final-target_gdbserver   = $(call gdb_install_cmds,\
                                          final-target_gdbserver,\
                                          $(TARGET_PREFIX),\
                                          $(final_sysroot),\
                                          install-gdbserver)
uninstall_final-target_gdbserver = $(call gdb_uninstall_cmds,\
                                          final-target_gdbserver,\
                                          $(TARGET_PREFIX),\
                                          $(final_sysroot),\
                                          uninstall)
check_final-target_gdbserver     = $(call gdbserver_check_cmds,\
                                          final-target_gdbserver,\
                                          check-gdbserver)

$(call gen_config_rules_with_dep,final-target_gdbserver,\
                                 gdb,\
                                 config_final-target_gdbserver)
$(call gen_clobber_rules,final-target_gdbserver)
$(call gen_build_rules,final-target_gdbserver,build_final-target_gdbserver)
$(call gen_clean_rules,final-target_gdbserver,clean_final-target_gdbserver)
$(call gen_install_rules,final-target_gdbserver,install_final-target_gdbserver)
$(call gen_uninstall_rules,final-target_gdbserver,\
                           uninstall_final-target_gdbserver)
$(call gen_check_rules,final-target_gdbserver,check_final-target_gdbserver)
$(call gen_dir_rules,final-target_gdbserver)
