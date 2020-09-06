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

columns.name := meta dev mount inode nlinks mode atime mtime ctime uname gname uid gid size path
columns.type := dec  hex str   dec   dec    hex  time  time  time  str   str   dec dec dec  path
path.sep := :

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

~ := %.stat
$~: locate = locate -e0d $< /
$~: fmt := 1 0x%D %m %i %h 0x%f %X %Y %Z %U %G %u %g %s $(path.sep)%n\0
$~: stat = stat --printf='$(fmt)'
$~: cmd = $(locate) | xargs -r0 $(stat)
$~: %.db $(self); $(cmd) > $@

assert = assert($1, "$1")
item = quote $1 quote colon $2
define awk
function assert(condition, string)
{
  if (!condition) {
    printf("%s:%d: assertion failed: %s\n", FILENAME, FNR, string) > "/dev/stderr";
    _assert_exit = 1;
    exit 1
  }
}
BEGIN {
  RS = "\0";
  nname = split("$(columns.name)", col2name);
  ntype = split("$(columns.type)", col2type);
  $(call assert,nname == ntype);
  for (i = 1; i <= nname; ++i) name2col[col2name[i]] = i;
  nuse = split("$(columns.use)", col2use);
  $(call assert,nuse <= ntype);
  quote = "\"";
  comma = ",";
  colon = ":";
  lsb = "[";
  rsb = "]";
  lcb = "{";
  rcb = "}";
}
function val(n) { return €n }
function dec(n) { return val(n) }
function time(n) { return val(n) }
function str(n) { return quote val(n) quote }
function path(  r, s, q, a, n) {
  r = "[^:]*$(path.sep)(.*)";
  s = "\\1";
  q = "\"";
  a = "\\\\";
  n = "\n";
  return q gensub(n, a "n", "g", gensub(q, a q, "g", gensub(r, s, 1))) q
}
function array(a, s,  r) { for (i = 1; i < a[0] - 1; ++i) r = r a[a[i]] s; return lsb r a[a[i]] rsb }
function object(a, s,  r) {
  for (i = 1; i < a[0] - 1; ++i) r = r $(call item, a[i], a[a[i]]) s;
  return lcb r $(call item, a[i], a[a[i]]) rcb
}
{
  for (i in col2use) {
    name = col2use[i];
    col = name2col[name];
    type = col2type[col];
    json[i] = name;
    json[name] = @type(col);
  }
  json[0] = ++i;
  print $1(json, comma)
}
END {
  if (_assert_exit) exit 1
}
endef


ifdef OBJECT
json := object
else
json := array
endif

~ := %.json
$~: cmd = awk '$(strip $(call €, $(call awk, $(json))))'
$~: %.stat $(self); < $< $(cmd) > $@
ifdef TEST
$~: %.stat $(self); @< $< head -zn 2 | $(cmd)
endif

stat: tmp/tst.stat
json: tmp/tst.json

main: json
