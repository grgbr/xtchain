MODULE := doc
include $(TOPDIR)/utils.mk

SPHINXBUILD := sphinx-build
SPHINXOPTS  := -a -j 1

install_docdir := $(prefix)/$(CONFIG_CROSSTOOL_TUPLE)/share/doc/xtchain/html

.PHONY: install
install: $(stampdir)/installed

$(stampdir)/installed: $(stampdir)/built | $(install_docdir)
	@echo ===== Installing $(MODULE)
	rsync -rlpt $(builddir)/html/ $(install_docdir)
	install -m644 \
	        $(builddir)/latex/xtchain.pdf \
	        $(install_docdir)/xtchain.pdf
	@touch $(@)

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
.PHONY: build
build: $(stampdir)/built

.PHONY: $(stampdir)/built
$(stampdir)/built: | $(stampdir) $(builddir)
	@echo ===== Building $(MODULE)
	+@$(SPHINXBUILD) -M html "$(CURDIR)" "$(builddir)" $(SPHINXOPTS)
	+@$(SPHINXBUILD) -M latexpdf "$(CURDIR)" "$(builddir)" $(SPHINXOPTS)
	@touch $(@)

$(stampdir) $(builddir) $(install_docdir):
	@mkdir -p $(@)

.PHONY: clean
clean:
	@echo ===== Cleaning $(MODULE)
	rm -rf $(builddir) $(stampdir)

.PHONY: help
help:
	+@$(SPHINXBUILD) -M help "$(CURDIR)" "$(builddir)" $(SPHINXOPTS)
