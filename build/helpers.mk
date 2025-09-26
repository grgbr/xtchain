MKDIR   := mkdir
CURL    := curl
GPG     := gpg
TAR     := tar
TOUCH   := touch
MV      := mv
LN      := ln
SYNC    := sync
RSYNC   := rsync
RMDIR   := rmdir
FIND    := find
CHMOD   := chmod
INSTALL := install
UNZIP   := unzip
ECHOE   := /bin/echo -e
SED     := sed
PATCH   := patch
CHRPATH := chrpath

define build_mach_bits
$(shell $(scriptdir)/mach_bits.sh '$(BUILD_CC) $(BUILD_CFLAGS)')
endef

define target_mach_bits
$(shell $(scriptdir)/mach_bits.sh \
        '$(bstrapdir)/bin/$(TARGET_UPLET)-gcc $(TARGET_CFLAGS)')
endef

arch           := $(shell $(BUILD_CC) $(BUILD_CFLAGS) -dumpmachine)
arch_is_x86_64 := $(filter x86_64%,$(arch))

# Probe for BUILD_CC default library search path (required to find system wide
# libc).
build_lib_search_path := $(shell $(BUILD_CC) -print-search-dirs | \
                                 sed -n 's/^libraries:[[:blank:]]\+=//p')

define newline
$(empty)
$(empty)
endef

# Expand to a set of configure flags declaring tools used to build host software
define config_build_tools
M4='$(BUILD_M4)' \
CPP='$(BUILD_CPP)' \
AS='$(BUILD_AS)' \
CC='$(BUILD_CC)' \
CXX='$(BUILD_CXX)' \
GCC='$(BUILD_CC)' \
LD='$(BUILD_LD)' \
AR='$(BUILD_AR)' \
NM='$(BUILD_NM)' \
OBJCOPY='$(BUILD_OBJCOPY)' \
OBJDUMP='$(BUILD_OBJDUMP)' \
RANLIB='$(BUILD_RANLIB)' \
READELF='$(BUILD_READELF)' \
STRIP='$(BUILD_STRIP)' \
BISON='$(BUILD_BISON)' \
YACC='$(BUILD_YACC)' \
FLEX='$(BUILD_FLEX)' \
LEX='$(BUILD_LEX)' \
PKG_CONFIG='$(BUILD_PKG_CONFIG)' \
PYTHON='$(BUILD_PYTHON)'
endef

# Expand to a set of configure flags declaring tools used to build target
# software
# $(1): pathname to stage prefix directory
define config_target_tools
M4='$(BUILD_M4)' \
CPP='$(strip $(1))/bin/$(TARGET_UPLET)-cpp' \
AS='$(strip $(1))/bin/$(TARGET_UPLET)-as' \
CC='$(strip $(1))/bin/$(TARGET_UPLET)-gcc' \
CXX='$(strip $(1))/bin/$(TARGET_UPLET)-g++' \
GCC='$(strip $(1))/bin/$(TARGET_UPLET)-gcc' \
LD='$(strip $(1))/bin/$(TARGET_UPLET)-ld' \
AR='$(strip $(1))/bin/$(TARGET_UPLET)-gcc-ar' \
NM='$(strip $(1))/bin/$(TARGET_UPLET)-gcc-nm' \
OBJCOPY='$(strip $(1))/bin/$(TARGET_UPLET)-objcopy' \
OBJDUMP='$(strip $(1))/bin/$(TARGET_UPLET)-objdump' \
RANLIB='$(strip $(1))/bin/$(TARGET_UPLET)-gcc-ranlib' \
READELF='$(strip $(1))/bin/$(TARGET_UPLET)-readelf' \
STRIP='$(strip $(1))/bin/$(TARGET_UPLET)-strip' \
BISON='$(BUILD_BISON)' \
YACC='$(BUILD_YACC)' \
FLEX='$(BUILD_FLEX)' \
LEX='$(BUILD_LEX)' \
PKG_CONFIG='$(BUILD_PKG_CONFIG)' \
PYTHON='$(BUILD_PYTHON)'
endef

