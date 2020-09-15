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

main: phony $(self) stat2json.json
stat2json.json: stat2json.awk $(self); awk --non-decimal-data -f $< -- $(STYLE) tmp/tst.stat > $@
stat2json.awk: stat2json.m4.awk; install -m 0444 <(m4 -P $<) $@

STYLE := -o
