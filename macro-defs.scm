(define-syntax class
  (er-macro-transformer
   (lambda (x r c)
     (let ((class-name (symbol->string (cadr x)))
	   (%objc-class (r 'objc-class)))
       `(,%objc-class ,class-name)))))
(define-syntax meta-class
  (er-macro-transformer
   (lambda (x r c)
     (let ((class-name (symbol->string (cadr x)))
	   (%objc-meta-class (r 'objc-meta-class)))
       `(,%objc-meta-class ,class-name)))))

(define-syntax objc-lambda
  (er-macro-transformer
   (lambda (x r c)
     (let ((return-type (cadr x))
	   (class-name (caddr x))
	   (selector-map (cdddr x)))
       `(let* ((sel (selector ,(car selector-map)))
	       (objc-class (class ,class-name))
	       (imp (class-method-imp objc-class sel))
	       (proc (dyncall-lambda ,return-type imp c-pointer c-pointer)))
	  (lambda (x)
	    ,(if (eq? return-type 'c-pointer)
		 `(make-objc-object (proc (objc-record->objc-ptr x) (objc-record->objc-ptr sel)))
		 `(proc (objc-record->objc-ptr x) (objc-record->objc-ptr sel)))))))))

(define-syntax objc-lambda*
  (er-macro-transformer
   (lambda (x r c)
     (let ((return-type (cadr x))
	   (class-name (caddr x))
	   (selector-map (cdddr x)))
       (let ((arg-types '())
	     (arg-names '()))
	 `(let* ((sel (selector ,(car selector-map)))
		 (c (class ,class-name))
		 (mc (meta-class ,class-name))
		 (imp (class-method-imp mc sel))
		 (proc (dyncall-lambda ,return-type imp c-pointer c-pointer ,@arg-types)))
	    (lambda ,arg-names
	      ,(if (eq? return-type 'c-pointer)
		   `(make-objc-object (proc (objc-record->objc-ptr c) (objc-record->objc-ptr sel) ,@arg-names))
		   `(proc (objc-record->objc-ptr c) (objc-record->objc-ptr sel) ,@arg-names)))))))))

(define-syntax selector
  (er-macro-transformer
   (lambda (x r c)
     (let* ((selector-symbol (cadr x))
	    (%selector* (r 'selector*))
	    (%symbol->string (r 'symbol->string)))       
       `(,%selector* 
	 ,(if (string? selector-symbol)
	      selector-symbol
	      `(,%symbol->string (quote ,selector-symbol))))))))
