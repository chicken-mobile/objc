;;;; read-syntax for ObjC method calls - highly problematic for those that use [...] as list notation


(require 'srfi-1)

(use objc-compile-time)

(set-read-syntax! 
 #\[
 (lambda (port)
   (let* ((receiver (read port))
	  (msg (read port)) )
     (define (fail err . args)
       (syntax-error err (cons* receiver msg '... args)))
     (let loop ((args '()) (msg msg) (kw (keyword? msg)) (done (not (keyword? msg))))
       (let ((c (peek-char port)))
	 (cond ((eof-object? c)
		(fail "unexpected end of [ ... ]"))
	       ((char=? c #\])
		(read-char port)
		(if kw
		    (fail "missing argument in [ ... ]")
		    (let ((args (reverse args)))
		      `(send ,receiver ,msg ,@args))))
	       ((char-whitespace? c)
		(read-char port)
		(loop args msg kw done))
	       (kw
		(let ((x (read port)))
		  (loop (cons x args) msg #f #f)))
	       (else
		(let ((x (read port)))
		  (if (keyword? x)
		      (if done
			  (fail "unexpected argument in [ ... ]")
			  (loop args (append-keywords msg x) #t #f))
		      (fail "expected keyword in [ ... ]" x))))))))))
