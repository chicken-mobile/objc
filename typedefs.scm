(define (objc-record->objc-ptr x)
  (record-instance-slot x 0))
(define (print-objc-record out x info)
  (fprintf out "#<~A [~A] 0x~x>" 
	   (record-instance-type x) (info x)
	   (pointer->address (objc-record->objc-ptr x))))

(define-record objc-object pointer)
(define-record-printer (objc-object x out)
  (print-objc-record out x object-class-name))
(define-foreign-type objc-object   (c-pointer "struct objc_object")
  objc-record->objc-ptr make-objc-object)


(define-record objc-class pointer)
(define-record-printer (objc-class x out)
    (print-objc-record out x class-name))
(define-foreign-type objc-class (c-pointer "struct objc_class")
  objc-record->objc-ptr make-objc-class)


(define-record objc-meta-class pointer)
(define-record-printer (objc-meta-class x out)
  (print-objc-record out x object-class-name))
(define-foreign-type objc-meta-class    (c-pointer "struct objc_class")
  objc-record->objc-ptr make-objc-meta-class)


(define-record objc-method pointer)
(define-record-printer (objc-method x out)
  (print-objc-record out x (compose selector-name method-name)))
(define-foreign-type objc-method   (c-pointer "struct objc_method")
  objc-record->objc-ptr make-objc-method)

(define-record objc-selector pointer)
(define-record-printer (objc-selector x out)
  (print-objc-record out x selector-name))
(define-foreign-type objc-selector (c-pointer "struct objc_selector")
  objc-record->objc-ptr make-objc-selector)


(define-foreign-type objc-imp c-pointer)
