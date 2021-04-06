MODULE := ldconfig
include $(TOPDIR)/utils.mk

ifeq ($(strip $(CONFIG_LDCONFIG_TARBALL)),)
$(error Missing tarball definition !)
endif
tarball := $(realpath $(TOPDIR)/$(MODULE)/$(CONFIG_LDCONFIG_TARBALL))

.PHONY: all
all: build

.PHONY: install
install: $(stampdir)/installed

$(stampdir)/installed: $(stampdir)/built
	@echo ===== Installing $(MODULE)
	install -m755 -D \
	        $(builddir)/ldconfig \
	        $(DESTDIR)$(prefix)/$(CONFIG_CROSSTOOL_TUPLE)/bin/$(CONFIG_CROSSTOOL_TUPLE)-ldconfig
	@touch $(@)

.PHONY: build
build: $(stampdir)/built

ldconfig_src := ldconfig.c \
                chroot_canon.c \
                xmalloc.c \
                xstrdup.c \
                cache.c \
                readlib.c \
                dl-cache.c

$(stampdir)/built: $(stampdir)/configured
	@echo ===== Building $(MODULE)
	$(CC) -std=gnu99 \
	      -I$(builddir) \
	      -o $(builddir)/ldconfig \
	      $(addprefix $(builddir)/,$(ldconfig_src))
	@touch $(@)

.PHONY: config
config: $(stampdir)/configured

$(stampdir)/configured: $(stampdir)/patched
	@touch $(@)

$(stampdir)/patched: $(stampdir)/extracted
	@echo ===== Patching $(MODULE)
	cd $(builddir) || exit 1; \
	for f in $(sort $(wildcard $(CURDIR)/ldconfig-*.patch)); do \
	        echo "Applying patch $$f ..." ; \
	        if ! patch -p1 < $$f; then \
	                exit 1; \
	        fi; \
	done
	@touch $(@)

.PHONY: extract
extract: $(stampdir)/extracted

$(stampdir)/extracted: | $(stampdir)
	@echo ===== Extracting $(MODULE)
	$(call extract_cmd,$(builddir),$(tarball))
	@touch $(@)

.PHONY: clean
clean:
	@echo ===== Cleaning $(MODULE)
	rm -rf $(builddir) $(stampdir)

$(stampdir):
	@mkdir -p $(@)
