(include "typedefs.scm")
(use objc)

(let ((some-class (class NSString)))
  
  (for-each 
   (lambda (some-method)
     (let ((some-method-description (method-description some-method)))
       (print)
       (pp some-method)
       (pp
	(map (lambda (x)
	       (let* ((argument-type-string (method-argument-type some-method x))
		      (type-int (char->integer (string-ref argument-type-string 0)))
		      (type-char (char->type-char type-int)))
		 (pp argument-type-string)
		 (cond
		  ((= type-char/objc-struct-begin type-int)
		   (let* ((struct-info (string-split (string-drop argument-type-string 1) "=")))
		     (cons 'objc-struct
			   (cons (string->symbol (car struct-info))
				 (list
				  (let loop ((types (string->list (cadr struct-info))))
				    (if (= (char->integer (car types)) type-char/objc-struct-end)
					'() (cons (char->type-char (char->integer (car types))) (loop (cdr types))))))))))
		  (else type-char))))
	     (iota (method-argument-length some-method))))))
   (class-method-list some-class)))

