class UScheme
  primitive_fun_env: {
    '+': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x + y],
    '-': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x - y],
    '*': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x * y],
    '>': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x > y],
    '<': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x < y],
    '>=': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x >= y],
    '<=': ['prim', (xs) -> (x for x in xs).reduce (x, y) -> x <= y],
  }

  # http://coffeescriptcookbook.com/chapters/arrays/zip-function
  zip: ->
    lengthArray = (arr.length for arr in arguments)
    length = Math.min(lengthArray...)
    for i in [0...length]
      arr[i] for arr in arguments

  lookup: (key, env) ->
    try
      alists = (alist for alist in env when key of alist)
      alists[0][key]
    catch TypeError
      throw new Error("couldn't find value to variables:'#{key}'")

  extend_env: (parameters, args, env) ->
    new_h = {}
    (new_h[x[0]] = x[1] for x in @zip parameters, args)
    env.unshift new_h
    env

  listp: (expr) -> Array.isArray expr

  nump: (expr) -> (isFinite expr) and not (@listp expr)

  immediatep: (expr) -> @nump expr

  letp: (expr) -> expr[0] == 'let'

  lambdap: (expr) -> expr[0] == 'lambda'

  ifp: (expr) -> expr[0] == 'if'

  specialp: (expr) ->
    @letp(expr) or
    @lambdap(expr) or
    @ifp(expr)

  primitivep: (expr) -> expr[0] == 'prim'

  car: (list) -> list[0]

  cdr: (list) -> list[1..]

  from_let: (expr) ->
    [(p[0] for p in expr[1]), (a[1] for a in expr[1]), expr[2]]

  from_closure: (expr) -> expr[1..]

  from_if: (expr) -> expr[1..]

  new_closure: (expr, env) ->
    ['closure', expr[1], expr[2], env]

  apply_primitive_fun: (fun, args) -> fun[1] args

  apply_lambda: (closure, args) ->
    [p, b, e] = @from_closure closure
    new_env = @extend_env p, args, e
    @_eval b, new_env

  apply: (fun, args) ->
    if @primitivep fun
      @apply_primitive_fun fun, args
    else
      @apply_lambda fun, args

  eval_list: (expr, env) ->
    (@_eval e, env for e in expr)

  eval_lambda: (expr, env) ->
    @new_closure expr, env

  eval_let: (expr, env) ->
    [p, a, b] = @from_let expr
    new_expr = [['lambda', p, b]].concat a
    @_eval new_expr, env

  eval_if: (expr, env) ->
    [cnd, tc, fc] = @from_if expr
    if @_eval cnd, env
      @_eval tc, env
    else
      @_eval fc, env

  eval_special_form: (expr, env) ->
    if @lambdap expr
      @eval_lambda expr, env
    else if @letp expr
      @eval_let expr, env
    else if @ifp expr
      @eval_if expr, env

  _eval: (expr, env) ->
    unless @listp expr
      if @immediatep expr
        expr
      else
        @lookup expr, env
    else
      if @specialp expr
        @eval_special_form expr, env
      else
        f = @_eval @car(expr), env
        a = @eval_list @cdr(expr), env
        @apply f, a

exports.UScheme = UScheme
