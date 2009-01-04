(load "objc")
(import objc)
(use expand-full srfi-13 srfi-18 dyncall trace)
(trace-module 'dyncall)

(define class-name object-get-class-name)

;; (ppexpand* '(dyncall*     vm c-pointer func-ptr              (c-pointer a0) (int a1) (float a2)))
;; (ppexpand* '(dyncall         c-pointer func-ptr              (c-pointer a0) (int a1) (float a2)))
;; (ppexpand* '(dyncall-lambda  void func-ptr              c-pointer))
;; (ppexpand* '(dyncall-lambda* void (lib-ptr symbol-name) c-pointer))

;; (let* ((libc (dl-load-library "/lib/libc.so.6")))
;;   (let ((testo (dyncall-lambda* void (libc printf) c-string c-string)))
;;     (testo "Hello World %s\n" "miautz")))

;; (pp (class-name (class NSAutoreleasePool)))
;; (pp (class-method NSString (selector stringWithUTF8String:)))

;; (let* ((class-obj (class NSAutoreleasePool))
;;        (sel (selector* (bar "alloc")))
;;        (imp (method-get-implementation (class-get-class-method class-obj sel)))
;;        (meta-class (object-get-class class-obj)))

;;   (object-get-class-name 
;;    (dyncall c-pointer imp (c-pointer meta-class) (c-pointer sel)))

;;   (let ((NSAutoreleasePool-alloc (dyncall-lambda c-pointer imp c-pointer c-pointer))
;; 	(NSAutoreleasePool-init (dyncall-lambda c-pointer imp c-pointer c-pointer)))
;;     (object-get-class-name
;;      (NSAutoreleasePool-alloc meta-class sel))))


;; (method* NSString c-pointer alloc)
;; (method  NSString int length)
;; (method  NSString c-pointer StringWithUtf8String: c-string)
;; (method  NSString c-pointer StringWithUtf8String: c-string  AndSomeOtherFoo: c-pointer WithOptionBar: bool)
;; (method  NSString c-pointer c-string c-pointer bool)  ??? is this possible ??? hmm isnt a good idea afterall

(define-syntax class
  (er-macro-transformer
   (lambda (x r c)
     (let ((class-name (symbol->string (cadr x)))
	   (%objc-get-class (r 'objc-get-class)))
       `(,%objc-get-class ,class-name)))))




(define-syntax method*
  (er-macro-transformer
   (lambda (x r c)     
     (let ((class-name (cadr x))
	   (return-type (caddr x))
	   (method-sig (cdddr x)))

       (let ((%let (r 'let))
	     (%let* (r 'let*))
	     (%class (r 'class))
	     (%selector* (r 'selector*))
	     (%bar (r 'bar))
	     (%method-get-implementation (r 'method-get-implementation))
	     (%class-get-class-method (r 'class-get-class-method))
	     (%object-get-class (r 'object-get-class))	     
	     (%dyncall-lambda (r 'dyncall-lambda))
	     (%lambda (r 'lambda)))
	 
	 `(,%let* ((class-obj (,%class ,class-name))
		   (sel (,%selector* (,%bar "alloc")))
		   (m (,%class-get-class-method class-obj sel))
		   (imp (,%method-get-implementation m))
		   (meta-class (,%object-get-class class-obj))
		   (objc-func (,%dyncall-lambda c-pointer imp c-pointer c-pointer)))

		  (,%lambda ()
			   (objc-func meta-class sel))))))))

(define-syntax method
  (er-macro-transformer
   (lambda (x r c)     
     (let ((class-name (cadr x))
	   (return-type (caddr x))
	   (method-sig (symbol->string (cadddr x))))

       (let ((%let (r 'let))
	     (%let* (r 'let*))
	     (%class (r 'class))
	     (%selector* (r 'selector*))
	     (%bar (r 'bar))
	     (%method-get-implementation (r 'method-get-implementation))
	     (%class-get-instance-method (r 'class-get-instance-method))
	     (%object-get-class (r 'object-get-class))	     
	     (%dyncall-lambda (r 'dyncall-lambda))
	     (%lambda (r 'lambda)))
	 
	 `(,%let* ((class-obj (,%class ,class-name))
		   (sel (,%selector* (,%bar ,method-sig)))
		   (m (,%class-get-instance-method class-obj sel))
		   (imp (,%method-get-implementation m))
		   (objc-func (,%dyncall-lambda c-pointer imp c-pointer c-pointer)))

		  (,%lambda (a1)
			   (objc-func a1 sel))))))))




(let* ((objc-class (class NSAutoreleasePool))
       (meta-class (object-get-class objc-class))
       (sel (selector* (bar "alloc")))
       (m (class-get-class-method objc-class sel))
       (imp (method-get-implementation m)))

  (pp (class-get-name objc-class))
  (pp (class-get-name meta-class))
  (pp (selector-get-name sel))
  (pp (selector-get-name (method-get-name m)))
  (pp imp)

  (let ((katze (dyncall c-pointer imp (c-pointer meta-class) (c-pointer sel))))
    (let* ((objc-class (class NSAutoreleasePool))
	   (meta-class (object-get-class objc-class))
	   (sel (selector* (bar "init")))
	   (m (class-get-instance-method objc-class sel))
	   (imp (method-get-implementation m)))

      (pp (class-get-name objc-class))
      (pp (class-get-name meta-class))
      (pp (selector-get-name sel))
      (pp (selector-get-name (method-get-name m)))
      (pp imp)

      (pp (object-get-class-name (dyncall c-pointer imp (c-pointer katze) (c-pointer sel)))))))

(let* ((objc-class (class NSAutoreleasePool))
       (meta-class (object-get-class objc-class))
       (sel (selector* (bar "alloc")))
       (m (class-get-class-method objc-class sel))
       (imp (method-get-implementation m)))

  (pp (class-get-name objc-class))
  (pp (class-get-name meta-class))
  (pp (selector-get-name sel))
  (pp (selector-get-name (method-get-name m)))
  (pp imp)

  (let ((katze (dyncall c-pointer imp (c-pointer meta-class) (c-pointer sel))))
    (let* ((objc-class (class NSAutoreleasePool))
	   (meta-class (object-get-class objc-class))
	   (sel (selector* (bar "init")))
	   (m (class-get-instance-method objc-class sel))
	   (imp (method-get-implementation m)))

      (pp (class-get-name objc-class))
      (pp (class-get-name meta-class))
      (pp (selector-get-name sel))
      (pp (selector-get-name (method-get-name m)))
      (pp imp)

      (pp (object-get-class-name (dyncall c-pointer imp (c-pointer katze) (c-pointer sel)))))))


(exit -1)

(define-syntax dynmodule
  (syntax-rules ()
    ((_ lib-path module-name
	(return-type sym-name arg-type ...) ...)

     (module module-name
     *     
     (import scheme chicken dyncall)
     (let ((lib (dl-load-library lib-path)))
       (define miau
	 (dyncall-lambda* return-type (lib sym-name) arg-type ...)) ...)))))



(pp (expand
     '(dynmodule "libc.so.6" libc
		 (void sprintf c-string int))))
(pp (expand*
     '(dynmodule "libc.so.6" libc
		 (void sprintf c-string int))))

(dynmodule "libc" libcss
	   (c-string printf c-string int))
(import libcss)


(miau "Hello World %i\n" 123)
(flush-output)

;; (objc:msg* NSString alloc)
;; (objc:msg  nsstring length)
;; (objc:msg  (object-get-class (class NSString)) stringWithUTF8String: foostring)
;; (objc:msg  (meta-class NSString)               stringWithUTF8String: foostring)
;; (objc:msg* NSString                            stringWithUTF8String: foostring)
;; (objc:msg* nstring                             stringWithUTF8String: foostring)
;; (objc:msg  nstring                                   initWithString: foostring)

;; (% NSString alloc)
;; (% nsstring length)
;; (% NSString stringWithUTF8String: foostring)
;; (% nstring        initWithString: foostring)

;; (objc-lambda c-pointer NSAutoreleasePool alloc)







;; + [NSString alloc] =>
;; (objc-class-lambda NSString alloc)
;; + [NSString stringWithUTF8String:(const char*) initialString] =>
;; (objc-class-lambda NSString stringWithUTF8String: c-string)

;; (define-syntax objc-class-lambda
;;   (er-macro-transformer
;;    (lambda (x r c)
;;      (let* ((class-name (cadr x))
;; 	    (arg-map (chop (cddr x) 2))
;; 	    (sel-string (string-concatenate
;; 			 (map (lambda (arg)
;; 				(string-append arg ":"))
;; 			      (map symbol->string 
;; 				   (map car arg-map)))))

;; 	    (arg-names (map (lambda (i)
;; 			      (string->symbol (format "a~A" i)))
;; 			    (iota (length arg-map)))))
       
;;        `(let ((class-object (class ,class-name))
;; 	      (sel (selector* (bar ,sel-string)))
;; 	      (method (class-get-class-method class-object)))
;; 	  (lambda ,arg-names
;; 	    (void)))))))

;; (ppexpand* '(objc-class-lambda NSString stringWithUTF8String: c-string))
;; (ppexpand* '(objc-class-lambda NSString stringWithUTF8String: c-string andBar: boolean))