define _pkg_config_dirs
$(strip $(1))/lib/pkgconfig:$(strip $(1))/share/pkgconfig
endef

# Expand to list of pkg-config(1) secondary directories where ‘.pc’ files are
# looked up.
# $(1): space separated list of pathname to prefix directories
define pkg_config_path
PKG_CONFIG_PATH='$(call _pkg_config_dirs,$(word 1,$(1)))$(foreach d,$(wordlist 2,$(words $(1)),$(1)),:$(call _pkg_config_dirs,$(d)))'
endef

# Expand to a set of configure flags used by gcc and related projects (such as
# binutils, gdb, ...)
# $(1): pathname to stage prefix directory
#
# Checkme: do we need these ?
#     ASFLAGS_FOR_TARGET
#     LIBCFLAGS_FOR_TARGET
#     LIBCXXFLAGS_FOR_TARGET
#     PICFLAG_FOR_TARGET
define gcc_tools_for_target
AS_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-as' \
CC_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-gcc' \
CXX_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-g++' \
GCC_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-gcc' \
LD_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-ld' \
AR_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-ar' \
NM_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-nm' \
OBJCOPY_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-objcopy' \
OBJDUMP_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-objdump' \
RANLIB_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-ranlib' \
READELF_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-readelf' \
STRIP_FOR_TARGET='$(strip $(1))/bin/$(TARGET_UPLET)-strip'
endef

# Use --location for sites where URL points to a page that has moved to a
# different location, e.g. github.
define _download
$(CURL) --silent --location '$(strip $(1))' --output '$(strip $(2))'
endef

define gpg_verify_detach
$(scriptdir)/gpg_verify.sh --homedir "$(FETCHDIR)/.gnupg" \
                           '$(strip $(1))' \
                           '$(strip $(2))'
endef

define download_csum
if [ ! -r "$(FETCHDIR)/$(strip $(2))" ]; then \
	if ! msg=$$($(CURL) --silent \
	                    --show-error \
	                    --stderr - \
	                    --location $(if $(FETCHURI),\
	                                     '$(FETCHURI)/$(strip $(2))',\
	                                     '$(strip $(1))') \
	                    --output '$(FETCHDIR)/$(strip $(2)).tmp'); then \
		echo "download: $(strip $(2)): $$msg" >&2; \
		exit 1; \
	fi; \
	if ! echo '$(strip $(3)) $(FETCHDIR)/$(strip $(2)).tmp' | \
	     sha512sum --check --strict --status -; then \
		echo 'download: $(strip $(2)): checksum mismatch' >&2; \
		exit 1; \
	else \
		$(call mv,$(FETCHDIR)/$(strip $(2)).tmp,$(FETCHDIR)/$(strip $(2))); \
		$(SYNC) --file-system '$(FETCHDIR)/$(strip $(2))'; \
	fi; \
fi
endef

define mkdir
$(MKDIR) --parents "$(strip $(1))"
endef

define rmrf
$(RM) --recursive $(strip $(1))
endef

define rmf
$(RM) $(strip $(1))
endef

define untar
$(MKDIR) --parents "$(strip $(1))"
$(TAR) --extract \
       --directory='$(strip $(1))' \
       --file='$(strip $(2))' \
       $(strip $(3))
endef

define unzip
$(MKDIR) --parents "$(strip $(1))"
$(UNZIP) -q \
         $(strip $(3)) \
         $(strip $(2)) \
         -d $(strip $(1))
endef

define patch
cd $(1) $(foreach p,$(2),&& $(PATCH) -p1 < $(p))
endef

define touch
$(TOUCH) '$(strip $(1))'
endef

define mv
$(MV) '$(strip $(1))' '$(strip $(2))'
endef

# Create symbolic link
# $(1): link target
# $(2): pathname
define slink
$(LN) -sf "$(strip $(1))" "$(strip $(2))" $(verbose)
endef

