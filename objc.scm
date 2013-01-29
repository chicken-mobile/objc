#>
#include <objc/objc.h>
#include <objc/runtime.h>
<#

(use extras lolevel srfi-1)

(define-foreign-type objc-class (c-pointer "struct objc_class"))
(define objc-class-size
  (foreign-value "sizeof(Class)" size_t))
(define objc-get-class-list
  (foreign-lambda int objc_getClassList (c-pointer objc-class) int))

(define class-get-name
  (foreign-lambda* c-string (((c-pointer "Class") clazz))
    "C_return(class_getName(*clazz));"))


(let ((class-count (objc-get-class-list #f 0)))
  (let-location ((classes objc-class (allocate (* objc-class-size class-count))))
    (let* ((return-count (objc-get-class-list classes class-count))
	   (class-list 
	    (fold (lambda (class-idx class-list)
		    (cons (pointer+ classes (* objc-class-size class-idx)) class-list))
		  '() (iota return-count))))

      (for-each (lambda (class)
		  (print (class-get-name class)))
		class-list)
      (free classes))))



