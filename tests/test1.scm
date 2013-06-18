(use test objc)

(test-begin)

(define NSAutoreleasePool (find-class "NSAutoreleasePool"))

(@ NSAutoreleasePool new)

;;;; tests of basic object/class/selector API

(define NSString (find-class 'NSString))
(define (string->NSString s) (@ NSString stringWithUTF8String: s))
(define (NSString->string s) (@ s UTF8String))

(define (superclass-chain cls)
  (if cls
      (let ((s (superclass-of cls)))
	(if s
	    (cons (class-name s) (superclass-chain s))
	    '()))
      '()))

(define s1 (string->NSString "foo"))
(test-assert (object? s1))
(test-assert (not (class? s1)))
(test-assert (class? (class-of s1)))

(let ((sc (superclass-chain (class-of s1))))
  (test-assert (member "NSString" sc)))

(test "foo" (NSString->string s1))

(define sel (string->selector "foo:bar:"))
(test-assert (selector? sel))
(test-assert (not (object? sel)))
(test-assert (not (class? sel)))
(test "foo:bar:" (selector->string sel))
(test-assert (selector? (@selector foo)))
(test "foo:bar:" (selector->string (@selector foo:bar:)))

(test-assert (not (class-of #f)))
(test "Nil" (class-name #f))

;; method lookup tests

(define s1 (@ NSString stringWithUTF8String: "this is a test"))
(test (string-length "this is a test") (@ s1 length))
(test "" (NSString->string (@ NSString string)))
(test "this is a test" (NSString->string (@ s1 description)))

(define (times n proc)
  (unless (zero? n) 
    (proc n)
    (times (sub1 n) proc)))

(set! *enable-inline-cache* #f)
(define count 100000)
(print "calling method " count " times with cache disabled...")

(time (times count (lambda (i) (@ s1 description))))

(set! *enable-inline-cache* #t)

(times 3 (lambda (i)
	   (test (if (= 2 i) "foo" "this is a test")
		 (NSString->string (@ (if (= 2 i) (string->NSString "foo") s1) description)))))

(print "calling method " count " times with cache enabled...")
(time (times count (lambda (i) (@ s1 description))))

;; class implementation tests

(objc-import "<objc/Object.h>")
(objc-import "<Foundation/NSObject.h>")

(define-objc-interface Foo : NSObject
  (field int x)
  (field double y)
  (+ (void)classMethod: (int)arg)
  (- (c-string)instanceMethod1: (int)arg1 with: (id)arg2)
  (- instanceMethod2))

(define class-method #f)
(define instance-method1 #f)
(define instance-method2 #f)
(define bar #f)

(define-objc-implementation Foo
  ((+ (void)classMethod: (int) arg)
   (set! class-method arg))
  ((- (c-string)instanceMethod1: (int)arg1 with: (id)arg2)
   (let ((name (class-name (class-of arg2))))
     (set! instance-method1 (list arg1 (NSString->string arg2)))
     name))
  ((- instanceMethod2) 
   (set! instance-method2 self)
   self))

(define-objc-interface Bar : Foo)

(define-objc-implementation Bar
  ((- instanceMethod2)
   (set! bar #t)
   (@ super instanceMethod2)))

(test-assert (class? Foo))
(test "Foo" (class-name Foo))
(test "NSObject" (class-name (superclass-of Foo)))
(test-assert (equal? (find-class 'NSObject) (superclass-of Foo)))

(@ Foo classMethod: 42)
(test 42 class-method)
(define f1 (@ Foo new))
(test Foo (class-of f1))

(test (cond-expand
       (macosx "__NSCFConstantString")
       (else "GSCBufferString"))
      (@ f1 instanceMethod1: 99 with: (string->NSString "string")))

(test (list 99 "string") (values instance-method1))
(define r1 (@ f1 instanceMethod2))
(test-assert (equal? r1 f1))
(define b1 (@ Bar new))
(define r2 (@ b1 instanceMethod2))
(test-assert (equal? b1 r2))
(test-assert bar)
(test b1 instance-method2)

(object-set! f1 'x 99)
(object-set! f1 'y 100)
(test 99 (object-ref f1 'x))
(test 100.0 (object-ref f1 'y))

(test-end)
