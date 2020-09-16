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

ifdef NEVER
tst: phony $(self) stat2json.json
stat2json.json: stat2json.awk $(self); awk -nf $< -- $(STYLE) tmp/tst.stat > $@
stat2json.awk: stat2json.m4.awk; install -m 0444 <(m4 -P $<) $@
endif

~ := %.json.gz
$~: unzip = zcat $<
$~: awk = awk -nf <(m4 -P stat2json.m4.awk) -- $(STYLE)
$~: rezip = gzip --rsyncable
$~: write = dd of=$@ 2> /dev/null
$~: cmd = $(unzip) | $(awk) | $(rezip) | $(write)
%.json.gz: %.stat.gz $(self); $(cmd)

main: phony /var/lib/mlocate/mlocate.json.gz
tst: phony tmp/tst.json.gz

opts := obj

STYLE :=
obj  := STYLE := -o

$(opts):; @: $(eval $($@))
