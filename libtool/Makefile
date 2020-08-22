MODULE := libtool
include $(TOPDIR)/utils.mk

AUTOTOOLS_TARBALL_PATHNAME := $(CONFIG_LIBTOOL_TARBALL)

include $(TOPDIR)/autotools.mk

$(stampdir)/configured: $(stampdir)/patched

$(stampdir)/patched: $(stampdir)/extracted
	@echo ===== Patching $(MODULE)
	cd $(builddir) || exit 1; \
	for f in $(sort $(wildcard $(CURDIR)/libtool-*.patch)); do \
	        echo "Applying patch $$f ..." ; \
	        if ! patch -p1 < $$f; then \
	                exit 1; \
	        fi; \
	done
	@echo ===== Reconfiguring $(MODULE) source
	cd $(builddir) && autoreconf -v
	@touch $(@)
