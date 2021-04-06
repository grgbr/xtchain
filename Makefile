unexport AS AR NM LD STRIP CXX OBJCOPY RANLIB CC OBJDUMP CFLAGS LDFLAGS DESTDIR

TOPDIR             := $(CURDIR)
CONFIGDIR          := $(TOPDIR)/config
SCRIPTDIR          := $(TOPDIR)/scripts
BUILDDIR           := $(TOPDIR)/out
PREFIX             := /opt/xtchain
VERSION            := $(shell $(SCRIPTDIR)/localversion.sh \
                              "$(TOPDIR)" 2>/dev/null)
ifeq ($(VERSION),)
$(error Unable to derive xtchain package version)
endif

# Do not use make's abspath function since it does not properly expand glob
# patterns in all situations (especially for command line overridden variables).
override CONFIGDIR := $(shell readlink --canonicalize-missing $(CONFIGDIR))
override SCRIPTDIR := $(shell readlink --canonicalize-missing $(SCRIPTDIR))
override BUILDDIR  := $(shell readlink --canonicalize-missing $(BUILDDIR))
override PREFIX    := $(shell readlink --canonicalize-missing $(PREFIX))
ifneq ($(DESTDIR),)
override DESTDIR   := $(shell readlink --canonicalize-missing $(DESTDIR))
endif

flavours           := $(shell find $(CONFIGDIR) \
                                   -name "*.mk" \
                                   -exec basename {} .mk \;)
ifeq ($(flavours),)
$(error Missing configuration files.)
endif

empty :=

define newline
$(empty)
$(empty)
endef

# Compute number of available CPUs.
# Note: we should use the number of online CPUs...
cpu_nr := $(shell grep '^processor[[:blank:]]\+:' /proc/cpuinfo | wc -l)

# Compute maximum number of Makefile jobs.
job_nr := $(shell echo $$(($(cpu_nr) * 3 / 2)))

MAKEFLAGS += --jobs $(job_nr)

# The list of packages required for the build to complete.
packages := coreutils \
            tar \
            patch \
            help2man \
            gcc \
            g++ \
            make \
            autoconf \
            automake \
            libtool \
            libtool-bin \
            libncurses5-dev \
            git \
            ssh \
            pkg-config \
            flex \
            bison \
            texinfo \
            texlive \
            gawk \
            rsync \
            python3-sphinx \
            python3-sphinx-rtd-theme \
            unzip

ifeq ($(V),)
.SILENT:
endif
.NOTPARALLEL:

################################################################################
# Module targets
################################################################################

modules            := autoconf automake libtool pkgconfig ldconfig crosstool final doc
extract_targets    := $(foreach f,$(flavours),$(addprefix extract-$(f)-,$(modules)))
config_targets     := $(foreach f,$(flavours),$(addprefix config-$(f)-,$(modules)))
build_targets      := $(foreach f,$(flavours),$(addprefix build-$(f)-,$(modules)))
install_targets    := $(foreach f,$(flavours),$(addprefix install-$(f)-,$(modules)))
clean_targets      := $(foreach f,$(flavours),$(addprefix clean-$(f)-,$(modules)))
all_targets        := $(extract_targets) \
                      $(config_targets) \
                      $(build_targets) \
                      $(install_targets) \
                      $(clean_targets)

target_action  = $(word 1,$(subst -, ,$(1)))
target_flavour = $(word 2,$(subst -, ,$(1)))
target_module  = $(word 3,$(subst -, ,$(1)))

define gen_top_targets
.PHONY: $(1)-$(2)
$(1)-$(2): $(foreach m,$(modules),$(1)-$(2)-$(m))
endef

$(eval $(foreach f,$(flavours),$(call gen_top_targets,extract,$(f))$(newline)))
$(eval $(foreach f,$(flavours),$(call gen_top_targets,config,$(f))$(newline)))
$(eval $(foreach f,$(flavours),$(call gen_top_targets,build,$(f))$(newline)))
$(eval $(foreach f,$(flavours),$(call gen_top_targets,install,$(f))$(newline)))

.PHONY: $(all_targets)
$(all_targets):
	$(MAKE) -C $(TOPDIR)/$(call target_module,$(@)) \
	        $(call target_action,$(@)) \
	        TOPDIR:=$(TOPDIR) \
	        CONFIGDIR:=$(CONFIGDIR) \
	        SCRIPTDIR:=$(SCRIPTDIR) \
	        FLAVOUR:=$(call target_flavour,$(@)) \
	        BUILDDIR:=$(BUILDDIR) \
	        PREFIX:=$(PREFIX) \
	        VERSION:=$(VERSION) \
	        DESTDIR:=$(DESTDIR)

################################################################################
# Crosstool module specific targets
################################################################################

menuconfig_crosstool_targets := $(foreach f, \
                                          $(flavours), \
                                          $(addprefix menuconfig-$(f)-, \
                                                      crosstool))
download_crosstool_targets   := $(foreach f, \
                                          $(flavours), \
                                          $(addprefix download-$(f)-,crosstool))
