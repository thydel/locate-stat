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

main: phony all

SMALL :=

ifdef SMALL
find ?= /usr/local/etc
tmp := tmp/small
else
find ?= /usr/local
tmp := tmp/medium
endif

time.cmd != which time
time = $(time.cmd) -o $@.time -f '%C\nElapsed\tMax mem\n%e\t%M'

tmp/small tmp/medium:; mkdir -p $@

$(tmp)/find.paths: Makefile | $(tmp); find $(find) | sort > $@
all += $(tmp)/find.paths

$(tmp)/find.json: $(tmp)/find.paths | $(tmp); $(time) jq -R . $< > $@
find: $(tmp)/find.json

paths-to-index-name.jq: index-name-lib.jq

p2i := paths-to-index-name.jq $(tmp)/find.json | $(tmp)

$(tmp)/map.json: $(p2i); env what=map $(time) $^ > $@
map: $(tmp)/map.json

$(tmp)/reduce.json: $(p2i); env what=reduce $(time) $^ > $@
reduce: $(tmp)/reduce.json

$(tmp)/dict.json: $(p2i); env what=mkdict $(time) $^ > $@
dict: $(tmp)/dict.json

$(tmp)/paths.json: $(p2i); env what=paths $(time) $^ > $@
paths: $(tmp)/paths.json

$(tmp)/2pass.json: paths-to-index-name.jq $(tmp)/dict.json $(tmp)/paths.json | $(tmp); env what=2pass $(time) $^ > $@

$(tmp)/map.paths: index-name-to-paths.jq $(tmp)/map.json | $(tmp); $(time) $^ > $@
all += $(tmp)/map.paths

$(tmp)/reduce.paths: index-name-to-paths.jq $(tmp)/reduce.json | $(tmp); $(time) $^ > $@
all += $(tmp)/reduce.paths

$(tmp)/2pass.paths: index-name-to-paths.jq $(tmp)/2pass.json | $(tmp); $(time) $^ > $@
all += $(tmp)/2pass.paths

all: $(all); sum $^ | cut -d' ' -f1 | sort -u | wc -l | xargs -i test {} -eq 1
