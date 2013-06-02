expect = require 'expect.js'
uscheme = require("../src/uscheme")

describe 'UScheme',->
  u = null

  before ->
    u = new uscheme.UScheme

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

  describe 'car', ->
    it '先頭の要素を返す', ->
      expect(u.car [0, 1, 2]).to.be 0
      expect(u.car ['a', 'b', 'c']).to.be 'a'

  describe 'cdr', ->
    it '先頭を除いた要素を返す', ->
      expect(u.cdr [0, 1, 2]).to.eql [1, 2]
      expect(u.cdr ['a', 'b', 'c']).to.eql ['b', 'c']
      expect(u.cdr []).to.eql []

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
      expect(u.eval_list [1, 2, ['+', 1, 2]]).to.be.eql [1, 2, 3]

  describe '_eval', ->
    it '式を評価する', ->
      expect(u._eval ['+', 1, 2, 3]).to.be 6
      expect(u._eval ['-', 1, 2, 3]).to.be -4
      expect(u._eval ['+', 1, 2, 3]).to.be 6
