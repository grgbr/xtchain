ifeq ($(strip $(AUTOTOOLS_TARBALL_PATHNAME)),)
$(error Missing tarball definition !)
endif

AUTOTOOLS_TARBALL_PATHNAME := \
	$(realpath $(TOPDIR)/$(MODULE)/$(AUTOTOOLS_TARBALL_PATHNAME))

ifeq ($(AUTOTOOLS_TARBALL_PATHNAME),)
$(error Path to tarball tarball found !)
endif

.PHONY: all
all: build

.PHONY: install
install: $(stampdir)/installed

$(stampdir)/installed: $(stampdir)/built
	@echo ===== Installing $(MODULE)
	$(MAKE) -C $(builddir) install DESTDIR:=
	@touch $(@)

.PHONY: build
build: $(stampdir)/built

$(stampdir)/built: $(stampdir)/configured
	@echo ===== Building $(MODULE)
	$(MAKE) -C $(builddir) all
	@touch $(@)

.PHONY: config
config: $(stampdir)/configured

$(stampdir)/configured: $(stampdir)/extracted
	@echo ===== Configuring $(MODULE)
	cd $(builddir) && ./configure --prefix=$(prefix) \
	                              --with-pkgversion=xtchain \
	                              $(AUTOTOOLS_CONFIGURE_ARGS)
	@touch $(@)

.PHONY: extract
extract: $(stampdir)/extracted

$(stampdir)/extracted: | $(stampdir)
	@echo ===== Extracting $(MODULE)
	$(call extract_cmd,$(builddir),$(AUTOTOOLS_TARBALL_PATHNAME))
	@touch $(@)

.PHONY: clean
clean:
	@echo ===== Cleaning $(MODULE)
	rm -rf $(builddir) $(stampdir)

$(stampdir):
	@mkdir -p $(@)
