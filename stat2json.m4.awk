@include "assert"
@include "getopt"
@include "join"

m4_define(`assert', ``assert'($1, "$1")')m4_dnl

func init_columns() {
    columns_name = "meta dev mount inode nlinks mode atime mtime ctime uname gname uid gid size path"
    columns_type = "dec  dev str   dec   dec    mode time  time  time  str   str   dec dec dec  path"
    columns_use = "meta dev mount inode nlinks mode times user group size path"
}

func init_merged_columns() {
    split("times user group", merged_name)

    cols["times"] = "atime mtime ctime"
    merged["times"] = cols["times"]

    cols["user"] = "uname uid"
    merged["user"] = "name uid"

    cols["group"] = "gname gid"
    merged["group"] = "name gid"
}

func init_args() {
    style = "json_array"
    path_sep = ":"
}

func init_vars() {
    quote = "\""
    comma = ","
    colon = ":"
    lsb = "["
    rsb = "]"
    lcb = "{"
    rcb = "}"
}

func init_arrays( nname, ntype, nuse, i) {
    nname = split(columns_name, col2name)
    ntype = split(columns_type, col2type)
    assert(nname == ntype);
    for (i = 1; i <= nname; ++i) name2col[col2name[i]] = i
}

func init_use() { split(columns_use, col2use) }

BEGIN {
    RS = "\0"
    init_columns()
    init_merged_columns()
    init_vars()
    init_args()
    init_arrays()
    parse_args()
    init_use()
}

func usage(n) { print n " [-o] [-s c] [-u cols]" > "/dev/stderr"; exit 1 }

func parse_args( c, i) {
    while ((c = getopt(ARGC, ARGV, "os:u:")) != -1) {
        if (c == "o")
            style = "json_object"
        else if (c == "s")
            path_sep = Optarg
        else if (c == "u")
            set_columns_use(Optarg)
        else
            usage(ARGV[0])
    }
    for (i = 1; i < Optind; i++)
        ARGV[i] = ""
}

func set_columns_use(s,  t, u, v, i) {
    split(s, t, "[ ,]")
    for (i in col2name) u[col2name[i]] = i
    for (i in merged_name) v[merged_name[i]] = i
    for (i in t)
        if (!(t[i] in u) && !(t[i] in v)) {
            print t[i] " neither in " joined(col2name, comma) " nor in " joined(merged_name, comma) > "/dev/stderr"
            exit 1
        } else columns_use = joined(t, " ")
}

func splitted(s, a,  i, n) {
    n = split(s, a)
    for (i = 1; i <= n; ++i) a[a[i]] = i
    return n
}

func split_item(a, i) { return a[a[i]] }

func map_splitted(f, a, b) { for (i = 1; i <= length(a) / 2; ++i) b[i] = @f(a, i) }

func joined(a, s) { return join(a, 1, length(a), s) }

func json_array(a,  t) {
    map_splitted("split_item", a, t)
    return lsb joined(t, comma) rsb
}

func json_item(a, i) { return quote a[i] quote colon a[a[i]] }

func json_object(a,  t) {
    map_splitted("json_item", a, t)
    return lcb joined(t, comma) rcb
}

func val(n) { return $n }
func dec(n) { return val(n) }
func str(n) { return quote val(n) quote }

func time(n,  m, t, u, i) {
    n = val(n)
    m = splitted("timestamp second minute hour day month fullyear weekday", t)
    splitted("              %S     %M     %H   %d  %m    %Y       %w", u)
    t[t[1]] = n
    for (i = 1; i < m; ++i) t[t[i + 1]] = strftime(u[i], n) + 0
    return @style(t)
}

func dev(n,  t) {
    n = val(n)
    splitted("major minor", t)
    t[t[1]] = rshift(n, 8)
    t[t[2]] = and(n, 0xff)
    return @style(t)
}

func bit(n, b) { return !!and(n + 0, lshift(1, b)) }

func mode(n,  t, i, j) {
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

func merge(n,  t, u, i, j) {
    split(merged[n], t)
    split(cols[n], u)
    for (i in u) {
        name = u[i]
        col = name2col[name]
        type = col2type[col]
        t[t[i]] = @type(col)
    }
    return @style(t)
}

# https://www.ietf.org/rfc/rfc4627.txt
# « All Unicode characters may be placed within the
#   quotation marks except for the characters that must be escaped:
#   quotation mark, reverse solidus, and the control characters (U+0000
#   through U+001F) »
BEGIN { init_quote_json_cntrl() }
func init_quote_json_cntrl( i) { for (i = 0; i < 256; ++i) ord[sprintf("%c", i)] = i }
func quote_json_cntrl(s,  t, i, a) {
    # [:cntrl:] also contain U+007F
    # So we may apply unneeded idempotent transformation
    if (match(s, "[[:cntrl:]]")) {
	split(s, a, "")
	for (i in a) t = t "" (ord[a[i]] < 32 ? sprintf("\\u%04X", ord[a[i]]) : a[i])
	return t
    }
    return s
}

func path(  r, s, q, a, n) {
    r = "[^:]*" path_sep "(.*)";
    s = "\\1";
    q = "\"";
    a = "\\\\";
    # Must replace \ before "
    return q quote_json_cntrl(gensub(q, a q, "g", gensub(a, a a, "g", gensub(r, s, 1)))) q
}

func main(  i, name, col, type, json) {
    for (i in col2use) {
	name = col2use[i]
        json[i] = name
        if (name in name2col) {
            col = name2col[name]
            type = col2type[col]
            json[name] = @type(col)
        } else {
            json[name] = merge(name)
        }
    }
    print @style(json)
}

$1 { main() }
!$1 && style == "json_array" { print lsb 0 comma quote $0 quote rsb }
!$1 && style == "json_object" {
    print lcb quote "meta" quote colon 0 comma quote "line" quote colon quote $0 quote rcb }

# Local Variables:
# indent-tabs-mode: nil
# mode: awk
# End:
