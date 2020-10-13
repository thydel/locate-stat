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

lib := paths-cons-lib.jq
$(lib):;

find ?= /usr/local/etc
input := tmp/paths-cons-find.paths
$(input): $(self); find $(find) | sort > $@

deps := %.jq $(lib) $(self)
filter = < $< $($@) > $@

- := paths-to-cons
~ := tmp/$-.json
$~: jq = split("/")
$~: $~ = jq -R '$(jq)' | ./$*.jq
$~: tmp/%.json : $(input) $(deps); $(filter)

- := cons-to-paths
~ := tmp/$-.paths
$~: jq = join("/")
$~: $~ = $*.jq | jq -r '$(jq)'
$~: tmp/%.paths : tmp/paths-to-cons.json $(deps); $(filter)

to-cons: phony tmp/paths-to-cons.json
to-paths: phony tmp/cons-to-paths.paths
diff: phony to-paths; diff $(input) tmp/cons-to-paths.paths

main: diff

