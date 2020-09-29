€ = $(subst €,$$,$1)

define paths
  . as €index2name
  | inputs[]
  | map(€index2name[.])
  | join("/")
endef

define files
  . as €paths
  | flatten | sort | unique
  | with_entries({ key: .value, value: .key}) as €name2index
  | €paths | map(map(€name2index[.])) as €indexed_paths
  | €name2index | to_entries | sort_by(.value) | map(.key) as €index2name
  | €index2name, €indexed_paths
endef

define files_alt
  reduce inputs as $i ( [ {},
endef

jq = $(strip $(call €, $($(basename $@))))

diff: find.txt paths.txt; diff $^

paths.txt: files.json; < $< jq -r '$(jq)' > $@

files.json: find.json; < $< jq -sc '$(jq)' > $@

find.json: find.txt; < $< jq -Rc 'split("/")' > $@

find := /usr/local
find := ~/usr
find.txt: Makefile; find $(find) > $@
