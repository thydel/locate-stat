#!/usr/bin/make -f

MAKEFLAGS += -Rr --warn-undefined-variables
SHELL != which bash
.SHELLFLAGS := -euo pipefail -c

.ONESHELL:
.DELETE_ON_ERROR:
.PHONY: phony
_WS := $(eval ) #
_comma := ,
.RECIPEPREFIX := $(_WS)
.DEFAULT_GOAL := main

-: min := 4.1
-: msg := make $(MAKE_VERSION) < $(min)
-: - := $(and $(or $(filter $(min),$(firstword $(sort $(MAKE_VERSION) $(min)))),$(error $(msg))),)

self := $(lastword $(MAKEFILE_LIST))
$(self):;

€ = $(subst €,$$,$1)

~ := simple/% efficient/%
$~: seq = echo 10^$1 | bc -q | xargs seq
$~: time := time -f '%U %M'
$~: cmd  = (echo -n "10^$* " >&2;
$~: cmd += $(call seq,$*) | $(time) jq '$(call €,$(jq))' > /dev/null)
$~: cmd += |& cat
$~: phony; @$(cmd)

# The simple way

~ := simple
$~ := [inputs] | add
$~/%: jq := $($~)

# The efficient way

~ := efficient
$~ := reduce inputs as €i (0; . + €i)
$~/%: jq := $($~)

# Compare

compare := simple efficient
main: phony; @$(foreach _,$(compare),$(self) --no-print-directory $_ | (line; tail -n +1 | column -t);)

.SECONDEXPANSION:

range != seq 3 8
show/%: phony; @echo '$(call €,$($*))'
header: phony; @echo cnt time mem
simple efficient: phony show/$$@ header $(range:%=$$@/%);
