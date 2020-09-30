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

find ?= /usr/local/etc

d := tmp/ins
main: phony $d/3 | $d
$d:; mkdir $@

$d/1: $(self); find $(find) | grep -v ' ' > $@
$d/2: $d/1; < $< tr / ' ' | fmt -1 | sort | uniq | nl | awk '{print $$2 "/", $$1}' > $@
$d/3: f = f () { echo $$1 | tr / '\n' | xargs -i look {}/ $$2 | cut -d/ -f2 | xargs | tr ' ' /; }
$d/3: $d/1 $d/2; $f; (declare -f f; < $< xargs -i echo f {} $(word 2, $^)) | bash > $@
