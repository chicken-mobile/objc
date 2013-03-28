(define (objc-record->objc-ptr x)
  (record-instance-slot x 0))
(define (print-objc-record out x info)
  (fprintf out "#<~A [~A] 0x~x>" 
	   (record-instance-type x) (info x)
	   (pointer->address (objc-record->objc-ptr x))))

(define-syntax define-objc-type
  (er-macro-transformer
   (lambda (x r c)
     (let* ((type-name (cadr x))
	    (record-print-proc (cddr x))
	    (record-print-proc (if (>= (length x) 3)
				   (caddr x)
				   (symbol-append type-name '-name)))
	    (real-type-name (if (= (length x) 4)
				(cadddr x) type-name))

	    (make-record-proc (symbol-append 'make-objc- type-name))
	    (s-type (symbol-append 'objc- type-name))
	    (c-type (symbol-append 'objc_ real-type-name)))

       (let ((%define-record         (r 'define-record))
	     (%define-record-printer (r 'define-record-printer))
	     (%print-objc-record     (r 'print-objc-record))
	     (%define-foreign-type   (r 'define-foreign-type))
	     (%objc-record->objc-ptr (r 'objc-record->objc-ptr)))
	 `(begin
	    (,%define-record ,s-type pointer)
	    (,%define-record-printer (,s-type x out)
	      (,%print-objc-record out x ,record-print-proc))
	    (,%define-foreign-type ,s-type (c-pointer (struct ,c-type))
	      ,%objc-record->objc-ptr ,make-record-proc)))))))


(define-objc-type object object-class-name)
(define-objc-type class)
(define-objc-type meta-class class-name class)
(define-objc-type selector)
(define-objc-type method (compose selector-name method-name))

(define-foreign-type objc-imp c-pointer)




