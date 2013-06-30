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

  list_env: {
    'car': ['prim', (xs) -> car(xs)],
    'cdr': ['prim', (xs) -> cdr(xs)],
  }

  # http://coffeescriptcookbook.com/chapters/arrays/zip-function
  zip = ->
    lengthArray = (arr.length for arr in arguments)
    length = Math.min(lengthArray...)
    for i in [0...length]
      arr[i] for arr in arguments

  lookup = (key, env) ->
    try
      alists = (alist for alist in env when key of alist)
      alists[0][key]
    catch TypeError
      throw new Error("couldn't find value to variables:'#{key}'")

  lookupEnv = (key, env) ->
    alists = (alist for alist in env when key of alist)
    alists[0]

  extendEnv = (parameters, args, env) ->
    new_h = {}
    (new_h[x[0]] = x[1] for x in zip parameters, args)
    env.unshift new_h
    env

  extendEnv2 = (parameters, args, env) ->
    env[0][p] = a for p, a in zip parameters, args

  listp = (expr) -> Array.isArray expr

  nump = (expr) -> (isFinite expr) and not (listp expr)

  immediatep = (expr) -> nump expr

  letp = (expr) -> expr[0] is 'let'

  lambdap = (expr) -> expr[0] is 'lambda'

  ifp = (expr) -> expr[0] is 'if'

  letrecp = (expr) -> expr[0] is 'letrec'

  condp = (expr) -> expr[0] is 'cond'

  definep = (expr) -> expr[0] is 'define'

  quotep = (expr) -> expr[0] is 'quote'

  specialp = (expr) ->
    letp(expr) or
    lambdap(expr) or
    ifp(expr) or
    letrecp(expr) or
    condp(expr) or
    definep(expr) or
    quotep(expr)

  primitivep = (expr) -> expr[0] is 'prim'

  car = (list) -> list[0]

  cdr = (list) -> list[1..]

  fromLet = (expr) ->
    [(p[0] for p in expr[1]), (a[1] for a in expr[1]), expr[2]]

  fromClosure = (expr) -> expr[1..]

  fromIf = (expr) -> expr[1..]

  fromLetrec = (expr) -> fromLet expr

  fromCondToIf = (expr) ->
    if expr.length is 0
      []
    else
      e = car expr
      [p, c] = e
      if p is 'else'
        p = 'true'
      ['if', p, c, fromCondToIf(cdr expr)]

  fromDefine = (expr) ->
    if listp expr[1]
      va = car expr[1]
      vl = ['lambda', cdr(expr[1]), expr[2]]
      [va, vl]
    else
      [expr[1], expr[2]]

  newClosure = (expr, env) ->
    ['closure', expr[1], expr[2], env]

  applyPrimitiveFun = (fun, args) -> fun[1] args

  applyLambda = (closure, args) ->
    [p, b, e] = fromClosure closure
    new_env = extendEnv p, args, e
    UScheme._eval b, new_env

  apply = (fun, args) ->
    if primitivep fun
      applyPrimitiveFun fun, args
    else
      applyLambda fun, args

  evalList = (expr, env) ->
    (UScheme._eval e, env for e in expr)

  evalLambda = (expr, env) ->
    newClosure expr, env

  evalLet = (expr, env) ->
    [p, a, b] = fromLet expr
    new_expr = [['lambda', p, b]].concat a
    UScheme._eval new_expr, env

  evalIf = (expr, env) ->
    [cnd, tc, fc] = fromIf expr
    if UScheme._eval cnd, env
      UScheme._eval tc, env
    else
      UScheme._eval fc, env

  evalLetrec = (expr, env) ->
    [params, a, b] = fromLetrec expr
    tmp_env = {}
    (tmp_env[param] = 'dummy' for param in params)
    keys = (k for k of tmp_env)
    values = (v for k, v of tmp_env)
    ext_env = extendEnv keys, values, env
    args_val = evalList a, ext_env
    extendEnv2 params, args_val, ext_env
    new_expr = [['lambda', params, b]].concat a
    UScheme._eval new_expr, ext_env

  evalCond = (expr, env) ->
    if_expr = fromCondToIf(cdr expr)
    evalIf if_expr, env

  evalDefine = (expr, env) ->
    [va, vl] = fromDefine expr
    v_ref = lookupEnv(va, env)
    if v_ref
      v_ref[va] = UScheme._eval va, env
    else
      extendEnv([va], [UScheme._eval vl, env], env)

  evalQuote = (expr, env) -> car (cdr expr)

  evalSpecialForm = (expr, env) ->
    if lambdap expr
      evalLambda expr, env
    else if letp expr
      evalLet expr, env
    else if ifp expr
      evalIf expr, env
    else if letrecp expr
      evalLetrec expr, env
    else if condp expr
      evalCond expr, env
    else if definep expr
      evalDefine expr, env
    else if quotep expr
      evalQuote expr, env

  @parse = (expr) ->
    program = expr.replace /^\s+|\s+$/g, ""
    program = program.replace /[a-zA-Z\+\-\*><=][0-9a-zA-Z\+\-\=!*]*/g, (m) -> "'#{m}'"
    program = program.replace /\s+/g, ", "
    program = program.replace /\(/g, "["
    program = program.replace /\)/g, "]"
    eval program

  @_eval: (expr, env) ->
    unless listp expr
      if immediatep expr
        expr
      else
        lookup expr, env
    else
      if specialp expr
        evalSpecialForm expr, env
      else
        f = UScheme._eval car(expr), env
        a = evalList cdr(expr), env
        apply f, a

exports.UScheme = UScheme
