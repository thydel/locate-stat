#!/usr/local/bin/jq -nrf

include "index-name-lib";

input as $d | inputs | map_dict($d) | array2path
