################################################################################
# Linux modules
################################################################################

linux_dist_url  := https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.43.tar.xz
# Kernel.org web of trust requires to adapt gpg_setup.sh / gpg_verify.sh...
# For more infos, see https://www.kernel.org/signature.html
$(warning Adapt gpg_setup.sh to Linux signature logic (--locate-keys) !!)
linux_dist_sum  := 39c8282ff2ad87cef9f2a7805fad1f628aa12413b71008cff6d10261273387491ff38cac35d42ae542a5db8cb41c6545426b31c03f9df203b58b120be299086f
linux_dist_name := $(notdir $(linux_dist_url))
linux_vers      := $(patsubst linux-%.tar.xz,%,$(linux_dist_name))
linux_brief     := Linux kernel
linux_home      := https://www.kernel.org/

define linux_desc
The Linux kernel is a free and open source Unix-like kernel that is used in many
computer systems worldwide. The kernel is adopted as the kernel for the GNU
Linux operating system (OS).
endef

define linux-head_code
$(shell $(BUILD_CC) -dM -E $(bstrap_sysroot)/include/linux/version.h | \
        sed --silent \
        's/^#define[[:blank:]]\+LINUX_VERSION_CODE[[:blank:]]\+//p')
endef

linux-head_maj  = $(shell echo $$(($(linux-head_code) >> 16)))
linux-head_min  = $(shell echo $$((($(linux-head_code) >> 8) & 0xff)))
linux-head_vers = $(linux-head_maj).$(linux-head_min)

define fetch_linux_dist
$(call download_csum,$(linux_dist_url),$(linux_dist_name),$(linux_dist_sum))
endef
$(call gen_fetch_rules,linux,linux_dist_name,fetch_linux_dist)

define xtract_linux
$(call rmrf,$(srcdir)/linux)
$(call untar,$(srcdir)/linux,\
             $(FETCHDIR)/$(linux_dist_name),\
             --strip-components=1)
endef
$(call gen_xtract_rules,linux,xtract_linux)

$(call gen_dir_rules,linux)

################################################################################
# Bootstrap Linux headers for the target platform
################################################################################

# Expand to a command suitable for installing Linux header files.
#
# $(1): pathname to output build directory
# $(2): pathname to directory under which to install Linux headers
# $(3): make target and additional make flags
linux-head_cmd = $(MAKE) --directory '$(srcdir)/linux' \
                         ARCH='$(TARGET_LINUX_ARCH)' \
                         INSTALL_HDR_PATH='$(strip $(2))' \
                         O='$(strip $(1))' \
                         V=1 \
                         $(3) \
                         HOSTCC='$(BUILD_CC)' \
                         HOSTCXX='$(BUILD_CXX)' \
                         HOSTLD='$(BUILD_LD)' \
                         HOSTAR='$(BUILD_AR)' \
                         HOSTPKG_CONFIG='$(BUILD_PKG_CONFIG)' \
                         HOSTCFLAGS='$(BUILD_CFLAGS)' \
                         HOSTCXXFLAGS='$(BUILD_CXXFLAGS)' \
                         HOSTLDFLAGS='$(BUILD_LDFLAGS)' \
                         $(verbose)

define build_bstrap-target_linux
+$(call linux-head_cmd,$(builddir)/bstrap-target_linux,\
                       $(builddir)/bstrap-target_linux/sysroot,\
                       headers_install \
                       PATH='$(bstrapdir)/bin:$(PATH)')
endef

define clean_bstrap-target_linux
$(RM) -r $(builddir)/bstrap-target_linux/sysroot
+$(call linux-head_cmd,$(builddir)/bstrap-target_linux,\
                       $(builddir)/bstrap-target_linux/sysroot,\
                       mrproper \
                       PATH='$(bstrapdir)/bin:$(PATH)')
endef

define install_bstrap-target_linux
$(call mkdir,$(bstrap_sysroot)/include)
$(RSYNC) -a $(builddir)/bstrap-target_linux/sysroot/include/ \
            $(bstrap_sysroot)/include
endef

define uninstall_bstrap-target_linux
$(call uninstall_from_refdir,$(builddir)/bstrap-target_linux/sysroot/include,\
                             $(bstrap_sysroot)/include)
