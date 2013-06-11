;;;; tests of basic object/class/selector API


(use test objc)

(test-begin)

;(install-autorelease-pool)

(NSLog "starting test1 ...")

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

(test-end)
