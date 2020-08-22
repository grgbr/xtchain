MODULE := pkgconfig
include $(TOPDIR)/utils.mk

AUTOTOOLS_TARBALL_PATHNAME := $(CONFIG_PKGCONFIG_TARBALL)
AUTOTOOLS_CONFIGURE_ARGS   := --with-internal-glib \
                              --disable-host-tool \
                              --with-system-library-path="" \
                              --with-system-include-path="" \
                              --with-pc-path=""

include $(TOPDIR)/autotools.mk
