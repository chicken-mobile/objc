;;;; syntactic definitions for ObjC


(define-syntax objc-import
  (lambda (x r c)
    `(,(r 'foreign-declare)
      ,@(map (lambda (imp)
	       (fmt #f nl "#import "
		    (if (char=? #\< (string-ref imp 0))
			imp
			(string-append "\"" imp "\""))
		    nl))
	     (cdr x)))))

(define-syntax define-objc-class
  (lambda (x r c)
    `(,(r 'foreign-declare) ,(fmt #f "@class " (fmt-join dsp (strip-syntax (cdr x)) ",")))))

;;XXX do we need this?
(define-syntax declare-objc-interface
  (lambda (x r c)
    (let* ((name (strip-syntax (cadr x)))
	   (parent (strip-syntax (caddr x)))
	   (def (parse-interface name (strip-syntax (cdddr x)) 'declare-objc-interface)))
      (put! name 'objc:interface def)
      (put! name 'objc:parent parent)
      `(,(r 'define) ,name (,(r 'find-class) ,(symbol->string name))))))

(define-syntax define-objc-interface
  (lambda (x r c)
    (define (process name parent decls)
      (let ((def (parse-interface name decls 'define-objc-interface)))
	(put! name 'objc:interface def)
	(put! name 'objc:parent parent)
	`(,(r 'begin)
	  (,(r 'foreign-declare) ,(format-interface-declaration name parent def))
	  (,(r 'define) ,name (,(r 'find-class) ,(symbol->string name))))))
    (match (strip-syntax (cdr x))
      ((name ': parent decls ...)
       (process name parent decls))
      ((name decls ...)
       (process name 'Object decls))
      (x (syntax-error 'define-objc-interface "invalid interface declaration" x)))))

(define-syntax define-objc-implementation
  (lambda (x r c)
    (let* ((name (strip-syntax (cadr x)))
	   (defs (parse-implementation name (strip-syntax (cddr x)) 'define-objc-implementation))
	   (handlers (map (match-lambda
			    ((sel . _)
			     (gensym (string-append
				      "C___" (symbol->string name) "___" 
				      (string-translate (symbol->string sel) ":" "_")
				      "___handler"))) )
			  defs))
	   (%begin (r 'begin))
	   (%foreign-declare (r 'foreign-declare))
	   (%define-external (r 'define-external))
	   (%define-synchronous-concurrent-native-callback (r 'define-synchronous-concurrent-native-callback)))
      `(,%begin
	(,%foreign-declare
	 ,(format-implementation-definition name defs handlers))
	,@(map (lambda (def h)
		 (match def
		   ((sel i rtype args body)
		    ;;XXX unfortunately this is externally visible
		    `(,(if (memq i '(+/async -/async))
			   %define-synchronous-concurrent-native-callback
			   %define-external)
		      (,h (c-pointer self)     ; intentionally unhygienic
			  ,@(map (match-lambda
				   ((name type) (list type name)))
				 args))
		      ,(if (eq? 'id rtype) 'c-pointer rtype)
		      ,@body))))
	       defs handlers)))))		   
      
(define-syntax send
  (lambda (x r c)
    (match x
      ((_ receiver msg args ...)
       (let ((%rec (r 'rec))
	     (%sel (r 'sel))
	     (%quote (r 'quote))
	     (%cache (r 'cache))
	     (super (c 'super receiver)))
	 `(,(r 'let*) ((,%rec ,(if super 'self receiver))
		       (,%sel ,(fmt #f (apply-cat (split-selector (strip-syntax msg)))))
		       (,%cache (,%quote ,(make-vector 3 #f)))) ; #(CLASS SEL CALL)
	   ((,(r 'lookup-method/call) ,%rec ,%sel ,%cache ,(length args) ,super) ,@args)))))))

(define-syntax send/block
  (lambda (x r c)
    (match x
      ((_ receiver msg args ...)
       (let ((%rec (r 'rec))
	     (%sel (r 'sel))
	     (%quote (r 'quote))
	     (%cache (r 'cache))
	     (super (c 'super receiver)))
	 `(,(r 'let*) ((,%rec ,(if super 'self receiver))
		       (,%sel ,(fmt #f (apply-cat (split-selector (strip-syntax msg))))))
	   ((,(r 'lookup-method/block) ,%rec ,%sel ,(length args) ,super) ,@args)))))))

(define-syntax send/main-thread
  (lambda (x r c)
    (match x
      ((_ receiver msg args ...)
       (let ((%rec (r 'rec))
	     (%sel (r 'sel))
	     (%quote (r 'quote))
	     (%cache (r 'cache))
	     (super (c 'super receiver)))
	 `(,(r 'let*) ((,%rec ,(if super 'self receiver))
		       (,%sel ,(fmt #f (apply-cat (split-selector (strip-syntax msg))))))
	   ((,(r 'lookup-method/main-thread) ,%rec ,%sel ,(length args) ,super) ,@args)))))))

;;XXX this could expand into "(foreign-value ...)" if in compilation mode
(define-syntax @selector
  (lambda (x r c)
    (match x
      ((_ name)
       (let ((name (cond ((keyword? name)
			  (string-append (keyword->string name) ":"))
			 ((symbol? name) (symbol->string (strip-syntax name)))
			 (else (syntax-error '@selector "bad selector" name)))))
	`(,(r 'string->selector) ,name)))))) ;XXX cache?

(define-syntax @
  (lambda (x r c)
    (match x
      ((_ recv args ...)
       (let-values (((sel args) (parse-selector-list args car+cdr '@)))
	 `(,(r 'send) ,recv ,sel ,@args))))))

(define-syntax @/block
  (lambda (x r c)
    (match x
      ((_ recv args ...)
       (let-values (((sel args) (parse-selector-list args car+cdr '@)))
	 `(,(r 'send/block) ,recv ,sel ,@args))))))

(define-syntax @/main-thread
  (lambda (x r c)
    (match x
      ((_ recv args ...)
       (let-values (((sel args) (parse-selector-list args car+cdr '@)))
	 `(,(r 'send/main-thread) ,recv ,sel ,@args))))))
