################################################################################
# libxxhash modules
################################################################################

libxxhash_dist_url  := https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.tar.gz
libxxhash_dist_sum  := 8b5c8b9aad4e869f28310b12cc314037feda81d92f26c23eaecdb35dc65042ca2e65f2e9606033e62a31bcc737a9a950500ffcbdb8677d6ab20e820ea14f2b79
libxxhash_dist_name := libxxhash-$(patsubst v%,%,$(notdir $(libxxhash_dist_url)))
libxxhash_vers      := $(patsubst libxxhash-%.tar.gz,%,$(libxxhash_dist_name))
libxxhash_brief     := xxHash, a fast non-cryptographic hash algorithm
libxxhash_home      := https://github.com/Cyan4973/xxHash

define libxxhash_desc
xxHash is an Extremely fast Hash algorithm, running at RAM speed limits. It
successfully completes the SMHasher test suite which evaluates collision,
dispersion and randomness qualities of hash functions. Code is highly portable,
and hashes are identical on all platforms (little / big endian).
endef

define fetch_libxxhash_dist
$(call download_csum,$(libxxhash_dist_url),\
                     $(libxxhash_dist_name),\
                     $(libxxhash_dist_sum))
endef
$(call gen_fetch_rules,libxxhash,libxxhash_dist_name,fetch_libxxhash_dist)

define xtract_libxxhash
$(call rmrf,$(srcdir)/libxxhash)
$(call untar,$(srcdir)/libxxhash,\
             $(FETCHDIR)/$(libxxhash_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,libxxhash,xtract_libxxhash)

$(call gen_dir_rules,libxxhash)

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): configure arguments
define libxxhash_config_cmds
$(RSYNC) --archive --delete $(srcdir)/libxxhash/ $(builddir)/$(strip $(1))
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): make arguments
define libxxhash_build_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         default \
         prefix='$(strip $(2))' \
         $(3) \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): make arguments
define libxxhash_clean_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         clean \
         prefix='$(strip $(2))' \
         $(3) \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): make arguments
define libxxhash_install_cmds
+$(MAKE) --directory $(builddir)/$(strip $(1)) \
         install \
         prefix='$(strip $(2))' \
         $(3) \
         $(if $(strip $(4)),DESTDIR='$(strip $(4))') \
         $(verbose)
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): make arguments
# $(4): optional install destination directory
define libxxhash_uninstall_cmds
-+$(MAKE) --keep-going \
          --directory $(builddir)/$(strip $(1)) \
          uninstall \
          prefix='$(strip $(2))' \
          $(3) \
          $(if $(strip $(4)),DESTDIR='$(strip $(4))') \
          $(verbose)
$(call cleanup_empty_dirs,$(strip $(4))$(strip $(2)))
endef

# $(1): targets base name / module name
# $(2): build / install prefix
# $(3): make arguments
define libxxhash_check_cmds
+env LD_LIBRARY_PATH='$(builddir)/$(strip $(1))/lib' \
$(MAKE) --directory $(builddir)/$(strip $(1)) \
        check \
        prefix='$(strip $(2))' \
        $(3)
endef

################################################################################
# Final definitions
################################################################################

libxxhash_final_target_make_args := \
	$(LIBXXHASH_FINAL_TARGET_ARGS) \
	SONAME_FLAGS='-shared -Wl,-soname=libxxhash.$$(SHARED_EXT).$$(LIBVER_MAJOR)' \
	UNAME='Linux' \
	$(call config_target_tools,$(stagedir)) \
	CPPFLAGS='$(TARGET_CPPFLAGS) --sysroot=$(final_sysroot)' \
	CFLAGS='$(call xclude_flags,$(o_flags),$(TARGET_CFLAGS)) -O3 \
	        $$(DEBUGFLAGS) $$(MOREFLAGS)' \
	CXXFLAGS='$(call xclude_flags,$(o_flags),$(TARGET_CXXFLAGS)) -O3 \
	          $$(DEBUGFLAGS) $$(MOREFLAGS)' \
	LDFLAGS='$(call xclude_flags,$(o_flags),$(TARGET_LDFLAGS)) -O3 \
	         --sysroot=$(final_sysroot)' \
	$(call pkg_config_path,$(final_sysroot))

$(call gen_deps,final-target_libxxhash,final-host_gcc)

config_final-target_libxxhash    = $(call libxxhash_config_cmds,\
                                          final-target_libxxhash)
build_final-target_libxxhash     = $(call libxxhash_build_cmds,\
                                          final-target_libxxhash,\
                                          $(TARGET_PREFIX),\
                                          $(libxxhash_final_target_make_args))
clean_final-target_libxxhash     = $(call libxxhash_clean_cmds,\
                                          final-target_libxxhash,\
                                          $(TARGET_PREFIX),\
                                          $(libxxhash_final_target_make_args))
install_final-target_libxxhash   = $(call libxxhash_install_cmds,\
                                          final-target_libxxhash,\
                                          $(TARGET_PREFIX),\
                                          $(libxxhash_final_target_make_args),\
                                          $(final_sysroot))
uninstall_final-target_libxxhash = $(call libxxhash_uninstall_cmds,\
                                          final-target_libxxhash,\
                                          $(TARGET_PREFIX),\
                                          $(libxxhash_final_target_make_args),\
                                          $(final_sysroot))
check_final-target_libxxhash     = $(call libxxhash_check_cmds,\
                                          final-target_libxxhash,\
                                          $(TARGET_PREFIX),\
                                          $(libxxhash_final_target_make_args))

$(call gen_config_rules_with_dep,final-target_libxxhash,\
                                 libxxhash,\
                                 config_final-target_libxxhash)
$(call gen_clobber_rules,final-target_libxxhash)
$(call gen_build_rules,final-target_libxxhash,build_final-target_libxxhash)
$(call gen_clean_rules,final-target_libxxhash,clean_final-target_libxxhash)
$(call gen_install_rules,final-target_libxxhash,install_final-target_libxxhash)
$(call gen_uninstall_rules,final-target_libxxhash,\
                           uninstall_final-target_libxxhash)
$(call gen_check_rules,final-target_libxxhash,check_final-target_libxxhash)
$(call gen_dir_rules,final-target_libxxhash)
