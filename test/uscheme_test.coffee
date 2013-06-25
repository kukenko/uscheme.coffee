expect = require 'expect.js'
uscheme = require("../src/uscheme")

describe 'UScheme',->
  u = null
  g = null
  ueval = (expr) -> u._eval u.parse(expr), g

  before ->
    u = new uscheme.UScheme
    g = [u.primitive_fun_env, u.boolean_env]

  describe 'zip', ->
    it '配列の各要素からなる配列の配列を返す', ->
      expect(u.zip [0, 1], [2, 3]).to.eql [[0, 2], [1, 3]]
      expect(u.zip [0, 1, 2], [3, 4]).to.eql [[0, 3], [1, 4]]

  describe 'lookup', ->
    it 'キーに対応する値を返す', ->
      expect(u.lookup '+', [{'-': 0}, {'+': 1}]).to.be 1
      clj = -> u.lookup '*', [{'-': 0}, {'+': 1}]
      expect(clj).to.throwError()

  describe 'lookup_env', ->
    it 'キーに対応する環境を返す', ->
      expect(u.lookup_env '+', [{'-': 0}, {'+': 1}]).to.eql {'+': 1}

  describe 'extend_env', ->
    it '環境を新たに作って環境の先頭に追加する', ->
      env = [{'+': 0}]
      u.extend_env ['-', '*'], [1, 2], env
      expect(env).to.eql [{'-': 1, '*':2}, {'+': 0}]

  describe 'listp', ->
    it '配列の場合は真を返す', ->
      expect(u.listp []).to.be true
      expect(u.listp 0).not.to.be true

  describe 'nump', ->
    it '数値の場合は真を返す', ->
      expect(u.nump 0).to.be true
      expect(u.nump []).not.to.be true

  describe 'immediatep', ->
    it '即値の場合は真を返す', ->
      expect(u.immediatep 0).to.be true
      expect(u.immediatep []).not.to.be true

  describe 'letp', ->
    it 'letの場合は真を返す', ->
      expect(u.letp ['let', 0, 1]).to.be true

  describe 'lambdap', ->
    it 'lambdaの場合は真を返す', ->
      expect(u.lambdap ['lambda', ['x'], ['+', 'x', 1]]).to.be true

  describe 'ifp', ->
    it 'ifの場合は真を返す', ->
      expect(u.ifp ['if', ['<', 0, 1], [0], [1]]).to.be true

  describe 'letrecp', ->
    it 'letrecの場合は真を返す', ->
      expect(u.letrecp ['letrec']).to.be true

  describe 'condp', ->
    it 'condの場合は真を返す', ->
      expect(u.condp ['cond']).to.be true

  describe 'definep', ->
    it 'defineの場合は真を返す', ->
      expect(u.definep ['define']).to.be true

  describe 'specialp', ->
    it 'スペシャルフォームの場合は真を返す', ->
      expect(u.specialp ['let', 0, 1]).to.be true
      expect(u.specialp ['lambda', ['x'], ['+', 'x', 1]]).to.be true
      expect(u.specialp ['if', ['<', 0, 1], [0], [1]]).to.be true
      expect(u.specialp ['letrec', 'dummy']).to.be true
      expect(u.specialp ['cond', [['>', 1, 1], 1], ['else', -1]]).to.be true
      expect(u.specialp ['define', ['id', 'x'], 'x']).to.be true

  describe 'primitivep', ->
    it '組み込みの場合は真を返す', ->
      expect(u.primitivep ['prim']).to.be true
      expect(u.primitivep ['lambda', ['x'], ['+', 'x', 1]]).not.to.be true

  describe 'car', ->
    it '先頭の要素を返す', ->
      expect(u.car [0, 1, 2]).to.be 0
      expect(u.car ['a', 'b', 'c']).to.be 'a'

  describe 'cdr', ->
    it '先頭を除いた要素を返す', ->
      expect(u.cdr [0, 1, 2]).to.eql [1, 2]
      expect(u.cdr ['a', 'b', 'c']).to.eql ['b', 'c']
      expect(u.cdr []).to.eql []

  describe 'from_let', ->
    it '仮引数, 引数, 本体を返す', ->
      [p, a, b] = u.from_let ['let', [['x', 1]], ['+', 'x', 1]]
      expect(p).to.eql ['x']
      expect(a).to.eql [1]
      expect(b).to.eql ['+', 'x', 1]

  describe 'from_closure', ->
    it '引数, 本体, 環境を返す', ->
      [p, b, e] = u.from_closure u.new_closure([0, 1, 2], [{}])
      expect(p).to.eql 1
      expect(b).to.eql 2
      expect(e).to.eql [{}]

  describe 'from_if', ->
    it '条件式, True節, False節を返す', ->
      [cnd, tc, fc] = u.from_if ['if', ['<', 0, 1], [0], [1]]
      expect(cnd).to.eql ['<', 0, 1]
      expect(tc).to.eql [0]
      expect(fc).to.eql [1]

  describe 'from_cond_to_if', ->
    it 'cond式からif式を作成する', ->
      expr = [[['>', 1, 1], 1], ['else', -1]]
      e = u.from_cond_to_if expr
      expect(e).to.eql ['if', ['>', 1, 1], 1, ['if', 'true', -1, []]]

  describe 'from_define', ->
    it 'define式から変数と値を返す', ->
      expr = ['define', 'id', ['lambda', ['x'], 'x']]
      expect(u.from_define expr).to.eql ['id', ['lambda', ['x'], 'x']]

      expr = ['define', ['id', 'x'], 'x']
      expect(u.from_define expr).to.eql ['id', ['lambda', ['x'], 'x']]

  describe 'new_closure', ->
    it 'closureを返す', ->
      expect(u.new_closure [0, 1, 2], [{}]).to.eql ['closure', 1, 2, [{}]]

  describe 'apply_primitive_fun', ->
    it '即値引数を関数へ適用する', ->
      f = u.primitive_fun_env['+']
      expect(u.apply_primitive_fun f, [1, 2, 3]).to.be 6
      f = u.primitive_fun_env['-']
      expect(u.apply_primitive_fun f, [1, 2, 3]).to.be -4

  describe 'apply', ->
    it '引数を関数へ適用する', ->
      f = u.primitive_fun_env['+']
      expect(u.apply f, [1, 2, 3]).to.be 6

  describe 'eval_list', ->
    it '評価結果を要素とする配列を返す', ->
      expect(u.eval_list [1, 2, ['+', 1, 2]], g).to.be.eql [1, 2, 3]

  describe 'parse', ->
    it 'S式をCoffeeScriptのリテラルに変換する', ->
      expr = u.parse "(length (list 1 2 3))"
      expect(expr).to.eql ['length', ['list', 1, 2, 3]]

  describe '_eval', ->
    describe 'primitive', ->
      it '式を評価する', ->
        expect(ueval '0').to.be 0
        expect(ueval '1').to.be 1
        expect(ueval '(+ 1 2 3)').to.be 6
        expect(ueval '(- 1 2 3)').to.be -4
        expect(ueval '(> 0 1)').not.to.be true
        expect(ueval '(>= 0 1)').not.to.be true
        expect(ueval '(< 0 1)').to.be true
        expect(ueval '(<= 0 1)').to.be true

    describe 'lambda', ->
      it '式を評価する', ->
        expect(ueval '((lambda (x y) (+ x y)) 1 2)').to.be 3
        expect(ueval '((lambda (fun) (fun 88)) (lambda (x) (+ x 2)))').to.be 90

    describe 'let', ->
      it '式を評価する', ->
        expect(ueval '(let ((x 3)) (+ x 4))').to.be 7
        expect(ueval '(let ((x 3)) ((lambda (y) (+ x y)) 10))').to.be 13

    describe 'if', ->
      it '式を評価する', ->
        expect(ueval '(if (< 0 1) 0 1)').to.be 0
        expect(ueval '(if (> 0 1) 0 1)').to.be 1
        expect(ueval '(if (> 0 1) 0 ((lambda (x) (+ x 1)) 1))').to.be 2

    describe 'letrec', ->
      it '式を評価する', ->
        expr = '(letrec
                  ((fact (lambda (n)
                           (if (< n 1)
                                1
                                (* n (fact (- n 1))))))) (fact 4))'
        expect(ueval expr).to.be 24

    describe 'cond', ->
      it '式を評価する', ->
        expr = '(cond
                  ((> 1 1) 1)
                  ((> 2 1) 2)
                  ((> 3 1) 3)
                  (else -1))'
        expect(ueval expr).to.be 2

    describe 'define', ->
      it '式を評価する', ->
        expr = '(define (id x) x)'
        ueval expr
        expect(ueval '(id 10)').to.be 10
