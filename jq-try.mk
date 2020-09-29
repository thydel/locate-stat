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

define results
{ s += $1 } END { print s }
cnt   time   mem
10^3  0.00   3352  500500
10^4  0.00   3332  50005000
10^5  0.02   3528  5000050000
10^6  0.22   3576  500000500000
10^7  2.35   3468  50000005000000
10^8  23.17  3228  5000000050000000
[inputs] | add
cnt   time   mem
10^3  0.02   2016     500500
10^4  0.03   2476     50005000
10^5  0.08   5156     5000050000
10^6  0.70   24156    500000500000
10^7  6.72   251444   50000005000000
10^8  67.80  2838708  5000000050000000
reduce inputs as $i (0; . + $i)
cnt   time   mem
10^3  0.02   1980  500500
10^4  0.02   2032  50005000
10^5  0.07   2032  5000050000
10^6  0.57   2028  500000500000
10^7  5.44   2028  50000005000000
10^8  56.56  2028  5000000050000000
endef

€ = $(subst €,$$,$1)

~ := awk/%
$~: with = awk '$(awk)'

~ := bc/%
$~: with = $(bc) | bc -q

~ := simple/% efficient/%
$~: with = jq -n '$(call €,$(jq))'

~ := simple/% efficient/% awk/% bc/%
$~: seq = echo 10^$1 | bc -q | xargs seq
$~: time := time -f '%U %M'
$~: cmd  = (echo -n "10^$* ";
$~: cmd += $(call seq,$*) | (r=$$(command $(time) $(with)); echo $$r))
$~: cmd += |& xargs
$~: phony; @$(cmd)

# AWK

~ := awk
$~ := { s += $$1 } END { print s }
$~/%: awk := $($~)

# bc

~ := bc
$~ := xargs -i echo {} + | cat - <(echo 0) | xargs
$~/%: bc := $($~)

# jq, the simple way

~ := simple
$~ := [inputs] | add
$~/%: jq := $($~)

# jq, the efficient way

~ := efficient
$~ := reduce inputs as €i (0; . + €i)
$~/%: jq := $($~)

# Compare

compare := awk simple efficient
main: phony; @$(foreach _,$(compare),$(self) --no-print-directory $_ | (line; tail -n +1 | column -t);)

.SECONDEXPANSION:

max ?= 6
range != seq 3 $(max)
show/%: phony; @echo '$(call €,$($*))'
header: phony; @echo cnt time mem
$(compare): phony show/$$@ header $(range:%=$$@/%);
