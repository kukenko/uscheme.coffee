class UScheme
  primitive_fun_env: {
    '+': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x + y],
    '-': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x - y],
    '*': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x * y],
  }

  listp: (expr) -> Array.isArray expr

  nump: (expr) -> (isFinite expr) and not (@listp expr)

  immediatep: (expr) -> @nump expr

  car: (list) -> list[0]

  cdr: (list) -> list[1..]

  apply_primitive_fun: (fun, args) -> fun[1] args

  apply: (fun, args) -> @apply_primitive_fun fun, args

  eval_list: (expr) ->
    (@_eval e for e in expr)

  _eval: (expr) ->
    unless @listp expr
      if @immediatep expr
        expr
      else
        @primitive_fun_env[expr]
    else
      f = @_eval(@car expr)
      a = @eval_list(@cdr expr)
      @apply f, a

exports.UScheme = UScheme
