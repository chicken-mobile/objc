;;;; class implementation tests


(use test objc)

(install-autorelease-pool)

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


(test-begin)

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
      (@ f1 instanceMethod1: 99 with: (@ "string")))
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
