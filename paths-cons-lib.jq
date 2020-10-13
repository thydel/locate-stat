def pair2key: map(tostring) | join(".");

def indict($pair; $dict):
  $pair | pair2key as $key
  | if ($dict | .index | has($key))
    then $dict | .ret = .index[$key]
    else $dict | .ret = .cnt | .index[$key] = .ret | .cnt += 1 | .conses += [$pair]
    end;

def mkdict($path; $dict):
  if $path | length == 1
  then indict([-1] + $path; $dict)
  else
    mkdict($path[:-1]; $dict) as $butlast
    | mkdict($path[-1:]; $butlast) as $last
    | indict([($butlast | .ret), ($last | .ret)]; $last)
  end;

def frompath($conses):
  $conses[.] as $cons | $cons[0] as $car | $cons[1] as $cdr |
  if $car == -1
  then [ $cdr ]
  else ($car | frompath($conses)) + ($cdr | frompath($conses))
  end;
       
def mkpath: .conses as $conses | .paths[] | frompath($conses);
