#!/usr/local/bin/jq -cnf

include "paths-cons-lib";

reduce inputs as $path ({ cnt: 0 }; mkdict($path; .) | .paths += [.ret]) | { paths, conses }
