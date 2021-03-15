MODULE := doc
include $(TOPDIR)/utils.mk

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = XtChain

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(CURDIR)" "$(builddir)" $(SPHINXOPTS) $(O)

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
.PHONY: build
build: $(stampdir)/built

.PHONY: $(stampdir)/built
$(stampdir)/built: | $(stampdir) $(builddir)
	@echo ===== Building $(MODULE)
	@$(SPHINXBUILD) -M html "$(CURDIR)" "$(builddir)" $(SPHINXOPTS) $(O)
	@touch $(@)

$(stampdir) $(builddir):
	@mkdir -p $(@)

.PHONY: clean
clean:
	@echo ===== Cleaning $(MODULE)
	rm -rf $(builddir) $(stampdir)