# Create hard link
# $(1): link target
# $(2): pathname
define hlink
$(LN) -f "$(strip $(1))" "$(strip $(2))"
endef

define download
if [ ! -r "$(strip $(2))" ]; then \
	$(call _download,$(1),$(strip $(2)).tmp) && \
	$(call mv,$(strip $(2)).tmp,$(2)) && \
	$(SYNC) --file-system '$(strip $(2))'; \
fi
endef

define download_verify_detach
if [ ! -r "$(strip $(3))" ]; then \
	$(call _download,$(1),$(strip $(3)).tmp) && \
	$(call _download,$(2),$(strip $(3)).sig) && \
	$(call gpg_verify_detach,$(strip $(3)).sig,$(strip $(3)).tmp) && \
	$(call mv,$(strip $(3)).tmp,$(3)) && \
	$(SYNC) --file-system '$(strip $(3))'; \
fi
endef

define setup_pkgs_cmds
sudo apt-get --assume-yes update
sudo apt-get --assume-yes --no-upgrade install $(DEBSRCDEPS)
endef

define setup_sigs_cmds
$(scriptdir)/gpg_setup.sh $(FETCHDIR)
endef

define _mirror_cmd
umask=0022 && \
$(RSYNC) --recursive \
         --links \
         --devices \
         --specials \
         --perms \
         --chmod=Dg-w,Dg+rx,Do-w,Do+rx,Fg-w,Fg+r,Fo-w,Fo+r \
         --info=progress2 \
         '$(strip $(1))/' '$(strip $(2))' $(verbose)
endef

define mirror_cmd
$(if $(realpath $(strip $(1))),,$(error '$(strip $(1))': Invalid mirror destination))
$(call rmrf,$(2))
$(call _mirror_cmd,$(1),$(2))
endef

define strip_cmd
umask=0022 && $(scriptdir)/strip.sh '$(strip $(1))'
endef

#$(1): reference top-level directory holding files to uninstall from $(2)
#$(2): top-level directory to uninstall files from
define uninstall_from_refdir
if [ -d "$(strip $(1))" ]; then \
	$(FIND) "$(strip $(1))" ! -type d -printf "%P\n" | \
	while read ln; do \
		$(RM) "$(strip $(2))/$$ln" >/dev/null 2>&1 || true; \
	done; \
	$(FIND) "$(strip $(1))" -type d -printf "%P\n" | sort -r | \
	while read ln; do \
		$(RMDIR) --ignore-fail-on-non-empty \
		         "$(strip $(2))/$$ln" \
		         >/dev/null 2>&1 || \
		         true; \
	done; \
fi
endef

define cleanup_empty_dirs
if [ -d "$(abspath $(strip $(1)))" ]; then \
	$(FIND) "$(abspath $(strip $(1)))" -type d | sort --reverse | \
	while read ln; do \
		$(RMDIR) --ignore-fail-on-non-empty \
		         "$$ln" \
		         >/dev/null 2>&1 || \
		         true; \
	done; \
fi
endef

define _uniq
$(eval _seen :=)
$(foreach _w,$(1),$(if $(filter $(_w),$(_seen)),,$(eval _seen += $(_w))))
$(_seen)
endef

# Filter out duplicate words of string passed in argument
# $(1): string
uniq = $(strip $(call _uniq,$(1)))

define xclude_flags
$(filter-out $(1),$(2))
endef

define log
@printf "### %22.22s### %30.30s %16.16s##\n" \
        "$(strip $(1)) ####################" \
        "$(strip $(2)) ############################" \
        "[$(debdist)] #############"
endef

# Replace shebang of scripts given in argument
# $(1): pathname to scripts to modify
# $(2): replacement shebang
define fixup_shebang
$(SED) --follow-symlinks --in-place '1s;^#!.*;#!$(strip $(2));' $(1)
endef

# Replace RPATH / RUNPATH of binaries given in argument
# $(1): pathname to binaries to modify
# $(2): replacement RPATH / RUNPATH
#
# Watch out ! Must be used only once stage-chrpath module has been installed !
define fixup_rpath
$(stage_chrpath) --replace "$(strip $(2))" $(1) $(verbose)
endef

