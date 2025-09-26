# Remove all makefile variables defined by make command line to prevent from
# confliting with internal project makefiles.
MAKEOVERRIDES :=

bstrap_targets        =
stage_targets         =
final_targets         =
all_targets           = $(bstrap_targets) $(stage_targets) $(final_targets)
stage_check_targets   =
final_check_targets   =
check_targets         = $(stage_check_targets) $(final_check_targets)

.PHONY: setup
setup: setup-sigs

.PHONY: setup-sigs
setup-sigs: | $(OUTDIR)/stamp/pkgs-setup $(FETCHDIR)
	$(call setup_sigs_cmds)

.PHONY: prepare
prepare: setup-pkgs

.PHONY: setup-pkgs
setup-pkgs:
	$(call setup_pkgs_cmds)

$(OUTDIR)/stamp/pkgs-setup: | $(OUTDIR)/stamp
	$(call setup_pkgs_cmds)
	$(call touch,$(@))

.PHONY: fetch
fetch:

.PHONY: xtract
xtract:

.PHONY: clobber
clobber:
	$(call rmrf,$(srcdir))
	if [ -d "$(builddir)" ]; then \
		$(FIND) $(builddir)/ \
		        -mindepth 1 \
		        -maxdepth 1 \
		        -type d \
		        -exec rm -rf {} \; ; \
	fi
	$(call rmrf,$(installdir))
	$(call rmrf,$(bstrapdir))
	$(call rmrf,$(stagedir))
	$(call rmrf,$(finaldir))
	$(call rmrf,$(debdir))
	if [ -d "$(stampdir)" ]; then \
		$(FIND) $(stampdir)/ \
		        -mindepth 1 \
		        -maxdepth 1 \
		        -type d \
		        -exec rm -rf {} \; ; \
	fi

.PHONY: check
check:

.PHONY: mrproper
mrproper:
	$(call rmrf,$(OUTDIR))

define deps_rule
$(stampdir)/$(strip $(1))/configured: \
	$(foreach m,$(2),$(stampdir)/$(m)/installed)

.PHONY: show-$(strip $(1))-deps
show-$(strip $(1))-deps:
	@$(foreach m,$(sort $(2)),echo $(m);)
endef

# $(1): module name
# $(2): list of modules $(1) depends on
define gen_deps
$(eval $(call deps_rule,$(1),$(2)))
endef

define check_deps_rule
check-$(strip $(1)): \
	$(foreach m,$(2),$(stampdir)/$(m)/installed)
endef

# $(1): module name
# $(2): list of modules $(1) check recipes depend on
define gen_check_deps
$(eval $(call check_deps_rule,$(1),$(2)))
endef

define fetch_rules
.PHONY: fetch-$(strip $(1))
fetch-$(strip $(1)): $(FETCHDIR)/$($(strip $(2)))
$(FETCHDIR)/$($(strip $(2))): | $(OUTDIR)/stamp/pkgs-setup $(FETCHDIR)
	$$(call log,$(1),fetching)
ifeq ($(OFFLINE),)
	$$($(strip $(3)))
	@touch $$(@)
else
	echo "$$(@): cannot download missing file: OFFLINE mode enabled!"  >&2; \
	exit 1
endif

fetch: fetch-$(strip $(1))

$(stampdir)/$(strip $(1))/xtracted: $(FETCHDIR)/$($(strip $(2)))
endef

# $(1): module name
# $(2): name of variable holding the fetched distribution tarball basename
# $(3): fetch recipe variable name
define gen_fetch_rules
$(eval $(call fetch_rules,$(1),$(2),$(3)))
endef

define xtract_rules
.PHONY: xtract-$(strip $(1))
xtract-$(strip $(1)): $(stampdir)/$(strip $(1))/xtracted
$(stampdir)/$(strip $(1))/xtracted: | $(stampdir)/$(strip $(1))
	$$(call log,$(1),extracting)
	$$($(strip $(2)))
	@touch $$(@)

xtract: xtract-$(strip $(1))
endef

# $(1): module name
# $(2): xtract recipe variable name
define gen_xtract_rules
$(eval $(call xtract_rules,$(1),$(2)))
endef

define config_rules
.PHONY: config-$(strip $(1))
config-$(strip $(1)): $(stampdir)/$(strip $(1))/configured
$(stampdir)/$(strip $(1))/configured: $(stampdir)/$(strip $(1))/xtracted \
                                      | $(builddir)/$(strip $(1))
	$$(call log,$(1),configuring)
	$(if $(strip $(2)),$$($(strip $(2))))
	@touch $$(@)
endef

# $(1): module name
# $(2): config recipe variable name
define gen_config_rules
$(eval $(call config_rules,$(1),$(2)))
endef

