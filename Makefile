OUTDIR   := $(CURDIR)/out
FETCHDIR := $(OUTDIR)/fetch
DESTDIR  :=
DEBDIST  :=
DEBORIG  := $(shell hostname --short)
DEBMAIL  := $(USER)@$(shell hostname --short)
PREFIX   := /opt/xtchain
TARGET   := a38x

################################################################################
# Do not touch these unless you really known what you are doing...
################################################################################

TOPDIR            := $(CURDIR)
override OUTDIR   := $(strip $(OUTDIR))
override PATCHDIR := $(strip $(TOPDIR)/patches)
override FETCHDIR := $(strip $(FETCHDIR))
override CONFDIR  := $(strip $(TOPDIR))/config
override DESTDIR  := $(strip $(DESTDIR))
override DEBDIST  := $(strip $(DEBDIST))
override DEBORIG  := $(strip $(DEBORIG))
override DEBMAIL  := $(strip $(DEBMAIL))
V                 :=

empty             :=
comma             := ,
space             := $(empty) $(empty)

ifeq ($(strip $(V)),)
.SILENT:
MAKEFLAGS += --silent --no-print-directory
verbose   := >/dev/null
endif

ifeq ($(strip $(JOBS)),)
# Compute number of available CPUs.
# Note: we should use the number of online CPUs...
JOBS := $(shell grep '^processor[[:blank:]]\+:' /proc/cpuinfo | wc -l)
endif

# Debian based distribution codename probing
debdist := $(if $(DEBDIST),$(DEBDIST),$(shell lsb_release -cs))
ifeq ($(realpath $(TOPDIR)/debian/$(debdist).mk),)
$(error Unsupported build distribution '$(debdist)')
endif
include $(TOPDIR)/debian/$(debdist).mk
export DEBSRCDEPS DEBBINDEPS

ifneq ($(realpath /.dockerenv),)
outdir          := $(OUTDIR)/$(debdist)
else
outdir          := $(OUTDIR)/current
endif
# Where sources are extracted
srcdir          := $(outdir)/src
# Where compile / link happens
builddir        := $(outdir)/build
# Temporary install directory (mainly for uninstall usage)
installdir      := $(outdir)/install
# Compiler bootstrapping area base directory
bstrapdir       := $(outdir)/bstrap
# Staging install destination base directory
stagedir        := $(outdir)/stage
# Final install destination base directory
finaldir        := $(outdir)/final
# Pathname to base directory used to build debian package.
debdir          := $(outdir)/debian
# Base timestamps directory location
stampdir        := $(outdir)/stamp
# Location where to find various testing utilities
testdir         := $(TOPDIR)/test
# Location where to find various script utilities
scriptdir       := $(TOPDIR)/scripts

# XtChain version
version         := $(shell $(scriptdir)/localversion.sh "$(TOPDIR)")
version_maj     := $(word 1,$(subst .,$(space),$(version)))
pkgname         := xtchain-$(TARGET)-$(version_maj)

# Final install prefix. Default value include version to support multiple
# XtChain installs.
override PREFIX := $(strip $(PREFIX))/xtchain-$(word 1,$(subst .,$(space),$(version)))
override PREFIX := $(PREFIX)/$(TARGET)

# XtChain package version strings
pkgvers         := XtChain $(TARGET) $(version)
pkgurl          := $(PREFIX)/share/doc/$(pkgname)/README.Bugs

include $(CONFDIR)/build.mk
include build/helpers.mk
include $(CONFDIR)/$(TARGET).mk

#target_sysroot  := /$(TARGET_UPLET)/sysroot
target_sysroot  := /sysroot
bstrap_sysroot  := $(bstrapdir)$(target_sysroot)
stage_sysroot   := $(stagedir)$(target_sysroot)
final_sysroot   := $(finaldir)$(PREFIX)$(target_sysroot)

fortify_flags   := -D_FORTIFY_SOURCE=%
o_flags         := -O%
ssp_flags       := -fstack-protector%
pie_flags       := -fpie -fPIE -pie
lto_flags       := -flto% -ffat-lto%
rpath_flags     := -Wl,-rpath%

