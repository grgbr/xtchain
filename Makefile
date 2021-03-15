unexport AS AR NM LD STRIP CXX OBJCOPY RANLIB CC OBJDUMP CFLAGS LDFLAGS DESTDIR

TOPDIR           := $(CURDIR)
CONFIGDIR        := $(TOPDIR)/config
BUILDDIR         := $(HOME)/build/xtchain
PREFIX           := $(HOME)/dev/tools/xtchain

CONFIGDIR        := $(abspath $(CONFIGDIR))
BUILDDIR         := $(abspath $(BUILDDIR))
override DESTDIR :=

flavours         := $(shell find $(CONFIGDIR) \
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
            python3-sphinx

.SILENT:
.NOTPARALLEL:

################################################################################
# Module targets
################################################################################

modules            := autoconf automake libtool pkgconfig ldconfig crosstool final doc
extract_targets    := $(foreach f,$(flavours),$(addprefix extract-$(f)-,$(modules)))
config_targets     := $(foreach f,$(flavours),$(addprefix config-$(f)-,$(modules)))
menuconfig_targets := $(foreach f,$(flavours),$(addprefix menuconfig-$(f)-,$(modules)))
build_targets      := $(foreach f,$(flavours),$(addprefix build-$(f)-,$(modules)))
install_targets    := $(foreach f,$(flavours),$(addprefix install-$(f)-,$(modules)))
clean_targets      := $(foreach f,$(flavours),$(addprefix clean-$(f)-,$(modules)))
all_targets        := $(extract_targets) \
                      $(config_targets) \
                      $(menuconfig_targets) \
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
$(eval $(foreach f,$(flavours),$(call gen_top_targets,clean,$(f))$(newline)))

.PHONY: $(all_targets)
$(all_targets):
	$(MAKE) -C $(TOPDIR)/$(call target_module,$(@)) \
	        $(call target_action,$(@)) \
	        TOPDIR:=$(TOPDIR) \
	        CONFIGDIR:=$(CONFIGDIR) \
	        FLAVOUR:=$(call target_flavour,$(@)) \
	        BUILDDIR:=$(BUILDDIR) \
	        PREFIX:=$(PREFIX)

################################################################################
# Main targets
################################################################################

# Install required packages:
# - preventing them to be upgraded if they are already installed,
# - assuming "yes" answer to all prompts.
.PHONY: prepare
prepare:
	apt-get install --no-upgrade --assume-yes $(packages)

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

define help_message
===== Usage =====

Build and install toolchain(s) for I.C. ComEth platforms.

::Main targets::
  prepare                      -- install packages required to build the
                                  toolchain
  mrproper                     -- remove all toolchains generated objects
  list                         -- display available buildable toolchains
  help                         -- this help message


::Toolchain targets:: Applicable to specified TOOLCHAIN
  extract-<TOOLCHAIN>          -- extract all TOOLCHAIN modules archive into
                                  $$(BUILDDIR)/$$(TOOLCHAIN) build area
  config-<TOOLCHAIN>           -- configure build of all TOOLCHAIN modules
  menucconfig-<TOOLCHAIN>      -- configure build of all TOOLCHAIN modules
                                  interactively
  build-<TOOLCHAIN>            -- build all TOOLCHAIN modules
  install-<TOOLCHAIN>          -- install all TOOLCHAIN modules under
                                  $$(PREFIX)/$$(TOOLCHAIN) final directory
  clean-<TOOLCHAIN>            -- remove all TOOLCHAIN modules generated objects
                                  from $$(BUILDDIR)/$$(TOOLCHAIN) build area


::Module targets:: Applicable to specified TOOLCHAIN / MODULE combination
  extract-<TOOLCHAIN>-<MODULE> -- extract TOOLCHAIN MODULE archive into
                                  $$(BUILDDIR)/$$(TOOLCHAIN) build area
  config-<TOOLCHAIN>-<MODULE>  -- configure build of TOOLCHAIN MODULE
  build-<TOOLCHAIN>-<MODULE>   -- build TOOLCHAIN MODULE
  install-<TOOLCHAIN>-<MODULE> -- install TOOLCHAIN MODULE under
                                  $$(PREFIX)/$$(TOOLCHAIN) final directory
  clean-<TOOLCHAIN>-<MODULE>   -- remove TOOLCHAIN MODULE generated objects from
                                  $$(BUILDDIR)/$$(TOOLCHAIN) build area


::Where::
  TOOLCHAIN                    -- name of toolchain as listed by the list target
  MODULE                       -- name of module listed by the list target
  BUILDDIR                     -- pathname to base directory where intermediate
                                  objects are generated
                                  [$(BUILDDIR)]
  PREFIX                       -- pathname to base directory under which
                                  toolchain objects will be installed / deployed
                                  [$(PREFIX)]

Further infos may be found into the README.rst file located at the root of
icchain source tree.

endef

.PHONY: help
help:
	/bin/echo -e '$(subst $(newline),\n,$(help_message))'

.DEFAULT_GOAL := help
