#!/usr/bin/make -f

MAKEFLAGS += -Rr --warn-undefined-variables
SHELL != which bash
.SHELLFLAGS := -euo pipefail -c

.ONESHELL:
.DELETE_ON_ERROR:
.PHONY: phony
_WS := $(or) $(or)
_comma := ,
.RECIPEPREFIX := $(_WS)
.DEFAULT_GOAL := main

self := $(lastword $(MAKEFILE_LIST))
$(self):;

N := 4
n != seq $N
tmp := tmp
tstd := $(tmp)/tst
dirs := $(n:%=$(tstd)/dir%)
files := $(foreach _,$(dirs),$(n:%=$_/file%))
fifod := $(tstd)/fifo
fifos := $(n:%=$(fifod)/fifo%)

. := dirs
~ := $($.)
$~: | $(tstd); mkdir $@
$.: phony $~

. := files
~ := $($.)
$~: n := 4
$~: | $(dirs); seq $$(($$RANDOM % $n)) | xargs -i date > $@
$.: phony $~

. := fifos
~ := $($.)
$~: | $(fifod); mkfifo $@
$(fifod): | $(tstd); mkdir $@
$.: phony $~

. := weird
define $.
.stone
name with space
name with "quote"
name with LF\\nsecond line
endef
~d := $(tstd)/$.
~ := $(~d)/.stone
weirds := $~
$~: cmd = while read l; do echo touch $|/\$$$${l@Q}; done
$~: $~ = cat <<<'$($(*F))' | $(cmd) | bash
$~: %/.stone : | %; @$($@)
$(~d):; mkdir $@
$.: phony $~

$(tstd):; mkdir -p $@
$(tstd)/.stone: $(files) $(fifos) $(weirds)
tstd: phony $(tstd)/.stone
$(tstd)/.stone:; touch $@

$(tmp)/tst.db: | $(tstd); updatedb -o $@ -U $| -l 1
db: $(tmp)/tst.db

main: phony db

define first
sudo adduser $$USER mlocate
newgrp mlocate
endef
first: phony; @cat <<<'$($@)'
