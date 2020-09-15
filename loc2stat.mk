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

path.sep := :
stat.fields :=       0x%D %m   %i    %h     0x%f %X    %Y    %Z    %U    %G    %u  %g  %s $(path.sep)%n\0
columns.name := meta dev mount inode nlinks mode atime mtime ctime uname gname uid gid size path
columns.type := dec  hex str   dec   dec    hex  time  time  time  str   str   dec dec dec  path

columns.use := meta mount inode nlinks atime mtime ctime uname gname uid gid path

~ := cols
ifeq ($(MAKECMDGOALS),$~)
$~: names = $(columns.name)
$~: cnt = $(words $(names))
$~: types = $(columns.type)
$~: $~ = (seq $(cnt) | xargs; echo $(names); echo $(types)) | column -t
$~: phony; @$($@)
endif

# $(self) cols
# 1     2    3      4      5       6     7      8      9      10     11     12   13   14    15
# meta  dev  mount  inode  nlinks  mode  atime  mtine  ctime  uname  gname  uid  gid  size  path
# dec   hex  str    dec    dec     hex   time   time   time   str    str    dec  dec  dec   path

~ := %.stat.gz
$~: ldb = $<
$~: out = $@
$~: id != id -u
$~: root? = $(filter $(id),0)
$~: sudo = $(if $(root?),sudo,env)
$~: visible = $(sudo) chmod o+r $(ldb)
$~: invisible = $(sudo) chmod o-r $(ldb)
$~: nice := nice -19
$~: ionice := ionice -c3
$~: niceload := niceload -L 2
$~: pattern := /
$~: locate = ($(visible); $(niceload) locate -e0d $(ldb) $(pattern); $(invisible))
$~: fmt = 0x%D %m %i %h 0x%f %X %Y %Z %U %G %u %g %s $(path.sep)%n\0
$~: head = 0 1 $(fmt)
$~: names = 0 2 $(columns.name)
$~: types = 0 3 $(columns.type)
$~: headers = head names types
$~: header = $(foreach _,$(headers),echo '$($_)'; )
$~: printf = 1 $(fmt)
$~: stat = stat --printf='$(printf)'
$~: stats = $(nice) $(ionice) $(sudo) xargs -r0 $(stat)
$~: compress := gzip --rsyncable
$~: write = $(sudo) dd of=$(out)
$~: cmd = ($(header) ($(locate) | $(stats))) | $(compress) | $(write)
$~: %.db $(self); $(strip $(cmd))

main: phony /var/lib/mlocate/mlocate.stat.gz
tst: phony tmp/tst.stat.gz

# Local Variables:
# indent-tabs-mode: nil
# End:
