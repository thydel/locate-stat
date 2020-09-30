def path2array: split("/");
def array2path: join("/");

def array_as_dict: with_entries({ key: .value, value: .key});
def dict_as_array: to_entries | sort_by(.value) | map(.key);
def map_dict($d): map($d[.]);

# simple, but read all inputs at once

def name2index_map:
  . as $paths | flatten | sort | unique as $names
  | $names | array_as_dict as $name2index
  | $names, ($paths[] | map_dict($name2index));

# read input one by one, but keep all output till end of inputs

def name2index_reduce(f):
  def in_dict($n): if .dict | has($n) then . else .dict[$n] = .cnt | .cnt += 1 | . end;
  def to_dict($i): .dict as $d | $i | map($d[.]);
  def mk_dict($i): reduce $i[] as $n (.; in_dict($n)) | .paths += [to_dict($i)];
  reduce f as $i ({ cnt: 0 }; mk_dict($i)) | (.dict | dict_as_array), .paths[];

# read input one by one and build and output dict only, but will need
# a second pass to encode paths

def name2index_reduce_mkdict(f):
  def in_dict($n): if .dict | has($n) then . else .dict[$n] = .cnt | .cnt += 1 | . end;
  def mk_dict($i): reduce $i[] as $n (.; in_dict($n));
  reduce f as $i ({ cnt: 0 }; mk_dict($i)) | .dict;
