;;;; method lookup tests


(use test objc)


(test-begin)

(define s1 (@ "this is a test"))
(test (string-length "this is a test") (@ s1 length))
(test "" (NSString->string (@ (find-class "NSString") string)))
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

;; test wether cache works at all
(times 3 (lambda (i)
	   (test (if (= 2 i) "foo" "this is a test")
		 (NSString->string (@ (if (= 2 i) (@ "foo") s1) description)))))

(print "calling method " count " times with cache enabled...")
(time (times count (lambda (i) (@ s1 description))))

(test-end)