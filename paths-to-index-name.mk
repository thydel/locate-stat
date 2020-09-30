top: all

find ?= /usr/local/etc

tmp/find.paths: Makefile; find $(find) | sort > $@
all += tmp/find.paths

tmp/find.json: tmp/find.paths; jq -R . $< > $@
find: tmp/find.json

paths-to-index-name.jq: index-name-lib.jq

p2i := paths-to-index-name.jq tmp/find.json

tmp/map.json: $(p2i); env what=map $^ > $@
map: tmp/map.json

tmp/reduce.json: $(p2i); env what=reduce $^ > $@
reduce: tmp/reduce.json

tmp/dict.json: $(p2i); env what=mkdict $^ > $@
dict: tmp/dict.json

tmp/paths.json: $(p2i); env what=paths $^ > $@
paths: tmp/paths.json

tmp/2pass.json: paths-to-index-name.jq tmp/dict.json tmp/paths.json; env what=2pass $^ > $@

tmp/map.paths: index-name-to-paths.jq tmp/map.json; $^ > $@
all += tmp/map.paths

tmp/reduce.paths: index-name-to-paths.jq tmp/reduce.json; $^ > $@
all += tmp/reduce.paths

tmp/2pass.paths: index-name-to-paths.jq tmp/2pass.json; $^ > $@
all += tmp/2pass.paths

all: $(all); sum $^ | cut -d' ' -f1 | sort -u | wc -l | xargs -i test {} -eq 1
