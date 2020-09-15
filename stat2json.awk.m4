#!/bin/sh
#exec awk "$(m4 "$0")" "$@"
#!/usr/bin/awk -f

m4_define(`columns_name',
          `"meta dev mount inode nlinks mode atime mtime ctime uname gname uid gid size path"')m4_dnl
m4_define(`columns_type',
          `"dec  dev str   dec   dec    mode time  time  time  user  group dec dec dec  path"')m4_dnl
m4_dnl
m4_define(`columns_use', `"meta dev mount inode nlinks mode atime mtime ctime uname gname uid gid path"')m4_dnl

@include "assert"
@include "getopt"
@include "join"

m4_define(`assert', ``assert'($1, "$1")')m4_dnl

function usage(n) {
    print n " [-o] [-s c]" > "/dev/stderr"
    exit 1
}

function parse_args() {
    while ((c = getopt(ARGC, ARGV, "os:")) != -1) {
        if (c == "o")
            style = "json_object"
        else if (c == "s")
            path_sep = Optarg
        else
            usage(ARGV[0])
    }
    for (i = 1; i < Optind; i++)
        ARGV[i] = ""
}    

function splitted(s, a,  i, n) {
    n = split(s, a)
    for (i = 1; i <= n; ++i) {
        a[a[i]] = i
    }
}

function split_item(a, i) {
    return a[a[i]]
}

function map_splitted(f, a, b) {
    for (i = 1; i <= length(a) / 2; ++i) {
        b[i] = @f(a, i)
    }
}

function joined(a, s) {
    return join(a, 1, length(a), s)
}

function json_array(a,  t) {
    map_splitted("split_item", a, t)
    return lsb joined(t, comma) rsb
}

function json_item(a, i) {
    return quote a[i] quote colon a[a[i]]
}

function json_object(a,  t) {
    map_splitted("json_item", a, t)
    return lcb joined(t, comma) rcb
}

function init_args() {
    style = "json_array"
    path_sep = ":"
}

function init_vars() {
    quote = "\""
    comma = ","
    colon = ":"
    lsb = "["
    rsb = "]"
    lcb = "{"
    rcb = "}"
}

function init_arrays() {
    nname = split(columns_name(), col2name);
    ntype = split(columns_type(), col2type);
    assert(nname == ntype);
    for (i = 1; i <= nname; ++i) name2col[col2name[i]] = i;
    nuse = split(columns_use(), col2use);
    assert(nuse <= ntype);
}

BEGIN {
    RS = "\0"
    init_vars()
    init_args()
    parse_args()
    init_arrays()
}

function val(n) { return $n }
function dec(n) { return val(n) }
function time(n) { return val(n) }
function str(n) { return quote val(n) quote }

function dev(n,  t) {
    n = val(n)
    splitted("major minor", t)
    t[t[1]] = rshift(n, 8)
    t[t[2]] = and(n, 0xff)
    return @style(t)
}

function bit(n, b) {
    return !!and(n + 0, lshift(1, b))
}

function mode(n,  t, i, j) {
    n = val(n)
    splitted("type suid sgid sticky mode", t)
    i = 1
    t[t[i++]] = sprintf("%o", rshift(and(n, 0170000), 12))
    for (j = 1; j < 4; ++j) {
        t[t[i++]] = bit(n, 12 - j)
    }
    t[t[i++]] = sprintf("%o", and(n, 0777))
    return @style(t)
}

function user_or_group(n, s,  t) {
    splitted(s, t)
    t[t[1]] = val(n)
    t[t[2]] = val(n + 2)
    return @style(t)
}

function user(n) {
    return user_or_group(n, "name uid")
}

function group(n) {
    return user_or_group(n, "group gid")
}

function path(  r, s, q, a, n) {
    r = "[^:]*" path_sep "(.*)";
    s = "\\1";
    q = "\"";
    a = "\\\\";
    n = "\n";
    return q gensub(n, a "n", "g", gensub(q, a q, "g", gensub(r, s, 1))) q
}

function main() {
    for (i in col2use) {
	name = col2use[i]
	col = name2col[name]
	type = col2type[col]
	json[i] = name
	json[name] = @type(col)
    }
    json[0] = i + 1
    print @style(json)
}

{
    main()
}

# Local Variables:
# indent-tabs-mode: nil
# mode: awk
# End:
