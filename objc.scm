#>
#include <objc/objc.h>
#include <objc/runtime.h>
<#

(use extras lolevel srfi-1)

(define-foreign-type objc-object   (c-pointer "id"))
(define-foreign-type objc-selector (c-pointer "struct objc_selector")) ;; hmmm
(define-foreign-type objc-class    (c-pointer "Class"))
(define-foreign-type objc-method   (c-pointer "Method"))

(define objc-class-size
  (foreign-value "sizeof(Class)" size_t))
(define objc-method-size
  (foreign-value "sizeof(Method)" size_t))
(define objc-get-class-list
  (foreign-lambda int objc_getClassList objc-class int))
(define objc-get-class
  (foreign-lambda objc-class objc_getClass c-string))

(define class-get-name
  (foreign-lambda* c-string ((objc-class clazz))
    "C_return(class_getName(*clazz));"))
(define class-copy-method-list
  (foreign-lambda* objc-method ((objc-class clazz) ((c-pointer unsigned-int) count))
    "C_return(class_copyMethodList(*clazz, count));"))


(define object-get-class
  (foreign-lambda* objc-class ((objc-object object))
    "C_return(object_getClass((id)*object));"))


(define method-get-name
  (foreign-lambda* objc-selector ((objc-method method))
    "C_return(method_getName(*method));"))


(define selector-get-name
  (foreign-lambda* c-string ((objc-selector s))
    "C_return(sel_getName(s));")) ;;hmmm!


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
       (let ((testo (method-get-name method)))
	 (pp (selector-get-name testo))))
     (let ((NSString (objc-get-class "NSString")))
       (let-location ((return-count unsigned-int))
	 (let ((methods (class-copy-method-list NSString (location return-count))))
	   (map (lambda (method-idx)
		  (pointer+ methods (* objc-method-size method-idx)) )
		(iota return-count))))))
