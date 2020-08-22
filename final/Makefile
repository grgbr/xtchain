MODULE := final
include $(TOPDIR)/utils.mk

ifeq ($(strip $(CONFIG_CROSSTOOL_TUPLE)),)
$(error No crosstool tuple defined !)
endif # ($(CONFIG_CROSSTOOL_TUPLE),)

.PHONY: install
install: $(stampdir)/installed

$(stampdir)/installed: $(stampdir)/built \
                       | $(prefix)/$(CONFIG_CROSSTOOL_TUPLE)/bin
	@echo ===== Installing $(MODULE)
	ln -sf /bin/true $(prefix)/$(CONFIG_CROSSTOOL_TUPLE)/bin/$(CONFIG_CROSSTOOL_TUPLE)-mt
	@touch $(@)

.PHONY: build
build: $(stampdir)/built

$(stampdir)/built: $(stampdir)/configured
	@touch $@

.PHONY: config
config: $(stampdir)/configured

$(stampdir)/configured: | $(stampdir)
	@touch $@

$(stampdir) $(prefix)/$(CONFIG_CROSSTOOL_TUPLE)/bin:
	@mkdir -p $(@)

.PHONY: clean
clean:
	@echo ===== Cleaning $(MODULE)
	rm -rf $(builddir) $(stampdir)