################################################################################
# Libtool helpers
################################################################################

# Make libtool operate quietly when verbose output is disabled.
define libtool_flags
$(if $(strip $(V)),,LIBTOOLFLAGS='--quiet')
endef

################################################################################
# Python module helpers
################################################################################

define python_ext_lib_suffix_stmts :=
import sysconfig;
print(sysconfig.get_config_var('EXT_SUFFIX'))
endef

# Return python module C extension library file name suffix
# Something like ".cpython-310-x86_64-linux-gnu.so"
define python_ext_lib_suffix
$(shell exec $(stage_python) -s -c "$(python_ext_lib_suffix_stmts)")
endef

define python_site_path_comp_stmts :=
import sys, site;
print(site.getsitepackages()[0].removeprefix(sys.exec_prefix + '/'))
endef

# Return python module install path with exec_prefix removed
# Something like "lib/python3.10/site-packages"
define python_site_path_comp
$(shell exec $(stage_python) -s -c "$(python_site_path_comp_stmts)")
endef

# $(1): targets base name / module name
# $(2): source directory basename
define python_module_config_cmds
$(RSYNC) --archive --delete $(srcdir)/$(strip $(2))/ $(builddir)/$(strip $(1))
endef

# $(1): targets base name / module name
# $(2): build /install prefix
# $(3): optional install destination directory
define pip_module_install_cmds
cd $(builddir)/$(strip $(1)) && \
env PATH='$(stagedir)/bin:$(PATH)' \
$(stage_python) -m pip --no-cache-dir \
                       $(if $(V),--verbose) \
                       install --no-deps \
                               --no-index \
                               --ignore-installed \
                               --force-reinstall \
                               --no-build-isolation \
                               --disable-pip-version-check \
                               --prefix "$(strip $(2))" \
                               $(if $(strip $(3)),--root "$(strip $(3))") \
                               --compile \
                               . \
                               $(verbose)
endef

# $(1): targets base name / module name
# $(2): build /install prefix
# $(3): optional install destination directory
define python_module_install_cmds
$(call pip_module_install_cmds,$(1),$(2),$(installdir)/$(strip $(1)))
$(call pip_module_install_cmds,$(1),$(2),$(3))
endef

# $(1): targets base name / module name
# $(2): optional install destination directory
define python_module_uninstall_cmds
$(call uninstall_from_refdir,$(installdir)/$(strip $(1)),$(2))
$(call rmrf,$(installdir)/$(strip $(1)))
endef

# $(1): targets base name / module name
# $(2): name of xtract module these config rules will depend on
# $(3): build /install prefix
# $(4): optional install destination directory
define python_module_rules
config_$(strip $(1))    = $$(call python_module_config_cmds,$(strip $(1)),\
                                                            $(strip $(2)))
$(if $(value install_$(strip $(1))),\
     ,\
     install_$(strip $(1)) = $$(call python_module_install_cmds,$(strip $(1)),\
                                                                $(strip $(3)),\
                                                                $(strip $(4))))

uninstall_$(strip $(1)) = $$(call python_module_uninstall_cmds,$(strip $(1)),\
                                                               $(strip $(4)))

$(call config_rules_with_dep,$(1),$(2),config_$(strip $(1)))
$(call clobber_rules,$(1))
$(call build_rules,$(1))
$(call clean_rules,$(1))
$(call install_rules,$(1),install_$(strip $(1)))
$(call uninstall_rules,$(1),uninstall_$(strip $(1)))
$(call check_rules,$(1),check_$(strip $(1)))
$(call dir_rules,$(1))
endef

# $(1): targets base name / module name
# $(2): name of xtract module these config rules will depend on
# $(3): build /install prefix
# $(4): optional install destination directory
define gen_python_module_rules
$(eval $(call python_module_rules,$(1),$(2),$(3),$(4)))
endef
