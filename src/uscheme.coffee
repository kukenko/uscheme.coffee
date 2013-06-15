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

  boolean_env: {
    'true': true, 'false': false
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

  lookup_env: (key, env) ->
    alists = (alist for alist in env when key of alist)
    alists[0]

  extend_env: (parameters, args, env) ->
    new_h = {}
    (new_h[x[0]] = x[1] for x in @zip parameters, args)
    env.unshift new_h
    env

  extend_env2: (parameters, args, env) ->
    env[0][p] = a for p, a in @zip parameters, args

  listp: (expr) -> Array.isArray expr

  nump: (expr) -> (isFinite expr) and not (@listp expr)

  immediatep: (expr) -> @nump expr

  letp: (expr) -> expr[0] is 'let'

  lambdap: (expr) -> expr[0] is 'lambda'

  ifp: (expr) -> expr[0] is 'if'

  letrecp: (expr) -> expr[0] is 'letrec'

  condp: (expr) -> expr[0] is 'cond'

  definep: (expr) -> expr[0] is 'define'

  specialp: (expr) ->
    @letp(expr) or
    @lambdap(expr) or
    @ifp(expr) or
    @letrecp(expr) or
    @condp(expr) or
    @definep(expr)

  primitivep: (expr) -> expr[0] is 'prim'

  car: (list) -> list[0]

  cdr: (list) -> list[1..]

  from_let: (expr) ->
    [(p[0] for p in expr[1]), (a[1] for a in expr[1]), expr[2]]

  from_closure: (expr) -> expr[1..]

  from_if: (expr) -> expr[1..]

  from_letrec: (expr) -> @from_let expr

  from_cond_to_if: (expr) ->
    if expr.length is 0
      []
    else
      e = @car expr
      [p, c] = e
      if p is 'else'
        p = 'true'
      ['if', p, c, @from_cond_to_if(@cdr expr)]

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

  parse: (expr) ->
    program = expr.replace /^\s+|\s+$/g, ""
    program = program.replace /[a-zA-Z\+\-\*><=][0-9a-zA-Z\+\-\=!*]*/g, (m) -> "'#{m}'"
    program = program.replace /\s+/g, ", "
    program = program.replace /\(/g, "["
    program = program.replace /\)/g, "]"
    eval program

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

  eval_letrec: (expr, env) ->
    [params, a, b] = @from_letrec expr
    tmp_env = {}
    (tmp_env[param] = 'dummy' for param in params)
    keys = (k for k of tmp_env)
    values = (v for k, v of tmp_env)
    ext_env = @extend_env keys, values, env
    args_val = @eval_list a, ext_env
    @extend_env2 params, args_val, ext_env
    new_expr = [['lambda', params, b]].concat a
    @_eval new_expr, ext_env

  eval_cond: (expr, env) ->
    if_expr = @from_cond_to_if (@cdr expr)
    @eval_if if_expr, env

  eval_special_form: (expr, env) ->
    if @lambdap expr
      @eval_lambda expr, env
    else if @letp expr
      @eval_let expr, env
    else if @ifp expr
      @eval_if expr, env
    else if @letrecp expr
      @eval_letrec expr, env
    else if @condp expr
      @eval_cond expr, env

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
