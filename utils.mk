include $(CONFIGDIR)/$(FLAVOUR).mk

empty :=

define newline
$(empty)
$(empty)
endef

define extract_cmd
rm -rf $(1)
mkdir -p $(1)
tar --verbose --directory $(1) --extract --strip-components=1 --file $(2)
endef

prefix   := $(abspath $(PREFIX)/$(FLAVOUR))
builddir := $(abspath $(BUILDDIR)/$(FLAVOUR)/$(MODULE))
stampdir := $(abspath $(BUILDDIR)/$(FLAVOUR)/stamps/$(MODULE))
