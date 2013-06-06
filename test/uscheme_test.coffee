expect = require 'expect.js'
uscheme = require("../src/uscheme")

describe 'UScheme',->
  u = null
  g = null

  before ->
    u = new uscheme.UScheme
    g = [u.primitive_fun_env]

  describe 'zip', ->
    it '配列の各要素からなる配列の配列を返す', ->
      expect(u.zip [0, 1], [2, 3]).to.eql [[0, 2], [1, 3]]
      expect(u.zip [0, 1, 2], [3, 4]).to.eql [[0, 3], [1, 4]]

  describe 'lookup', ->
    it 'キーに対応する値を返す', ->
      expect(u.lookup '+', [{'-': 0}, {'+': 1}]).to.be 1

      clj = -> u.lookup '*', [{'-': 0}, {'+': 1}]
      expect(clj).to.throwError()

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

  describe 'specialp', ->
    it 'スペシャルフォームの場合は真を返す', ->
      expect(u.specialp ['let', 0, 1]).to.be true
      expect(u.specialp ['lambda', ['x'], ['+', 'x', 1]]).to.be true

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

  describe '_eval', ->
    describe 'primitive', ->
      it '式を評価する', ->
        expect(u._eval 0, g).to.be 0
        expect(u._eval 1, g).to.be 1
        expect(u._eval ['+', 1, 2, 3], g).to.be 6
        expect(u._eval ['-', 1, 2, 3], g).to.be -4
        expect(u._eval ['+', 1, 2, 3], g).to.be 6

    describe 'lambda', ->
      it '式を評価する', ->
        expect(u._eval [['lambda', ['x', 'y'], ['+', 'x', 'y']], 1, 2], g).to.be 3
        expr = [['lambda', ['fun'], ['fun', 88]], ['lambda', ['x'], ['+', 'x', 2]]]
        expect(u._eval expr, g).to.be 90

    describe 'let', ->
      it '式を評価する', ->
        expect(u._eval ['let', [['x', 3]], ['+', 'x', 4]], g).to.be 7
        expr = ['let', [['x', 3]], [['lambda', ['y'], ['+', 'x', 'y']], 10]]
        expect(u._eval expr, g).to.be 13
