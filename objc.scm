#>
#include <objc/objc.h>
#include <objc/runtime.h>
<#

(use extras lolevel srfi-1)

(define-foreign-type objc-class (c-pointer "Class"))
(define objc-class-size
  (foreign-value "sizeof(Class)" size_t))
(define objc-get-class-list
  (foreign-lambda int objc_getClassList objc-class int))

(define class-get-name
  (foreign-lambda* c-string ((objc-class clazz))
    "C_return(class_getName(*clazz));"))


(define (class-list)
  (let ((class-count (objc-get-class-list #f 0)))
    (let-location ((classes objc-class (allocate (* objc-class-size class-count))))
      (let ((return-count (objc-get-class-list classes class-count)))
	(map (lambda (class-idx)
	       (pointer+ classes (* objc-class-size class-idx)))
	     (iota return-count))))))

(for-each 
 (lambda (class)
   (print (class-get-name class)))
 (class-list))



