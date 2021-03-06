MODULE := crosstool
include $(TOPDIR)/utils.mk

ifeq ($(strip $(CONFIG_CROSSTOOL_TARBALL)),)
$(error No crosstool tarball specified !)
endif # ($(CONFIG_CROSSTOOL_TARBALL),)

tarball := $(realpath $(CURDIR)/$(CONFIG_CROSSTOOL_TARBALL))
ifeq ($(tarball),)
$(error No valid crosstool tarball found !)
endif # ($(tarball),)

defconfig := $(realpath $(TOPDIR)/config/$(CONFIG_CROSSTOOL_DEFCONFIG))
ifeq ($(defconfig),)
$(error No valid crosstool default configuration file found !)
endif # ($(defconfig),)

ifeq ($(strip $(CONFIG_CROSSTOOL_TUPLE)),)
$(error No crosstool tuple defined !)
endif # ($(CONFIG_CROSSTOOL_TUPLE),)

installdir := $(abspath $(BUILDDIR)/$(FLAVOUR)/$(CONFIG_CROSSTOOL_TUPLE))
tarballdir := $(CURDIR)

.PHONY: install
install: $(stampdir)/installed

$(stampdir)/installed: $(stampdir)/built
	@echo ===== Installing $(MODULE)
	rsync --archive \
	      --no-owner \
	      $(installdir)/ \
	      $(DESTDIR)$(prefix)
	@touch $(@)

.PHONY: build
build: $(stampdir)/built

$(stampdir)/built: $(stampdir)/configured | $(tarballdir)
	@echo ===== Building $(MODULE)
	+cd $(builddir) && \
		unset LD_LIBRARY_PATH && \
		env TARBALLDIR="$(tarballdir)" \
		    INSTALLDIR="$(installdir)" \
		    DESTDIR:= \
		    VERSION:="$(VERSION)" \
		    ./ct-ng build DESTDIR:=
	@touch $(@)

.PHONY: config
config: $(stampdir)/configured

$(stampdir)/configured: $(stampdir)/prepared
	@echo ===== Configuring $(MODULE)
	+cd $(builddir) && \
		unset LD_LIBRARY_PATH && \
		env DEFCONFIG=$(defconfig) \
		    TARBALLDIR="$(tarballdir)" \
		    INSTALLDIR="$(installdir)" \
		    DESTDIR:= \
		    VERSION:="$(VERSION)" \
		    ./ct-ng defconfig DESTDIR:=
	@touch $(@)

.PHONY: menuconfig
menuconfig: $(stampdir)/configured
	+cd $(builddir) && \
		unset LD_LIBRARY_PATH && \
		env DEFCONFIG=$(defconfig) \
		    TARBALLDIR="$(tarballdir)" \
		    INSTALLDIR="$(installdir)" \
		    DESTDIR:= \
		    VERSION:="$(VERSION)" \
		    ./ct-ng menuconfig DESTDIR:=
	@touch $(<)

.PHONY: download
download: $(stampdir)/configured
	+cd $(builddir) && \
		unset LD_LIBRARY_PATH && \
		env DEFCONFIG=$(defconfig) \
		    TARBALLDIR="$(tarballdir)" \
		    INSTALLDIR="$(installdir)" \
		    DESTDIR:= \
		    VERSION:="$(VERSION)" \
		    ./ct-ng source DESTDIR:=

$(stampdir)/prepared: $(stampdir)/extracted
	+cd $(builddir) && env DESTDIR= ./configure --enable-local && make DESTDIR:=
	@touch $(@)

.PHONY: extract
extract: $(stampdir)/extracted

$(stampdir)/extracted: | $(stampdir)
	@echo ===== Extracting $(MODULE) $(builddir)
	$(call extract_cmd,$(builddir),$(tarball))
	@touch $(@)

$(stampdir) $(tarballdir):
	@mkdir -p $(@)

.PHONY: clean
clean:
	@echo ===== Cleaning $(MODULE)
	rm -rf $(builddir) $(stampdir) $(installdir)
