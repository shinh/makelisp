MakeLisp
========

Lisp implementation in GNU make

[makelisp.mk](https://github.com/shinh/makelisp/blob/master/makelisp.mk)
is a Lisp interpreter in GNU make.

GNU make has two builtin functions, $(shell) and $(guile), which make
the implementation less interesting. MakeLisp does not use either of
them, except a single $(shell cat /dev/stdin) function call to make it
easier for users to pass Lisp programs to MakeLisp.


How to Use
----------

    $ make -f makelisp.mk LISP_PROGRAM='(car (quote (a b c)))'
    a
    $ make -f makelisp.mk LISP_PROGRAM='(cdr (quote (a b c)))'
    (b c)
    $ make -f makelisp.mk LISP_PROGRAM='(cons 1 (cons 2 (cons 3 ())))'
    (1 2 3)
    $ make -f makelisp.mk
    (defun fact (n) (if (eq n 0) 1 (* n (fact (- n 1)))))
    (fact 10)
    (defun fib (n) (if (eq n 1) 1 (if (eq n 0) 1 (+ (fib (- n 1)) (fib (- n 2))))))
    (fib 12)
    (defun gen (n) ((lambda (x y) y) (define G n) (lambda (m) (define G (+ G m)) G)))
    (define x (gen 100))
    (x 10)
    (x 90)
    (x 300)
    ^D
    fact
    3628800
    fib
    233
    gen
    x
    110
    200
    500

Note ^D in the above means you should type Ctrl + d. Lines followed by
the ^D are expected output, so you should not need to type them.


Builtin Functions
-----------------

- car
- cdr
- cons
- eq
- atom
- +, -, *, /, mod
- neg?
- print


Special Forms
-------------

- quote
- if
- lambda
- defun
- define


More Complicated Examples
-------------------------

You can test a few more examples.

FizzBuzz:

    $ cat fizzbuzz.l | make -f makelisp.mk
    (lambda (n) (if (eq n 101) nil (if (print (if (eq (mod n 15) 0) FizzBuzz (if (eq (mod n 5) 0) Buzz (if (eq (mod n 3) 0) Fizz n)))) (fizzbuzz (+ n 1)) nil)))
    PRINT:   1
    PRINT:   2
    PRINT:   Fizz
    ...
    PRINT:   98
    PRINT:   Fizz
    PRINT:   Buzz
    nil

Sort:

    $ (cat sort.l && echo '(sort (quote (4 2 99 12 -4 -7)))') | make -f makelisp.mk
    ...
    (1 2 3 4 5 6 7)
    (-7 -4 2 4 12 99)

Though this Lisp implementation does not support eval function, we can
implement eval on top of this interpreter - eval.l is the
implementation:

    $ (grep -v ';' eval.l && cat /dev/stdin) | make -f makelisp.mk
    (eval (quote (+ 4 38)))
    (eval (quote (defun fact (n) (if (eq n 0) 1 (* n (fact (- n 1)))))))
    (eval (quote (fact 4)))
    ^D
    ...
    42
    gval-table
    24

This essentially means we have a Lisp interpreter in Lisp. evalify.rb
is a helper script to convert a normal Lisp program into the Lisp in
Lisp. You can run the FizzBuzz program like:

    $ ./evalify.rb fizzbuzz.l | make -f makelisp.mk
    ...
    PRINT:   1
    PRINT:   2
    PRINT:   Fizz

This takes very long time. I'm not sure if this will finish. You can
use [kati](https://github.com/google/kati) for a faster execution
(~30 seconds for me):

    $ git clone https://github.com/google/kati
    $ make -C kati -j8
    $ ulimit -s 40960  # You need a fairly big stack.
    $ ./evalify.rb fizzbuzz.l | time ./kati/ckati -f makelisp.mk

Though makelisp.mk does not support defmacro, eval.l also defines
defmacro:

    $ ./evalify.rb | make -f makelisp.mk
    (defmacro let (l e) (cons (cons lambda (cons (cons (car l) nil) (cons e nil))) (cons (car (cdr l)) nil)))
    (let (x 42) (+ x 7))
    ^D
    ...
    49
    $ ./evalify.rb | make -f makelisp.mk
    (defun list0 (a) (cons a nil))
    (defun cadr (a) (car (cdr a)))
    (defmacro cond (l) (if l (cons if (cons (car (car l)) (cons (cadr (car l)) (cons (cons (quote cond) (list0 (cdr l))))))) nil))
    (defun fb (n) (cond (((eq (mod n 5) 0) "Buzz") ((eq (mod n 3) 0) "Fizz") (t n))))
    (fb 18)
    ^D
    ...
    "Fizz"

You can apply ./evalify.rb multiple times. However, makelisp seems to
be too slow to run the generated program. purelisp.rb, which is a
reference implementation of makelisp, can run it:

    $ ./evalify.rb fizzbuzz.l | ./evalify.rb | ruby purelisp.rb
    ...
    PRINT: 1
    PRINT: 2
    PRINT: Fizz
    PRINT: 4
    PRINT: Buzz
    PRINT: Fizz
    PRINT: 7
    PRINT: 8

test.l is the test program I was using during the development. test.rb
runs it with makelisp.mk and purelisp.rb and compare their
results. You can run the test with evalify.rb by passing -e:

    $ ./test.rb -e purelisp.rb makelisp.mk


Limitations
-----------

There should be a lot of limitations. beflisp behaves very strangely
when you pass a broken Lisp code.


See also
--------

* [Lisp in sed](https://github.com/shinh/sedlisp)
* [Lisp in Befunge](https://github.com/shinh/beflisp)