define config_rules_with_dep
.PHONY: config-$(strip $(1))
config-$(strip $(1)): $(stampdir)/$(strip $(1))/configured
$(stampdir)/$(strip $(1))/configured: $(stampdir)/$(strip $(2))/xtracted \
                                      | $(builddir)/$(strip $(1)) \
                                        $(stampdir)/$(strip $(1))
	$$(call log,$(1),configuring)
	$(if $(strip $(3)),$$($(strip $(3))))
	@touch $$(@)
endef

# $(1): module name
# $(2): name of xtract module these config rules will depend on
# $(3): config recipe variable name
define gen_config_rules_with_dep
$(eval $(call config_rules_with_dep,$(1),$(2),$(3)))
endef

define clobber_rules
.PHONY: clobber-$(strip $(1))
clobber-$(strip $(1)): uninstall-$(strip $(1))
	$$(call log,$(1),clobbering)
	$$($(strip $(2)))
	$(RM) -r $(builddir)/$(strip $(1))
	$(RM) -r $(stampdir)/$(strip $(1))
endef

# $(1): module name
# $(2): clobber recipe variable name
define gen_clobber_rules
$(eval $(call clobber_rules,$(1),$(2)))
endef

define build_rules
.PHONY: build-$(strip $(1))
build-$(strip $(1)): $(stampdir)/$(strip $(1))/built
$(stampdir)/$(strip $(1))/built: $(stampdir)/$(strip $(1))/configured
	$$(call log,$(1),building)
	$$($(strip $(2)))
	@touch $$(@)
endef

# $(1): module name
# $(2): build recipe variable name
define gen_build_rules
$(eval $(call build_rules,$(1),$(2)))
endef

define clean_rules
.PHONY: clean-$(strip $(1))
clean-$(strip $(1)): uninstall-$(strip $(1))
	$$(call log,$(1),cleaning)
	$$(if $$(realpath $(builddir)/$(strip $(1))),$$($(strip $(2))))
	$(RM) "$(stampdir)/$(strip $(1))/built"
endef

# $(1): module name
# $(2): clean recipe variable name
define gen_clean_rules
$(eval $(call clean_rules,$(1),$(2)))
endef

define install_rules
bstrap_targets += $(filter bstrap-%,$(strip $(1)))
stage_targets += $(filter stage-%,$(strip $(1)))
final_targets += $(filter final-%,$(strip $(1)))

.PHONY: $(strip $(1)) install-$(strip $(1))
$(strip $(1)) install-$(strip $(1)): $(stampdir)/$(strip $(1))/installed
$(stampdir)/$(strip $(1))/installed: $(stampdir)/$(strip $(1))/built \
                                     | $(stagedir) $(installdir)/$(strip $(1))
	$$(call log,$(1),installing)
	$$($(strip $(2)))
	@touch $$(@)

install: install-$(strip $(1))
endef

# $(1): module name
# $(2): install recipe variable name
define gen_install_rules
$(eval $(call install_rules,$(1),$(2)))
endef

define uninstall_rules
.PHONY: uninstall-$(strip $(1))
uninstall-$(strip $(1)):
	$$(call log,$(1),uninstalling)
	$$(if $$(realpath $(builddir)/$(strip $(1))),$$($(strip $(2))))
	$(RM) "$(stampdir)/$(strip $(1))/installed"
endef

# $(1): module name
# $(2): uninstall recipe variable name
define gen_uninstall_rules
$(eval $(call uninstall_rules,$(1),$(2)))
endef

define check_rules
stage_check_targets += $(patsubst %,check-%,$(filter stage-%,$(strip $(1))))
final_check_targets += $(patsubst %,check-%,$(filter final-%,$(strip $(1))))

.PHONY: check-$(strip $(1))
check-$(strip $(1)): $(stampdir)/$(strip $(1))/built
	$$(call log,$(1),checking)
	$$($(strip $(2)))
endef

# $(1): module name
# $(2): checking recipe variable name
define gen_check_rules
$(eval $(call check_rules,$(1),$(2)))
endef

define no_check_rules
.PHONY: check-$(strip $(1))
check-$(strip $(1)): $(stampdir)/$(strip $(1))/built
	$$(call log,$(1),checking)
ifeq ($(strip $(2)),)
	@printf "No check rull for $(strip $(1))\n"
else
	@printf "$(strip $(2))\n"
endif
endef

# $(1): module name
# $(2): Custom message
define gen_no_check_rules
$(eval $(call no_check_rules,$(1),$(2)))
endef

define dir_rules
$(stampdir)/$(strip $(1)) $(builddir)/$(strip $(1)) $(installdir)/$(strip $(1)):
	@$(call mkdir,$$(@))
endef

# $(1): module name
define gen_dir_rules
$(eval $(call dir_rules,$(1)))
endef

$(finaldir) $(stagedir) $(OUTDIR)/stamp $(FETCHDIR):
	@$(call mkdir,$(@))