endef

$(call gen_config_rules_with_dep,bstrap-target_linux,linux)
$(call gen_clobber_rules,bstrap-target_linux)
$(call gen_build_rules,bstrap-target_linux,build_bstrap-target_linux)
$(call gen_clean_rules,bstrap-target_linux,clean_bstrap-target_linux)
$(call gen_install_rules,bstrap-target_linux,install_bstrap-target_linux)
$(call gen_uninstall_rules,bstrap-target_linux,uninstall_bstrap-target_linux)
$(call gen_dir_rules,bstrap-target_linux)

################################################################################
# Install Linux headers for the target platform to staging area
################################################################################

define build_stage-target_linux
+$(call linux-head_cmd,$(builddir)/stage-target_linux,\
                       $(builddir)/stage-target_linux/sysroot,\
                       headers_install \
                       CROSS_COMPILE='$(TARGET_UPLET)-' \
                       PATH='$(bstrapdir)/bin:$(PATH)')
endef

define clean_stage-target_linux
$(RM) -r $(builddir)/stage-target_linux/sysroot
+$(call linux-head_cmd,$(builddir)/stage-target_linux,\
                       $(builddir)/stage-target_linux/sysroot,\
                       mrproper \
                       CROSS_COMPILE='$(TARGET_UPLET)-' \
                       PATH='$(bstrapdir)/bin:$(PATH)')
endef

define install_stage-target_linux
$(call mkdir,$(stage_sysroot)/include)
$(RSYNC) -a $(builddir)/stage-target_linux/sysroot/include/ \
            $(stage_sysroot)/include
endef

define uninstall_stage-target_linux
$(call uninstall_from_refdir,$(builddir)/stage-target_linux/sysroot/include,\
                             $(stage_sysroot)/include)
endef

$(call gen_deps,stage-target_linux,bstrap-host_gcc)

$(call gen_config_rules_with_dep,stage-target_linux,linux)
$(call gen_clobber_rules,stage-target_linux)
$(call gen_build_rules,stage-target_linux,build_stage-target_linux)
$(call gen_clean_rules,stage-target_linux,clean_stage-target_linux)
$(call gen_install_rules,stage-target_linux,install_stage-target_linux)
$(call gen_uninstall_rules,stage-target_linux,uninstall_stage-target_linux)
$(call gen_dir_rules,stage-target_linux)

################################################################################
# Install Linux headers for the target platform to final area
################################################################################

define build_final-target_linux
+$(call linux-head_cmd,$(builddir)/final-target_linux,\
                       $(builddir)/final-target_linux/sysroot,\
                       headers_install \
                       CROSS_COMPILE='$(TARGET_UPLET)-' \
                       PATH='$(stagedir)/bin:$(PATH)')
endef

define clean_final-target_linux
$(RM) -r $(builddir)/final-target_linux/sysroot
+$(call linux-head_cmd,$(builddir)/final-target_linux,\
                       $(builddir)/final-target_linux/sysroot,\
                       mrproper \
                       CROSS_COMPILE='$(TARGET_UPLET)-' \
                       PATH='$(stagedir)/bin:$(PATH)')
endef

define install_final-target_linux
$(call mkdir,$(finaldir)$(PREFIX)$(target_sysroot)/include)
$(RSYNC) -a $(builddir)/final-target_linux/sysroot/include/ \
            $(finaldir)$(PREFIX)$(target_sysroot)/include
endef

define uninstall_final-target_linux
$(call uninstall_from_refdir,$(builddir)/final-target_linux/sysroot/include,\
                             $(finaldir)/$(PREFIX)$(target_sysroot)/include)
endef

$(call gen_deps,final-target_linux,bstrap-host_gcc)

$(call gen_config_rules_with_dep,final-target_linux,linux)
$(call gen_clobber_rules,final-target_linux)
$(call gen_build_rules,final-target_linux,build_final-target_linux)
$(call gen_clean_rules,final-target_linux,clean_final-target_linux)
$(call gen_install_rules,final-target_linux,install_final-target_linux)
$(call gen_uninstall_rules,final-target_linux,uninstall_final-target_linux)
$(call gen_dir_rules,final-target_linux)
