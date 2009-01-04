#;
(define testo
  (let ((class (class NSString))
	(sel (selector string)))
    (let ((imp (class-get-method-imp class sel))
	  (proc (foreign-lambda* objc-object ((objc-imp p) (objc-object o) (objc-selector sel) (c-string s))
		  "C_return(((IMP)*p)(*o, *sel));")))
      (lambda (arg0)
	(let ((muh (class-create-instance class 0)))
	  (object-set-class (class NSString))
	  (proc imp (object-get-class muh) sel arg0))))))

#;
(define objc-msg-send
  (foreign-lambda* objc-object ((objc-object o) (objc-selector s))
    "C_return(objc_msgSend(*o,*s));"))

;; (define bar?
;;   (foreign-lambda* objc-object ()
;;     "C_return([NSString stringWithCString:\"muh kuh macht gut muh foo kuh\"]);"))
;; (define bar??
;;   (foreign-lambda* objc-object ()
;;     "C_return([[NSString alloc] init]);"))
;; (define bar???
;;   (foreign-lambda* objc-object ()
;;     "C_return([NSString alloc]);"))

;; (pp (object-get-class-name (bar?)))
;; (pp (object-get-class-name (bar??)))
;; (pp (object-get-class-name (bar???)))




#;
(let* ((class-object (class NSAutoreleasePool))
       (sel (selector init))
       (imp (class-get-method-imp class-object sel))
       (proc (foreign-lambda* objc-object ((objc-imp p) (objc-object o) (objc-selector sel))
	       "IMP imp = (IMP)*p;
                id  foo = imp(*o, *sel);
                id* bar = &foo;
                C_return(bar);")))
  (pp class-object)
  (pp sel)
  (pp imp)

  (let* ((obj (class-create-instance class-object 0))
	 (foo (proc imp obj sel)))
    (pp obj)
    (pp (object-get-class-name obj))
    (print "---")
    (pp foo)
    (pp (object-get-class-name foo))))
(pp "----------------")





#;
(foo NSString stringWithCString: c-string 
     andFoo: int 
     onSomethingDifferent: c-pointer)



(let* ((NSString-stringWithCString (objc-class-lambda NSString stringWithCString:))
       (foo-string (NSString-stringWithCString "foo?")))
  (pp (object-get-class-name foo-string)))


#;
(let* ((class-object (class NSString))
       (sel (selector alloc))
       (imp (class-get-method-imp (object-get-class class-object) sel))
       (proc (foreign-lambda* objc-object ((objc-imp p) (objc-object o) (objc-selector sel))
	       "id(*imp)(id, SEL, const char*);
                id  foo = ((IMP)*p)(*o, *sel);
                id* bar = &foo;
                C_return(bar);")))
  (lambda ()
    (proc imp class-object sel)))


(exit 0)

(let* ((testo-class   (class NSString))
       (testo-sel     (selector stringWithUTF8String:))
       (testo-sel2    (selector lengthOfBytesUsingEncoding:))
       (testo-method  (class-method    NSString stringWithUTF8String:))
       (testo-method2 (instance-method NSString lengthOfBytesUsingEncoding:)))

  (print "--- class method ---")
  (pp testo-sel)
  (pp testo-method)
  (pp (selector-get-name testo-sel))
  (pp (selector-get-name (method-get-name testo-method)))

  (let ((imp (class-get-method-imp (class NSAutoreleasePool) (selector new))))
    (pp imp)
    (pp ((foreign-lambda* objc-object ((objc-imp p) (objc-object o) (objc-selector sel) (c-string s) )
	   "
           IMP imp = *p;
           C_return(imp(*o,*sel, s));") imp testo-class testo-sel "muh!" )))
  
  (print "\n--- instance method ---")
  (pp testo-sel2)
  (pp testo-method2)
  (pp (selector-get-name testo-sel2))
  (pp (selector-get-name (method-get-name testo-method2))))


(define (class-list)
  (let ((class-count (objc-get-class-list #f 0)))
    (let-location ((classes objc-class (allocate (* objc-class-size class-count))))
      (let ((return-count (objc-get-class-list classes class-count)))
	(let ((fin-proc (let ((c return-count))
			  (lambda (p)
			    (if (= c 1)
				(free classes))
			    (set! c (- c 1))))))
	  (map (lambda (class-idx)
		 (set-finalizer! (pointer+ classes (* objc-class-size class-idx)) fin-proc))
	       (iota return-count)))))))

(map (lambda (method)
       (let ((selector (method-get-name method))
	     (arg-count (method-get-number-of-arguments method)))
	 (pp (selector-get-name selector))
	 (let loop ((i 0))
	   (unless (= i arg-count)
	     (pp (method-copy-argument-type method i))
	     (loop (+ i 1))))
	 (print "-----")))
     (let ((NSString (objc-get-class "NSString")))
       (let-location ((return-count unsigned-int))
	 (let ((methods (class-copy-method-list NSString (location return-count))))
	   (map (lambda (method-idx)
		  (pointer+ methods (* objc-method-size method-idx)) )
		(iota return-count))))))
