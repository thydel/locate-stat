#!/usr/local/bin/jq -ncf

include "index-name-lib";

if env.what == "map" then [inputs] | map(path2array) | name2index_map
elif env.what == "reduce" then name2index_reduce(inputs | path2array)
elif env.what == "mkdict" then name2index_reduce_mkdict(inputs | path2array)
elif env.what == "paths" then inputs | path2array
elif env.what == "2pass" then input as $d | ($d | dict_as_array), (inputs | map_dict($d))
else empty end
