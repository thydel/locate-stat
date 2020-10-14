#!/usr/local/bin/jq -cnf

include "paths-cons-lib";

[inputs] | reduce .[] as $path ({ cnt: 0 }; mkdict($path; .) | .paths += [.ret]) | { paths, conses }
