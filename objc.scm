#>
#include <objc/objc.h>
#include <objc/runtime.h>
#import <Foundation/Foundation.h>
<#

(module objc
	*
(import scheme chicken foreign)
(use lolevel dyncall)

(define (objc-record->objc-ptr x)
  (record-instance-slot x 0))
(define (print-objc-record out name class-name address)
  (fprintf out "#<~A [~A] 0x~x>" name class-name address))


(define-record objc-object pointer)
(define-record-printer (objc-object x out)
  (let ((ptr (objc-record->objc-ptr x)))
    (print-objc-record out (record-instance-type x) (object-get-class-name* ptr) (pointer->address ptr))))
(define-foreign-type objc-object   (c-pointer "id")
  objc-record->objc-ptr make-objc-object)


(define-record objc-class  pointer)
(define-record-printer (objc-class x out)
  (let ((ptr (objc-record->objc-ptr x)))
    (print-objc-record out (record-instance-type x) (object-get-class-name* ptr) (pointer->address ptr))))
(define-foreign-type objc-class   (c-pointer "Class")
  objc-record->objc-ptr make-objc-class)


(define-record objc-meta-class pointer)
(define-record-printer (objc-meta-class x out)
  (let ((ptr (objc-record->objc-ptr x)))
    (print-objc-record out (record-instance-type x) "MetaClass" (pointer->address ptr))))
(define-foreign-type objc-meta-class    (c-pointer "Class")
  objc-record->objc-ptr make-objc-meta-class)


(define-record objc-method  pointer)
(define-record-printer (objc-method x out)
  (let ((ptr (objc-record->objc-ptr x)))
    (print-objc-record out (record-instance-type x) (selector-get-name (method-get-name* ptr)) (pointer->address ptr))))
(define-foreign-type objc-method   (c-pointer "Method")
  objc-record->objc-ptr make-objc-method)



;; typedefs
(define-foreign-type objc-selector (c-pointer "SEL"))
(define-foreign-type objc-imp      c-pointer)


;;;;
;; runtime
;;;;
(define objc-get-class
  (foreign-lambda* objc-class ((c-string class_name))
    "Class  foo  = objc_getClass(class_name);
     Class* bar = &foo;
     C_return(bar);"))


;; classes
(define class-get-name*
  (foreign-lambda* c-string (((c-pointer c-pointer) clazz))
    "C_return(class_getName(*clazz));"))
(define class-get-name
  (foreign-lambda* c-string ((objc-class clazz))
    "C_return(class_getName(*clazz));"))
(define class-create-instance
  (foreign-lambda* objc-object ((objc-class clazz) (unsigned-int b))
    "C_return(class_createInstance(*clazz, b));"))
(define class-copy-method-list
  (foreign-lambda* objc-method ((objc-class clazz) ((c-pointer unsigned-int) count))
    "C_return(class_copyMethodList(*clazz, count));"))
(define class-get-class-method
  (foreign-lambda* objc-method ((objc-class clazz) (objc-selector selector))
    "C_return(class_getClassMethod(*clazz, *selector));"))
(define class-get-class-method
  (foreign-lambda* objc-method ((objc-class clazz) (objc-selector selector))
    "Method  foo = class_getClassMethod(*clazz, *selector);
     Method* bar = &foo;
     C_return(bar);"))
(define class-get-instance-method
  (foreign-lambda* objc-method ((objc-class clazz) (objc-selector selector))
    "Method  foo = class_getInstanceMethod(*clazz, *selector);
     Method* bar = &foo;
     C_return(bar);"))
(define class-get-method-imp
  (foreign-lambda* objc-imp ((objc-class clazz) (objc-selector selector))
    "IMP  foo = class_getMethodImplementation(*clazz, *selector);
     IMP* bar = &foo;
     C_return(bar);"))
(define class-get-meta-class
  (foreign-lambda* objc-meta-class ((objc-class object))
    "Class  foo = object_getClass(*object);
     Class* bar = &foo;
     C_return(bar);"))
(define class-get-meta-class*
  (foreign-lambda* (c-pointer "Class") (((c-pointer "Class") object))
    "Class  foo = object_getClass(*object);
     Class* bar = &foo;
     C_return(bar);"))


;; objects 
(define object-get-class
  (foreign-lambda* objc-class ((objc-object object))
    "Class  foo = object_getClass(*object);
     Class* bar = &foo;
     C_return(bar);"))

(define object-set-class
  (foreign-lambda* objc-class ((objc-object object) (objc-class clazz))
    "C_return(object_setClass(*object, *clazz));"))
(define object-get-class-name*
  (foreign-lambda* c-string (((c-pointer c-pointer) o))
    "C_return(object_getClassName(*o));"))
(define object-get-class-name
  (foreign-lambda* c-string ((objc-object o))
    "C_return(object_getClassName(*o));"))
(define object-dispose
  (foreign-lambda* void ((objc-object o))
    "C_return(object_dispose(*o));"))

;; methods
(define method-get-name
  (foreign-lambda* objc-selector ((objc-method method))
    "SEL  foo = method_getName(*method);
     SEL* bar = &foo;
     C_return(bar);"))
(define method-get-name*
  (foreign-lambda* objc-selector (((c-pointer "Method") method))
    "SEL  foo = method_getName(*method);
     SEL* bar = &foo;
     C_return(bar);"))
(define method-get-implementation
  (foreign-lambda* objc-imp ((objc-method method))
    "IMP  foo = method_getImplementation(*method);
     IMP* bar = &foo;
     C_return(foo);"))
(define method-get-number-of-arguments
  (foreign-lambda* int ((objc-method method))
    "C_return(method_getNumberOfArguments(*method));"))
(define method-copy-argument-type
  (foreign-lambda* c-string ((objc-method method) (unsigned-int i))
    "C_return(method_copyArgumentType(*method, i));"))

;; selector
;; this will always return a valid (thats not a <null selector>) 
;; thats if at runtime is not defined is useless of course ^^
(define sel->objc-selector
  (foreign-lambda* objc-selector ((objc-selector s)) "
    SEL  foo = (SEL)s;
    SEL* bar = &foo;
    C_return(bar);"))
(define selector-get-name
  (foreign-lambda* c-string ((objc-selector s))
    "C_return(sel_getName(*s));"))

;; experimental
;; (define objc-class-size
;;   (foreign-value "sizeof(Class)" size_t))
;; (define objc-method-size
;;   (foreign-value "sizeof(Method)" size_t))
;; (define objc-get-class-list
;;   (foreign-lambda int objc_getClassList scheme-pointer int))

(define ns-string
  (foreign-lambda* objc-object ((c-string string))
    "NSString* foo = [NSString stringWithUTF8String: string];
     C_return(&foo);"))

;;;;
;; macros
;;;;

(define-syntax selector
  (er-macro-transformer
   (lambda (x r c)
     (let ((selector-name (cadr x))
	   (%sel->objc-selector (r 'sel->objc-selector))
	   (%foreign-value (r 'foreign-value)))
       `(,%sel->objc-selector (,%foreign-value ,(format "@selector(~A)" selector-name) objc-selector))))))

(define selector*
  (foreign-lambda* objc-selector ((c-string name))    
    "// NSString* baz = [[NSString alloc] initWithUTF8String: name]; :((((
     NSString* baz = [NSString stringWithUTF8String: name];
     SEL  foo = NSSelectorFromString(baz);
     SEL* bar = &foo;
     // [baz retain];
     C_return(bar);"))

(define-syntax class
  (er-macro-transformer
   (lambda (x r c)
     (let ((class-name (symbol->string (cadr x)))
	   (%objc-get-class (r 'objc-get-class)))
       `(,%objc-get-class ,class-name)))))
(define-syntax class-method
  (er-macro-transformer
   (lambda (x r c)
     (let ((class-name (cadr x))
	   (selector-name (caddr x))
	   (%class-get-class-method (r 'class-get-class-method))
	   (%class (r 'class))
	   (%selector (r 'selector)))
       `(,%class-get-class-method (,%class ,class-name) (,%selector ,selector-name))))))
(define-syntax instance-method
  (er-macro-transformer
   (lambda (x r c)
     (let ((class-name (cadr x))
	   (selector-name (caddr x))
	   (%class-get-instance-method (r 'class-get-instance-method))
	   (%class (r 'class))
	   (%selector (r 'selector)))
       `(,%class-get-instance-method (,%class ,class-name) (,%selector ,selector-name))))))


(define-syntax objc-lambda
  (er-macro-transformer
   (lambda (x r c)
     (let ((return-type (cadr x))
	   (class-name (caddr x))
	   (selector-map (cdddr x)))
       `(let* ((sel (selector* ,(symbol->string (car selector-map))))
	       (objc-class (class ,class-name))
	       (imp  (method-get-implementation (class-get-instance-method objc-class sel)))
	       (proc (dyncall-lambda ,return-type imp c-pointer c-pointer)))
	  (lambda (x)
	    (make-objc-object (proc (objc-record->objc-ptr x) sel))))))))

(define-syntax objc-lambda*
  (er-macro-transformer
   (lambda (x r c)
     (let ((return-type (cadr x))
	   (class-name (caddr x))
	   (selector-map (cdddr x)))
       (let ((arg-types '())
	     (arg-names '()))
	 `(let* ((sel (selector* ,(symbol->string (car selector-map))))
		 (objc-class (class ,class-name))
		 (meta-class (class-get-meta-class objc-class))		 
		 (m (class-get-class-method objc-class sel))
		 (imp  (method-get-implementation m))
		 (proc (dyncall-lambda ,return-type imp c-pointer c-pointer ,@arg-types)))
	    (object-dispose objc-class)
	    (object-dispose m)
	    (lambda ,arg-names
	      ,(if (eq? return-type 'objc-object)
		   `(set-finalizer! (proc (objc-record->objc-ptr meta-class) sel ,@arg-names) object-dispose)
		   `(make-objc-object (proc (objc-record->objc-ptr meta-class) sel ,@arg-names))))))))))
)
