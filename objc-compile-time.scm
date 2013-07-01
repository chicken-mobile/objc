;;;; common expansion-time code


(module objc-compile-time (append-keywords
			   split-selector
			   parse-interface
			   parse-implementation
			   parse-selector-list
			   core-foreign-type-declaration
			   objc-foreign-type-declaration
			   format-interface-declaration
			   format-implementation-definition)

(import scheme chicken matchable)
(use miscmacros fmt srfi-1 data-structures)

(include "foreign-types.scm")

(define (append-keywords m1 . ms)
  (if (null? ms)
      m1
      (string->keyword
       (string-intersperse
	(map keyword->string (if m1 (cons m1 ms) ms))
	":"))))

(define (split-selector sel)
  (if (keyword? sel)
      (map string->keyword (string-split (symbol->string sel) ":"))
      (list sel)))

(define (parse-interface class form loc)
  (let ((def '())
	(prot '@protected))
    (define (type+name lst)
      (match lst
	(((type) name . more)
	 (values (list name type) more))
	(_ (syntax-error loc "invalid syntax in declaration" class lst))))
    (for-each
     (match-lambda
       (('field type name)
	(push! `(,name field ,type ,prot) def))
       ((and p (or '@protected '@public '@private))
	(set! prot p))
       (((and i (or '- '+ '-/async '+/async)) (rtype) name+args ...)
	(let-values (((sel args) (parse-selector-list name+args type+name loc)))
	  (push! (cons* sel i rtype args) def)))
       (((and i (or '- '+ '-/async '+/async)) name+args ...)
	(let-values (((sel args) (parse-selector-list name+args type+name loc)))
	  (push! (cons* sel i 'id args) def)))
       (x (syntax-error loc "invalid declaration" class x)))
     form)
    (reverse def)))

(define (parse-implementation class form loc)
  (let ((def '()))
    (define (type+name lst)
      (match lst
	(((type) name . more)
	 (values (list name type) more))
	(_ (syntax-error loc "invalid syntax in definition" class lst))))
    (let loop ()
      (unless (null? form)
	(match (pop! form)
	  ((((and i (or '- '+ '-/async '+/async)) (rtype) name+args ...) body ...)
	   (let-values (((sel args) (parse-selector-list name+args type+name loc)))
	     (push! (list sel i rtype args body) def)))
	  ((((and i (or '- '+ '-/async '+/async)) name+args ...) body ...)
	   (let-values (((sel args) (parse-selector-list name+args type+name loc)))
	     (push! (list sel i 'id args body) def)))
	  (x (syntax-error loc "invalid definition" class x)))
	(loop)))
    (reverse def)))

(define (parse-selector-list lst elt loc)
  (match lst
    ((sel1)
     (if (keyword? sel1)
	 (syntax-error loc "missing arguments" sel1)
	 (values sel1 '())))
    (_ (let loop ((lst lst) (sel #f) (acc '()))
	 (match lst
	   (() (values sel (reverse acc)))
	   (((? keyword? kw) . more)
	    (let-values (((result more) (elt more)))
	      (loop more (append-keywords sel kw) (cons result acc))))
	   (x (syntax-error loc "missing keyword in declaration" lst)))))))

(define (format-interface-declaration name parent def)
  (fmt #f
       nl "@interface " name " : " parent " {" nl
       (apply-cat
	(filter-map
	 (match-lambda
	   ((name 'field type prot)
	    (fmt #f nl prot " " (objc-foreign-type-declaration type (symbol->string name)) ";" nl))
	   (_ #f))
	 def))
       "}" nl
       (apply-cat
	(filter-map
	 (match-lambda
	   ((_ 'field _ _) #f)
	   ((sel i rtype args ...)
	    (let ((sels (split-selector sel)))
	      (fmt #f 
		   (case i
		     ((+/async) '+)
		     ((-/async) '-)
		     (else i))
		   "(" (objc-foreign-type-declaration rtype "") ")"
		   (if (null? args)
		       (car sels)
		       (apply-cat
			(map (lambda (s a)
			       (fmt #f s " (" (objc-foreign-type-declaration (cadr a) "") ")" (car a) " "))
			     sels args)))
		   ";" nl))))
	 def))
       nl "@end" nl))

(define (format-implementation-definition name defs handlers)
  (fmt #f 
       nl
       (apply-cat ; we have to generate prototypes to avoid requiring "-emit-external-prototypes-first"
	(map (lambda (def h)
	       (match def
		 ((sel i rtype args _)
		  (fmt #f 
		       "static " (core-foreign-type-declaration rtype "") " " h "(void *"
		       (apply-cat
			(map (lambda (a)
			       (string-append "," (core-foreign-type-declaration (cadr a) "")))
			     args) )
		       ");\n"))))
	     defs handlers))
       nl "@implementation " name nl
       (apply-cat
	(map (lambda (def h)
	       (match def
		 ((sel i rtype args _)
		  (let ((sels (split-selector sel)))
		    (fmt #f 
			 (case i
			   ((+/async) '+)
			   ((-/async) '-)
			   (else i))
			 "(" (objc-foreign-type-declaration rtype "") ")" 
			 (if (null? args)
			     (car sels)
			     (apply-cat
			      (map (lambda (s a)
				     (fmt #f s " (" (objc-foreign-type-declaration (cadr a) "") ")" (car a) " "))
				   sels args)))
			 " { "
			 (if (eq? 'void rtype) "" "return ")
			 h "(self" (apply-cat (map (lambda (a)
						     (fmt #f "," (car a)))
						   args))
			 "); }\n")))))
	     defs handlers))
       nl "@end" nl))

)
