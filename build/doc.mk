SPHINXOPTS   := -a -j 1 \
                -D version="$(version)" \
                -D release="$(version)"
sphinx_build := $(stagedir)/bin/sphinx-build

.PHONY: doc
doc: build-html

.PHONY: build-html
build-html: $(OUTDIR)/stamp/doc/html-built

.PHONY: $(OUTDIR)/stamp/doc/html-built
$(OUTDIR)/stamp/doc/html-built: stage-sphinx-rtd-theme stage-texinfo \
                                $(OUTDIR)/doc/generated/packages.rst \
                                | $(OUTDIR)/stamp/doc $(OUTDIR)/doc/src
	$(call log,html,building)
	$(Q)$(call mirror_cmd,$(CURDIR)/doc,$(OUTDIR)/doc/src)
	$(Q)$(sphinx_build) -b html \
	                    "$(OUTDIR)/doc/src" \
	                    "$(OUTDIR)/doc/html" \
	                    $(SPHINXOPTS) \
	                    $(if $(V),-v,-q)
	@touch $(@)

define rst_underln
$(shell len=$$(($$(echo '$(1)' | wc --chars)-1)); \
        printf "%$${len}.$${len}s\n" \
               '**************************************************************')
endef

define _pkg_rst_doc

$(1)
$(call rst_underln,$(1))

$(if $(2),$(2),??)

:Version: $(if $(3),$(3),??)
:Homepage: $(if $(4),$(4),??)
$(if $(5),

$(5)
)
endef

define pkg_rst_doc
$(call _pkg_rst_doc,$(1),$($(1)_brief),$($(1)_vers),$($(1)_home),$($(1)_desc))
endef

define echo_multi_line
$(ECHOE) -n $$'$(subst $(newline),\n,$(1))'
endef

# A target that generates final modules informations formatted for inclusion
# inside the reStructuredText csv-table found into doc/user.rst file.
$(OUTDIR)/doc/generated/packages.rst: SHELL := bash
$(OUTDIR)/doc/generated/packages.rst: build/doc.mk \
                                      $(module_mkfiles) \
                                      | $(OUTDIR)/doc/generated
	$(Q)echo 'Packages' > $(@)
	$(Q)echo '########' >> $(@)
	$(Q)echo >> $(@)
	$(Q)echo 'HtChain provides the following tools:' >> $(@)
	$(Q)echo >> $(@)
	$(Q)echo '.. csv-table::' >> $(@)
	$(Q)echo '   :header: "Package", "Version", "Description"' >> $(@)
	$(Q)echo >> $(@)
	$(Q)$(foreach t,\
	              $(sort $(subst final-,,$(final_targets))),\
	              echo $$'   "$(t)_", "$($(t)_vers)", "$($(t)_brief)"' \
	              >> $(@)$(newline))
	$(foreach t,\
	          $(sort $(subst final-,,$(final_targets))),\
	          $(Q)$(call echo_multi_line,$(call pkg_rst_doc,$(t))) \
	          >> $(@)$(newline))

.PHONY: clean-doc
clean-doc:
	$(call log,$(subst clean-,,$(@)),cleaning)
	$(Q)$(RM) -r "$(OUTDIR)/doc"
	$(Q)$(RM) -r "$(OUTDIR)/stamp/doc"

.PHONY: clean-html
clean-html:
	$(call log,$(subst clean-,,$(@)),cleaning)
	$(Q)$(RM) -r "$(OUTDIR)/doc/html"
	$(Q)$(RM) "$(OUTDIR)/stamp/doc/html-built"

$(OUTDIR)/stamp/doc $(OUTDIR)/doc/src $(OUTDIR)/doc/generated:
	@mkdir -p $(@)
