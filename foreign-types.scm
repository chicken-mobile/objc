;; foreign-type conversion - taken from c-backend.scm


(define core-foreign-type-declaration 
  (if (or (memq #:compiling ##sys#features)
	  (memq #:compiler-extension ##sys#features))
      ##compiler#foreign-type-declaration
      (lambda _
	(error "interface- and implementation-declarations can only be used in compiled code."))))

(define (objc-foreign-type-declaration type target)
  (let ((err (lambda () (syntax-error "illegal foreign type" type)))
	(str (lambda (ts) (string-append ts " " target))) )
    (case type
      ((scheme-object) (str "C_word"))
      ((char byte) (str "C_char"))
      ((unsigned-char unsigned-byte) (str "unsigned C_char"))
      ((unsigned-int unsigned-integer) (str "unsigned int"))
      ((unsigned-int32 unsigned-integer32) (str "C_u32"))
      ((int integer bool) (str "int"))
      ((size_t) (str "size_t"))
      ((int32 integer32) (str "C_s32"))
      ((integer64) (str "C_s64"))
      ((unsigned-integer64) (str "C_u64"))
      ((short) (str "short"))
      ((long) (str "long"))
      ((unsigned-short) (str "unsigned short"))
      ((unsigned-long) (str "unsigned long"))
      ((float) (str "float"))
      ((double number) (str "double"))
      ((c-pointer nonnull-c-pointer scheme-pointer nonnull-scheme-pointer)
       (str "void *"))
      ((c-string-list c-string-list*) "C_char **")
      ((blob nonnull-blob u8vector nonnull-u8vector)
       (str "unsigned char *"))
      ((u16vector nonnull-u16vector)
       (str "unsigned short *"))
      ((s8vector nonnull-s8vector) 
       (str "char *"))
      ((u32vector nonnull-u32vector)
       (str "unsigned int *"))
      ((s16vector nonnull-s16vector)
       (str "short *"))
      ((s32vector nonnull-s32vector)
       (str "int *"))
      ((f32vector nonnull-f32vector)
       (str "float *"))
      ((f64vector nonnull-f64vector)
       (str "double *"))
      ((pointer-vector nonnull-pointer-vector) (str "void **"))
      ((nonnull-c-string c-string nonnull-c-string* c-string* symbol) 
       (str "char *"))
      ((nonnull-unsigned-c-string nonnull-unsigned-c-string* 
				  unsigned-c-string unsigned-c-string*)
       (str "unsigned char *"))
      ((void) (str "void"))
      ((sel SEL) (str "SEL"))
      ((id) (str "id"))
      ((imp IMP Class class Method method id) (str "void *"))
      (else
       (cond
	((and (symbol? type) 
	      (##sys#hash-table-ref ##compiler#foreign-type-table type))
	 => (lambda (t)
	      (objc-foreign-type-declaration (if (vector? t) (vector-ref t 0) t) target)) )
	((string? type) (str type))
	((list? type)
	 (let ((len (length type)))
	   (cond 
	    ((and (= 2 len)
		  (memq (car type)
			'(pointer nonnull-pointer c-pointer 
				  nonnull-c-pointer) ) )
	     (objc-foreign-type-declaration
	      (cadr type)
	      (string-append "*" target)) )
	    ((and (= 2 len)
		  (eq? 'ref (car type)))
	     (objc-foreign-type-declaration
	      (cadr type)
	      (string-append "&" target)) )
	    ((and (> len 2)
		  (eq? 'template (car type)))
	     (str
	      (string-append 
	       (objc-foreign-type-declaration (cadr type) "")
	       "<"
	       (string-intersperse
		(map (cut objc-foreign-type-declaration <> "") (cddr type))
		",")
	       "> ") ) )
	    ((and (= len 2) (eq? 'const (car type)))
	     (string-append
	      "const " 
	      (objc-foreign-type-declaration (cadr type) target)))
	    ((and (= len 2) (eq? 'struct (car type)))
	     (string-append
	      "struct "
	      (->string (cadr type)) " " target))
	    ((and (= len 2) (eq? 'union (car type)))
	     (string-append "union " (->string (cadr type)) " " target))
	    ((and (= len 2) (eq? 'enum (car type)))
	     (string-append "enum " (->string (cadr type)) " " target))
	    ((and (= len 3) 
		  (memq (car type) 
			'(instance nonnull-instance)))
	     (string-append (->string (cadr type)) "*" target))
	    ((and (= len 3) (eq? 'instance-ref (car type)))
	     (string-append (->string (cadr type)) "&" target))
	    ((and (>= len 3) (eq? 'function (car type)))
	     (let ((rtype (cadr type))
		   (argtypes (caddr type))
		   (callconv (optional (cdddr type) "")))
	       (string-append
		(objc-foreign-type-declaration rtype "")
		callconv
		" (*" target ")("
		(string-intersperse
		 (map (lambda (at)
			(if (eq? '... at) 
			    "..."
			    (objc-foreign-type-declaration at "") ) )
		      argtypes) 
		 ",")
		")" ) ) )
	    (else (err)) ) ) )
	(else (err)) ) ) ) ) )

;;; Hack Objective-C specific foreign types into compiler (if compiling) to avoid
;   requiring foreign-type definitions. This is really dirty.

(when (or (memq #:compiling ##sys#features)
	  (memq #:compiler-extension ##sys#features))
  (##sys#hash-table-set! ##compiler#foreign-type-table 'id '#(c-pointer identity ##objc#make-object))
  (##sys#hash-table-set! ##compiler#foreign-type-table 'sel '#(c-pointer identity ##objc#make-selector))
  (##sys#hash-table-set! ##compiler#foreign-type-table 'SEL '#(c-pointer identity ##objc#make-selector))
  (##sys#hash-table-set! ##compiler#foreign-type-table 'Class '#(c-pointer identity ##objc#make-object))
  (##sys#hash-table-set! ##compiler#foreign-type-table 'class '#(c-pointer identity ##objc#make-object)))
