MODULE := doc
include $(TOPDIR)/utils.mk

SPHINXBUILD := sphinx-build
SPHINXOPTS  := -a -j 1 -D version="$(VERSION)" -D release="$(VERSION)"

install_docdir := $(DESTDIR)$(prefix)/share/doc/xtchain

.PHONY: install
install: $(stampdir)/installed

$(stampdir)/installed: $(stampdir)/built | $(install_docdir)/html
	@echo ===== Installing $(MODULE)
	rsync -rlpt $(builddir)/html/ $(install_docdir)/html
	install -m644 \
	        $(builddir)/latex/xtchain.pdf \
	        $(install_docdir)/xtchain.pdf
	@touch $(@)

.PHONY: build
build: $(stampdir)/built

.PHONY: $(stampdir)/built
$(stampdir)/built: | $(stampdir) $(builddir)
	@echo ===== Building $(MODULE)
	+@$(SPHINXBUILD) -M html "$(CURDIR)" "$(builddir)" $(SPHINXOPTS)
	+@$(SPHINXBUILD) -M latexpdf "$(CURDIR)" "$(builddir)" $(SPHINXOPTS)
	@touch $(@)

$(stampdir) $(builddir) $(install_docdir)/html:
	@mkdir -p $(@)

.PHONY: clean
clean:
	@echo ===== Cleaning $(MODULE)
	rm -rf $(builddir) $(stampdir)

.PHONY: help
help:
	+@$(SPHINXBUILD) -M help "$(CURDIR)" "$(builddir)" $(SPHINXOPTS)