module_mkfiles  := $(wildcard modules/*.mk)

ifeq ($(DEBDIST),)

MAKEFLAGS += --jobs $(JOBS)

include build/rules.mk
include $(module_mkfiles)

check_black_list :=

.PHONY: list-bstrap
list-bstrap:
	@$(foreach t,$(sort $(bstrap_targets)),echo $(t);)

.PHONY: bstrap
bstrap: $(bstrap_targets)
	$(call rmrf,$(bstrapdir)/share/doc)
	$(call rmrf,$(bstrapdir)/share/info)
	$(call rmrf,$(bstrapdir)/share/man)
	$(scriptdir)/strip.sh $(bstrapdir) '! -path "$(bstrap_sysroot)/*"'

.PHONY: clobber-bstrap
clobber-bstrap:
	$(foreach d,$(wildcard $(stampdir)/bstrap-*),$(call rmrf,$(d))$(newline))
	$(foreach d,$(wildcard $(builddir)/bstrap-*),$(call rmrf,$(d))$(newline))
	$(foreach d,$(wildcard $(installdir)/bstrap-*),$(call rmrf,$(d))$(newline))
	$(call rmrf,$(bstrapdir))

.PHONY: list-stage
list-stage:
	@$(foreach t,$(sort $(stage_targets)),echo $(t);)

.PHONY: stage
stage: $(stage_targets)
	$(call rmrf,$(stagedir)/share/doc)
	$(call rmrf,$(stagedir)/share/gtk-doc)
	$(call rmrf,$(stagedir)/share/info)
	$(call rmrf,$(stagedir)/share/man)
	$(scriptdir)/strip.sh $(stagedir) '! -path "$(stage_sysroot)/*"'

.PHONY: check-stage-rpath
check-stage-rpath: $(stage_targets)
	env READELF='$(stage_readelf)' \
	$(testdir)/check_rpath.sh $(if $(V),--verbose) \
	                          $(stagedir) \
	                          '^$(PREFIX)/lib.*'

.PHONY: check-stage-shebang
check-stage-shebang: $(stage_targets)
	$(testdir)/check_shebang.sh $(if $(V),--verbose) $(stagedir) $(stagedir)

.PHONY: check-stage
check-stage: $(filter-out $(check_black_list),$(stage_check_targets)) \
             check-stage-rpath check-stage-shebang

.PHONY: clobber-stage
clobber-stage:
	$(foreach d,$(wildcard $(stampdir)/stage-*),$(call rmrf,$(d))$(newline))
	$(foreach d,$(wildcard $(builddir)/stage-*),$(call rmrf,$(d))$(newline))
	$(foreach d,$(wildcard $(installdir)/stage-*),$(call rmrf,$(d))$(newline))
	$(call rmrf,$(stagedir))

.PHONY: list-final
list-final:
	@$(foreach t,$(sort $(final_targets)),echo $(t);)

.PHONY: final
final: $(final_targets)

.PHONY: check-final-rpath
check-final-rpath: $(final_targets)
	env READELF='$(stage_readelf)' \
	$(testdir)/check_rpath.sh $(if $(V),--verbose) \
	                          $(finaldir) \
	                          '^$(PREFIX)/lib.*'

.PHONY: check-final-shebang
check-final-shebang: $(final_targets)
	$(testdir)/check_shebang.sh $(if $(V),--verbose) $(finaldir) $(PREFIX)

.PHONY: check-final
check-final: $(filter-out $(check_black_list),$(final_check_targets)) \
             check-final-shebang check-final-rpath

check: check-final

.PHONY: clobber-final
clobber-final:
	$(foreach d,$(wildcard $(stampdir)/final-*),$(call rmrf,$(d))$(newline))
	$(foreach d,$(wildcard $(builddir)/final-*),$(call rmrf,$(d))$(newline))
	$(foreach d,$(wildcard $(installdir)/final-*),$(call rmrf,$(d))$(newline))
	$(call rmrf,$(finaldir))

.PHONY: list
list:
	@$(foreach t,$(sort $(all_targets)),echo $(t);)

.PHONY: show-version
show-version:
	@echo $(version)

.PHONY: all
all: final

.PHONY: build
build: final

# Debian package architecture field
debarch    := $(shell dpkg --print-architecture)
# Debian package depends field
debbindeps := $(subst $(space),$(comma)$(space),$(strip $(DEBBINDEPS)))
# Debian file path
debfile    := $(OUTDIR)/$(pkgname)_$(version)_$(debarch).deb

.PHONY: debian
debian: $(debfile)
$(debfile): $(final_targets) \
            $(TOPDIR)/debian/control.in \
            Makefile
	$(call rmrf,$(debdir))
	$(MKDIR) --parents --mode=755 $(debdir)
	$(call mirror_cmd,$(finaldir),$(debdir))
	$(Q)find $(debdir)$(PREFIX) -name "*.la" -delete
	$(Q)$(scriptdir)/strip.sh '$(debdir)$(PREFIX)' \
	                          '! -path "$(debdir)$(PREFIX)$(target_sysroot)/*"'
	$(MKDIR) --mode=755 $(debdir)/DEBIAN
	umask=0022 && \
	sed --expression='s/@@DEBVERS@@/$(version)/g' \
	    --expression='s/@@DEBTARGET@@/$(TARGET)/g' \
	    --expression='s/@@DEBPKGNAME@@/$(pkgname)/g' \
	    --expression='s/@@DEBVERSMAJOR@@/$(version_maj)/g' \
	    --expression='s/@@DEBDIST@@/$(debdist)/g' \
	    --expression='s/@@DEBORIG@@/$(DEBORIG)/g' \
	    --expression='s/@@DEBARCH@@/$(debarch)/g' \
	    --expression='s/@@DEBMAIL@@/$(DEBMAIL)/g' \
	    --expression='s/@@DEBBINDEPS@@/$(debbindeps)/g' \
	    $(TOPDIR)/debian/control.in > $(debdir)/DEBIAN/control
	fakeroot dpkg-deb --build "$(debdir)" "$(outdir)"

.PHONY: install
install: $(final_targets)
	$(MKDIR) --parents --mode=755 $(DESTDIR)$(PREFIX)
	$(call mirror_cmd,$(finaldir)$(PREFIX),$(DESTDIR)$(PREFIX))
	$(Q)find $(finaldir)$(PREFIX) -name "*.la" -delete

.PHONY: install-strip
install-strip: install
	$(Q)$(scriptdir)/strip.sh '$(DESTDIR)$(PREFIX)' \
	                          '! -path "$(DESTDIR)$(PREFIX)$(target_sysroot)/*"'

.PHONY: uninstall
uninstall:
	$(Q)$(call uninstall_from_refdir,$(finaldir)$(PREFIX),$(DESTDIR)$(PREFIX))

include build/doc.mk

else  # !($(DEBDIST),)

# Docker, since version 20.03, basically defines that unprivileged ports start
# at 0 instead of 1024 so that even when the net_bind_service capability is
# dropped, network services may bind to conventional privileged ports.
# This is why the --sysctl option is given (running sysctl from within the
# container will fail since disallowed by Docker).
#
# This is required to ensure that TCL testsuite completes properly. Otherwise,
# some socket related tests (socket_inet and co.) would complain with the
# following error message:
#     `htons problem, should be disallowed, are you running as SU?'
# /etc/machine-id: glib test need valid machine id, use host machine-id
define dock_run_cmd
docker run \
       --rm=true \
       --cap-add=SYS_PTRACE \
       --security-opt seccomp=unconfined \
       --sysctl="net.ipv4.ip_unprivileged_port_start=1024" \
       --volume $(HOME):$(HOME):ro \
       --volume $(TOPDIR):$(TOPDIR):ro \
       --volume $(OUTDIR):$(OUTDIR):rw \
       --volume /etc/machine-id:/etc/machine-id:ro \
       --workdir $(TOPDIR) \
       --tty=true \
       --interactive=true \
       "xtchain:$(strip $(1))" \
       $(2)
endef

define dock_run_make
$(call dock_run_cmd,\
       $(1),\
       make $(filter --silent --no-print-directory,$(MAKEFLAGS)) \
            --directory="$(TOPDIR)" \
            $(2) \
            JOBS="$(JOBS)" \
            OUTDIR="$(OUTDIR)" \
            FETCHDIR="$(FETCHDIR)" \
            PREFIX="$(PREFIX)" \
            DESTDIR="$(DESTDIR)" \
            DEBDIST= \
            DEBORIG="$(DEBORIG)" \
            DEBMAIL="$(DEBMAIL)" \
            V=$(V))
endef

$(OUTDIR)/$(DEBDIST)/stamp/docker-ready: $(TOPDIR)/Dockerfile \
                                         $(TOPDIR)/debian/$(DEBDIST).mk \
                                         | $(OUTDIR)/$(DEBDIST)/stamp
	docker build \
	       --file '$(<)' \
	       --tag 'xtchain:$(DEBDIST)' \
	           --build-arg DOCKIMG="$(DOCKIMG)" \
	           --build-arg DEBSRCDEPS="$(DEBSRCDEPS)" \
	           --build-arg XTCHAIN_UID="$(shell id -u)" \
	           --build-arg XTCHAIN_USER="$(shell id -un)" \
	           --build-arg XTCHAIN_GID="$(shell id -g)" \
	           --build-arg XTCHAIN_GROUP="$(shell id -gn)" \
	           --build-arg XTCHAIN_HOME="$(HOME)" \
	       $(TOPDIR)
	$(call touch,$(@))

$(OUTDIR)/$(DEBDIST)/build $(OUTDIR)/$(DEBDIST)/stamp:
	$(call mkdir,$(@))

.PHONY: shell
shell: $(OUTDIR)/$(DEBDIST)/stamp/docker-ready
	$(call dock_run_cmd,$(DEBDIST))

.PHONY: test-deps
test-deps: $(OUTDIR)/$(DEBDIST)/stamp/docker-ready
	$(call dock_run_cmd,$(DEBDIST),$(TOPDIR)/scripts/test_deps.sh)

_goals := $(filter-out $(OUTDIR)% $(TOPDIR)% shell test-deps,$(MAKECMDGOALS))
ifeq ($(_goals),)
	_goals := all
endif

.PHONY: $(_goals)
$(_goals): $(OUTDIR)/$(DEBDIST)/stamp/docker-ready
	$(call dock_run_make,$(DEBDIST),$(@))

endif # ($(DEBDIST),)

.DEFAULT_GOAL := all

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

## FIXMEEEEEEE ! Do we really need this ???
## Build host pkg-config default system-wide search path. This is useful to probe
## for system components we depend on.
##SYS_PKG_CONFIG_PATH := $(shell pkg-config --variable pc_path pkg-config)
#
##
## Bootstrapping flags
##
#
#bstrap_ar             := $(bstrapdir)/bin/ar
#bstrap_nm             := $(bstrapdir)/bin/nm
#bstrap_ranlib         := $(bstrapdir)/bin/ranlib
#bstrap_objcopy        := $(bstrapdir)/bin/objcopy
#bstrap_objdump        := $(bstrapdir)/bin/objdump
#bstrap_readelf        := $(bstrapdir)/bin/readelf
#bstrap_strip          := $(bstrapdir)/bin/strip
#bstrap_as             := $(bstrapdir)/bin/as
#bstrap_cc             := $(bstrapdir)/bin/gcc
#bstrap_cxx            := $(bstrapdir)/bin/g++
#bstrap_ld             := $(bstrapdir)/bin/ld
#bstrap_m4             := $(bstrapdir)/bin/m4
#bstrap_cppflags       := $(BUILD_CPPFLAGS) -I$(bstrapdir)/include
#bstrap_cflags         := $(BUILD_CFLAGS)
#bstrap_cxxflags       := $(BUILD_CXXFLAGS)
#bstrap_ldflags        := $(BUILD_LDFLAGS) -L$(bstrapdir)/lib
#bstrap_sysroot        := $(bstrapdir)$(target_sysroot)
#
#_bstrap_lib64_path    := $(bstrapdir)/lib64
#_bstrap_lib64_ldflags := -L$(_bstrap_lib64_path) \
#                         -Wl,-rpath,$(_bstrap_lib64_path)
#_bstrap_lib_path      := $(bstrapdir)/lib
#_bstrap_lib_ldflags   := -L$(_bstrap_lib_path) -Wl,-rpath,$(_bstrap_lib_path)
#
#define bstrap_lib_ldflags
#$(if $(mach_is_64bits),$(_bstrap_lib64_ldflags)) $(_bstrap_lib_ldflags)
#endef
#
#define bstrap_lib_path
#$(if $(mach_is_64bits),$(_bstrap_lib64_path):)$(_bstrap_lib_path)
#endef
#
## $(1): list of preprocessor / compile / link flags to exclude
#define bstrap_config_flags
#CPP='$(BUILD_CPP)' \
#AS='$(BUILD_AS)' \
#CC='$(BUILD_CC)' \
#CXX='$(BUILD_CXX)' \
#AR='$(BUILD_AR)' \
#NM='$(BUILD_NM)' \
#RANLIB='$(BUILD_RANLIB)' \
#OBJCOPY='$(BUILD_OBJCOPY)' \
#OBJDUMP='$(BUILD_OBJDUMP)' \
#READELF='$(BUILD_READELF)' \
#STRIP='$(BUILD_STRIP)' \
#PATH='$(bstrapdir)/bin:$(PATH)' \
#CPPFLAGS='$(call xclude_flags,$(1),$(bstrap_cppflags))' \
#CFLAGS='$(call xclude_flags,$(1),$(bstrap_cflags))' \
#CXXFLAGS='$(call xclude_flags,$(1),$(bstrap_cxxflags))' \
#LDFLAGS='$(call xclude_flags,$(1),$(bstrap_ldflags))'
#endef
#
##
## Staging flags
##
#
#_stage_lib64_path     := $(stagedir)/lib64
#_stage_lib64_ldflags  := -L$(_stage_lib64_path) -Wl,-rpath,$(_stage_lib64_path)
#_stage_lib_path       := $(stagedir)/lib
#_stage_lib_ldflags    := -L$(_stage_lib_path) -Wl,-rpath,$(_stage_lib_path)
#
#define stage_lib_ldflags
#$(if $(mach_is_64bits),$(_stage_lib64_ldflags)) $(_stage_lib_ldflags)
#endef
#
#define stage_lib_path
#$(if $(mach_is_64bits),$(_stage_lib64_path):)$(_stage_lib_path)
#endef
#
#stage_ar              := $(stagedir)/bin/ar
#stage_nm              := $(stagedir)/bin/nm
#stage_ranlib          := $(stagedir)/bin/ranlib
#stage_objcopy         := $(stagedir)/bin/objcopy
#stage_objdump         := $(stagedir)/bin/objdump
#stage_readelf         := $(stagedir)/bin/readelf
#stage_strip           := $(stagedir)/bin/strip
#stage_pkg-config      := $(stagedir)/bin/pkg-config
#stage_as              := $(stagedir)/bin/as
#stage_cc              := $(stagedir)/bin/gcc
#stage_cxx             := $(stagedir)/bin/g++
#stage_ld              := $(stagedir)/bin/ld
#stage_m4              := $(stagedir)/bin/m4
#stage_perl            := $(stagedir)/bin/perl
#stage_tclsh           := $(stagedir)/bin/tclsh
#stage_expect          := $(stagedir)/bin/expect
#stage_runtest         := $(stagedir)/bin/runtest
#stage_python          := $(stagedir)/bin/python
#stage_xgettext        := $(stagedir)/bin/xgettext
#stage_msgfmt          := $(stagedir)/bin/msgfmt
#stage_gmsgfmt         := $(stagedir)/bin/msgfmt
#stage_msgmerge        := $(stagedir)/bin/msgmerge
#stage_makeinfo        := $(stagedir)/bin/makeinfo
#stage_bison           := $(stagedir)/bin/bison
#stage_yacc            := $(stagedir)/bin/bison -y
#stage_flex            := $(stagedir)/bin/flex
#stage_gperf           := $(stagedir)/bin/gperf
#stage_help2man        := $(stagedir)/bin/help2man
#stage_pod2man         := $(stagedir)/bin/pod2man
#stage_libtool         := $(stagedir)/bin/libtool
#stage_chrpath         := $(stagedir)/bin/chrpath
#stage_ninja           := $(stagedir)/bin/ninja
#stage_meson           := $(stagedir)/bin/meson
#stage_cppflags        := -I$(stagedir)/include $(BUILD_CPPFLAGS)
#stage_cflags          := -I$(stagedir)/include $(BUILD_CFLAGS)
#stage_cxxflags        := -I$(stagedir)/include $(BUILD_CXXFLAGS)
#stage_ldflags          = $(BUILD_LDFLAGS) $(stage_lib_ldflags)
#stage_sysroot         := $(stagedir)$(target_sysroot)
#
## $(1): list of preprocessor / compile / link flags to exclude
#define stage_config_flags
#AR='$(stage_ar)' \
#NM='$(stage_nm)' \
#RANLIB='$(stage_ranlib)' \
#OBJCOPY='$(stage_objcopy)' \
#OBJDUMP='$(stage_objdump)' \
#READELF='$(stage_readelf)' \
#STRIP='$(stage_strip)' \
#PKG_CONFIG='$(stage_pkg-config)' \
#AS='$(stage_as)' \
#CC='$(stage_cc)' \
#CXX='$(stage_cxx)' \
#M4='$(stage_m4)' \
#PERL='$(stage_perl)' \
#TCLSH_PROG='$(stage_tclsh)' \
#TCLSH_CMD='$(stage_tclsh)' \
#EXPECT='$(stage_expect)' \
#RUNTEST='$(stage_runtest)' \
#PYTHON='$(stage_python)' \
#XGETTEXT=':' \
#MSGFMT=':' \
#GMSGFMT=':' \
#MSGFMT=':' \
#MAKEINFO='true' \
#BISON='$(stage_bison)' \
#YACC='$(stage_yacc)' \
#FLEX='$(stage_flex)' \
#LEX='$(stage_flex)' \
#GPERF='$(stage_gperf)' \
#HELP2MAN='true' \
#POD2MAN=':' \
#NINJA='$(stage_ninja)' \
#MESON='$(stage_meson)' \
#CPPFLAGS='$(call xclude_flags,$(1),$(stage_cppflags))' \
#CFLAGS='$(call xclude_flags,$(1),$(stage_cflags))' \
#CXXFLAGS='$(call xclude_flags,$(1),$(stage_cxxflags))' \
#LDFLAGS='$(call xclude_flags,$(1),$(stage_ldflags))'
#endef
#
##
## Final flags
##
#
#_final_lib64_ldflags := -L$(_stage_lib64_path) \
#                        -Wl,-rpath-link,$(_stage_lib64_path) \
#                        -L$(_stage_lib_path) \
#                        -Wl,-rpath-link,$(_stage_lib_path) \
#                        -Wl,-rpath,$(PREFIX)/lib \
#                        -Wl,-rpath,$(PREFIX)/lib64
#_final_lib_ldflags   := -L$(_stage_lib_path) \
#                        -Wl,-rpath-link,$(_stage_lib_path) \
#                        -Wl,-rpath,$(PREFIX)/lib
#
#define final_lib_ldflags
#$(if $(mach_is_64bits),$(_final_lib64_ldflags),$(_final_lib_ldflags))
#endef
#
#final_lib_path       := $(PREFIX)/lib:$(PREFIX)/lib64
#
#final_cppflags       := -I$(finaldir)$(PREFIX)/include \
#                        -I$(stagedir)/include \
#                        $(BUILD_CPPFLAGS)
#final_cflags         := -I$(finaldir)$(PREFIX)/include \
#                        -I$(stagedir)/include \
#                        $(BUILD_CFLAGS)
#final_cxxflags       := -I$(finaldir)$(PREFIX)/include \
#                        -I$(stagedir)/include \
#                        $(BUILD_CXXFLAGS)
#final_ldflags         = $(BUILD_LDFLAGS) $(final_lib_ldflags)
#
#final_sysroot        := $(finaldir)$(PREFIX)$(target_sysroot)
#
## $(1): list of preprocessor / compile / link flags to exclude
#define final_config_flags
#AR='$(stage_ar)' \
#NM='$(stage_nm)' \
#RANLIB='$(stage_ranlib)' \
#OBJCOPY='$(stage_objcopy)' \
#OBJDUMP='$(stage_objdump)' \
#READELF='$(stage_readelf)' \
#STRIP='$(stage_strip)' \
#PKG_CONFIG='$(stage_pkg-config)' \
#AS='$(stage_as)' \
#CC='$(stage_cc)' \
#CXX='$(stage_cxx)' \
#M4='$(stage_m4)' \
#PERL='$(stage_perl)' \
#TCLSH_PROG='$(stage_tclsh)' \
#TCLSH_CMD='$(stage_tclsh)' \
#EXPECT='$(stage_expect)' \
#RUNTEST='$(stage_runtest)' \
#PYTHON='$(stage_python)' \
#XGETTEXT='$(stage_xgettext)' \
#MSGFMT='$(stage_msgfmt)' \
#GMSGFMT='$(stage_gmsgfmt)' \
#MSGFMT='$(stage_msgmerge)' \
#MAKEINFO='$(stage_makeinfo)' \
#BISON='$(stage_bison)' \
#YACC='$(stage_yacc)' \
#FLEX='$(stage_flex)' \
#LEX='$(stage_flex)' \
#HELP2MAN='$(stage_help2man)' \
#POD2MAN='$(stage_pod2man)' \
#LIBTOOL='$(stage_libtool)' \
#PATH="$(stagedir)/bin:$(PATH)" \
#CPPFLAGS='$(call xclude_flags,$(1),$(final_cppflags))' \
#CFLAGS='$(call xclude_flags,$(1),$(final_cflags))' \
#CXXFLAGS='$(call xclude_flags,$(1),$(final_cxxflags))' \
#LDFLAGS='$(call xclude_flags,$(1),$(final_ldflags))'
#endef
