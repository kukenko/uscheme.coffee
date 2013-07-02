expect = require 'expect.js'
uscheme = require("../src/uscheme")

describe 'UScheme',->
  u = null
  g = null
  ueval = (expr) -> uscheme.UScheme._eval uscheme.UScheme.parse(expr), g

  before ->
    u = new uscheme.UScheme
    g = [u.primitive_fun_env, u.boolean_env, u.list_env]

  describe 'parse', ->
    it 'S式をCoffeeScriptのリテラルに変換する', ->
      expr = uscheme.UScheme.parse "(length (list 1 2 3))"
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
        ueval '(define (id x) x)'
        expect(ueval '(id 10)').to.be 10

        ueval '(define id (lambda (x) x))'
        expect(ueval '(id 10)').to.be 10

        # FIXME: 'lst'を'list'にすると以降のテストが失敗する
        ueval '(define (length lst) (if (null? lst) 0 (+ (length (cdr lst)) 1)))'
        expect(ueval '(length (list 1 2 3))').to.be 3

        ueval '(define lst (list 1 2 3))'
        expect(ueval '(cdr lst)').to.eql [2, 3]

    describe 'quote', ->
      it '式を評価する', ->
        expect(ueval '(quote (0 1 2))').to.eql [0, 1, 2]

    describe 'car', ->
      it '先頭の要素を返す', ->
        expect(ueval '(car 0 1 2)').to.be 0

    describe 'cdr', ->
      it '先頭を除いた要素を返す', ->
        expect(ueval '(cdr 0 1 2)').to.eql [1, 2]
        expect(ueval '(cdr)').to.eql []

    describe 'list', ->
      it 'リストをそのまま返す', ->
        expect(ueval '(list 0 1 2)').to.eql [0, 1, 2]
        expect(ueval '(list 0 (quote (1 2)))').to.eql [0, [1, 2]]

    describe 'cons', ->
      it 'リストに先頭要素を加える', ->
        expect(ueval '(cons 0 (list 1 2))').to.eql [0, 1, 2]

    describe 'nil', ->
      it '空リストを返す', ->
        expect(ueval '(nil)').to.eql []

    describe 'null?', ->
      it '空リストの場合は真を返す', ->
        expect(ueval '(null? (nil))').to.be true
