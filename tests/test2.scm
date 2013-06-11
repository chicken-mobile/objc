;;;; method lookup tests


(use test objc)


(test-begin)

;(install-autorelease-pool)

(NSLog "starting test2 ...")

(define s1 (@ (find-class "NSString") stringWithUTF8String: "this is a test"))
(test (string-length "this is a test") (@ s1 length))
;(test "" (NSString->string (@ (find-class "NSString") string)))
;(test "this is a test" (NSString->string (@ s1 description)))

(define (times n proc)
  (unless (zero? n) 
    (proc n)
    (times (sub1 n) proc)))

(set! *enable-inline-cache* #f)
(define count 100000)
(print "calling method " count " times with cache disabled...")

(time (times count (lambda (i) (@ s1 description))))

(set! *enable-inline-cache* #t)

(print "calling method " count " times with cache enabled...")
(time (times count (lambda (i) (@ s1 description))))

(test-end)