crosstool_targets            := $(menuconfig_crosstool_targets) \
                                $(download_crosstool_targets)

.PHONY: $(crosstool_targets)
$(crosstool_targets):
	$(MAKE) -C $(TOPDIR)/crosstool \
	        $(call target_action,$(@)) \
	        TOPDIR:=$(TOPDIR) \
	        CONFIGDIR:=$(CONFIGDIR) \
	        SCRIPTDIR:=$(SCRIPTDIR) \
	        FLAVOUR:=$(call target_flavour,$(@)) \
	        BUILDDIR:=$(BUILDDIR) \
	        PREFIX:=$(PREFIX) \
	        VERSION:=$(VERSION) \
	        DESTDIR:=$(DESTDIR)

################################################################################
# Main targets
################################################################################

# Install required packages:
# - preventing them to be upgraded if they are already installed,
# - assuming "yes" answer to all prompts.
.PHONY: prepare
prepare:
	apt-get install --no-upgrade --assume-yes $(packages)

.PHONY: $(foreach f,$(flavours),clean-$(f))
$(foreach f,$(flavours),clean-$(f)):
	@rm -rf $(BUILDDIR)/$(subst clean-,$(empty),$(@))

.PHONY: mrproper
mrproper:
	@rm -rf $(BUILDDIR)

.PHONY: list
list:
	@echo Available toolchains:
	@for f in $(flavours); do \
		printf "  %-16s -- " "$$f"; \
		make --just-print \
		     --print-data-base \
		     --no-builtin-rules \
		     --no-builtin-variables \
		     --makefile "$(CONFIGDIR)/$$f.mk"  2>/dev/null | \
		awk --field-separator '=[[:blank:]]*' \
		' \
			/CONFIG_DESC/ { print $$2 } \
		'; \
	 done
	@echo
	@echo Available modules:
	@for m in $(modules); do \
		printf "  %-16s\n" "$$m"; \
	 done

showvar-%: FORCE
	$(if $($(subst showvar-,$(empty),$(@))), \
	     echo $($(subst showvar-,$(empty),$(@))))

.PHONY: FORCE
FORCE:

define help_message
===== Usage =====

Build and install toolchain(s) for I.C. ComEth platforms.

::Main targets::
  prepare                          -- install packages required to build the
                                      toolchain
  mrproper                         -- remove all toolchains generated objects
  list                             -- display available buildable toolchains
  help                             -- this help message


::Toolchain targets:: Applicable to specified TOOLCHAIN
  extract-<TOOLCHAIN>              -- extract all TOOLCHAIN modules archive into
                                      $$(BUILDDIR)/$$(TOOLCHAIN) build area
  config-<TOOLCHAIN>               -- configure build of all TOOLCHAIN modules
  build-<TOOLCHAIN>                -- build all TOOLCHAIN modules
  install-<TOOLCHAIN>              -- install all TOOLCHAIN modules under
                                      $$(PREFIX)/$$(TOOLCHAIN) final directory
  clean-<TOOLCHAIN>                -- remove all TOOLCHAIN modules generated
                                      objects from $$(BUILDDIR)/$$(TOOLCHAIN)
                                      build area


::Module targets:: Applicable to specified TOOLCHAIN / MODULE combination
  extract-<TOOLCHAIN>-<MODULE>     -- extract TOOLCHAIN MODULE archive into
                                      $$(BUILDDIR)/$$(TOOLCHAIN) build area
  config-<TOOLCHAIN>-<MODULE>      -- configure build of TOOLCHAIN MODULE
  build-<TOOLCHAIN>-<MODULE>       -- build TOOLCHAIN MODULE
  install-<TOOLCHAIN>-<MODULE>     -- install TOOLCHAIN MODULE under
                                      $$(PREFIX)/$$(TOOLCHAIN) final directory
  clean-<TOOLCHAIN>-<MODULE>       -- remove TOOLCHAIN MODULE generated objects
                                      from $$(BUILDDIR)/$$(TOOLCHAIN) build area

::Crosstoll module targets:: Applicable to specified TOOLCHAIN / crosstool
                             combination
  menuconfig-<TOOLCHAIN>-crosstool -- configure build of TOOLCHAIN crosstool
                                      module interactively
  download-<TOOLCHAIN>-crosstool   -- download software components required to
                                      build TOOLCHAIN crosstool module.

::Where::
  TOOLCHAIN                        -- name of toolchain as listed by the list
                                      target
  MODULE                           -- name of module listed by the list target
  BUILDDIR                         -- pathname to base directory where
                                      intermediate objects are generated
                                      [$(BUILDDIR)]
  PREFIX                           -- pathname to base directory under which
                                      toolchain objects will be installed /
                                      deployed
                                      [$(PREFIX)]

Further infos may be found into the doc/README.rst file located at the root of
xtchain source tree.

endef

.PHONY: help
help:
	printf '$(subst $(newline),\n,$(help_message))'

.DEFAULT_GOAL := help
