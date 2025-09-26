################################################################################
# ldconfig modules
################################################################################

ldconfig_dist_url  := https://git.openembedded.org/openembedded-core/plain/meta/recipes-core/glibc/ldconfig-native-2.12.1/ldconfig-native-2.12.1.tar.bz2
ldconfig_dist_sum  := 5c53e9c6fd1736a9396e9de7fd4c151359fdbd41a588d8f4868ea99803c00889f8bff27a64ae13faa26ef7ce1239412c0c1b718ac1415d3c3fb47223d2989c84
ldconfig_dist_name := $(notdir $(ldconfig_dist_url))
ldconfig_vers      := $(patsubst ldconfig-%.tar.bz2,%,$(ldconfig_dist_name))
ldconfig_brief     := ldconfig, the dynamic linker run-time configuration tool
ldconfig_home      := https://layers.openembedded.org/layerindex/recipe/592/

define ldconfig_desc
ldconfig, a Glibc tool that creates the necessary links and cache to the most
recent shared libraries found in the directories specified on the command line,
in the file /etc/ld.so.conf, and in the trusted directories.
This module is composed of ldconfig sources extracted from glibc 2.5 and then
patched to allow standalone compilation.
endef

define fetch_ldconfig_dist
$(call download_csum,$(ldconfig_dist_url),\
                     $(ldconfig_dist_name),\
                     $(ldconfig_dist_sum))
endef
$(call gen_fetch_rules,ldconfig,ldconfig_dist_name,fetch_ldconfig_dist)

define xtract_ldconfig
$(call rmrf,$(srcdir)/ldconfig)
$(call untar,$(srcdir)/ldconfig,\
             $(FETCHDIR)/$(ldconfig_dist_name),\
             --strip-components=1)
$(call patch,$(srcdir)/ldconfig,\
             $(PATCHDIR)/ldconfig-2.12.1-000-ldconfig.patch \
             $(PATCHDIR)/ldconfig-2.12.1-001-aux_cache_path_fix.patch \
             $(PATCHDIR)/ldconfig-2.12.1-002-32and64bit.patch \
             $(PATCHDIR)/ldconfig-2.12.1-003-endianness_handling.patch \
             $(PATCHDIR)/ldconfig-2.12.1-004-flag_fix.patch \
             $(PATCHDIR)/ldconfig-2.12.1-005-endianess_header.patch \
             $(PATCHDIR)/ldconfig-2.12.1-006-default_to_all_multilib_dirs.patch \
             $(PATCHDIR)/ldconfig-2.12.1-007-endianness_handling_fix.patch \
             $(PATCHDIR)/ldconfig-2.12.1-008-add_64bit_flag_for_elf64_entries.patch \
             $(PATCHDIR)/ldconfig-2.12.1-009-no_aux_cache.patch \
             $(PATCHDIR)/ldconfig-2.12.1-010-add_riscv-support.patch \
             $(PATCHDIR)/ldconfig-2.12.1-011-handle_dynstr_located_in_separate_segment.patch)
endef
$(call gen_xtract_rules,ldconfig,xtract_ldconfig)

$(call gen_dir_rules,ldconfig)

################################################################################
# Final ldconfig definitions
################################################################################

ldconfig_src_files := ldconfig.c \
                      chroot_canon.c \
                      xmalloc.c \
                      xstrdup.c \
                      cache.c \
                      readlib.c \
                      dl-cache.c
ldconfig_src_files := $(addprefix $(srcdir)/ldconfig/,$(ldconfig_src_files))

$(ldconfig_src_files): $(stampdir)/ldconfig/xtracted

$(stampdir)/final-host_ldconfig/built: $(builddir)/final-host_ldconfig/ldconfig
$(builddir)/final-host_ldconfig/ldconfig: $(ldconfig_src_files) \
                                          | $(builddir)/final-host_ldconfig
	$(BUILD_CC) $(BUILD_CPPFLAGS) -I $(srcdir)/ldconfig $(BUILD_CFLAGS) \
		-o $(@) $(^) $(BUILD_LDFLAGS)

clean_final-host_ldconfig     = $(RM) $(builddir)/final-host_ldconfig/ldconfig

$(stampdir)/final-host_ldconfig/installed: \
	$(finaldir)$(PREFIX)/sbin/$(TARGET_UPLET)-ldconfig

.PHONY: $(finaldir)$(PREFIX)/sbin/$(TARGET_UPLET)-ldconfig
$(finaldir)$(PREFIX)/sbin/$(TARGET_UPLET)-ldconfig: \
	$(stampdir)/final-host_ldconfig/built \
	| $(finaldir)$(PREFIX)/sbin
	$(INSTALL) --mode=755 $(builddir)/final-host_ldconfig/ldconfig \
	                      $(@)
$(finaldir)$(PREFIX)/sbin:
	$(call mkdir,$(@))

define uninstall_final-host_ldconfig
$(RM) $(finaldir)$(PREFIX)/sbin/$(TARGET_UPLET)-ldconfig
endef

$(call gen_config_rules_with_dep,final-host_ldconfig,ldconfig)
$(call gen_clobber_rules,final-host_ldconfig)
$(call gen_build_rules,final-host_ldconfig)
$(call gen_clean_rules,final-host_ldconfig,clean_final-host_ldconfig)
$(call gen_install_rules,final-host_ldconfig)
$(call gen_uninstall_rules,final-host_ldconfig,uninstall_final-host_ldconfig)
$(call gen_dir_rules,final-host_ldconfig)
