#!/usr/bin/make -f

MAKEFLAGS += -Rr --warn-undefined-variables
SHELL != which bash
.SHELLFLAGS := -euo pipefail -c

.ONESHELL:
.DELETE_ON_ERROR:
.PHONY: phony
_WS :=
_WS +=
_comma := ,
.RECIPEPREFIX := $(_WS)
.DEFAULT_GOAL := main

self := $(lastword $(MAKEFILE_LIST))
$(self):;

€ = $(subst €,$$,$1)

columns := meta dev mount inode nlinks mode atime mtine ctime uname gname uid gid size path
pathsep := :

~ := cols
ifeq ($(MAKECMDGOALS),$~)
$~: names = $(columns)
$~: cnt = $(words $(names))
$~: $~ = (seq $(cnt) | xargs; echo $(names)) | column -t
$~: phony; @$($@)
endif

# $(self) cols
# 1     2    3      4      5       6     7      8      9      10     11     12   13   14    15
# meta  dev  mount  inode  nlinks  mode  atime  mtine  ctime  uname  gname  uid  gid  size  path

~ := %.stat
$~: locate = locate -e0d $< /
$~: fmt := 1 0x%D %m %i %h 0x%f %X %Y %Z %U %G %u %g %s $(pathsep)%n\0
$~: stat = stat --printf='$(fmt)'
$~: cmd = $(locate) | xargs -r0 $(stat)
$~: %.db $(self); $(cmd) > $@

define awk
BEGIN {
 RS = "\0";
 ncol = split("$(columns)", col2name);
 for (i = 1; i <= ncol; ++i) name2col[col2name[i]] = i;
}
function path(  r, s, q, a) {
 r = "[^:]*$(pathsep)(.*)";
 s = "\\1";
 q = "\"";
 a = "\\\\";
 n = "\n";
 return q gensub(n, a "n", "g", gensub(q, a q, "g", gensub(r, s, 1))) q
}
function val(n) { return €name2col[n] }
{
 l = "[";
 c = ",";
 r = "]";
 print l val("uname") c val("gname") c val("size") c path() r
}
endef

~ := %.awk
$~: %.stat $(self); < $< awk '$(strip $(call €, $(awk)))' > $@

stat: tmp/tst.stat
awk: tmp/tst.awk

main: awk

