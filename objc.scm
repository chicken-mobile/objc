#>
#include <objc/objc.h>
#include <objc/runtime.h>
#import <Foundation/Foundation.h>
<#

(module objc
*
(import scheme chicken data-structures foreign)
(use srfi-1 lolevel dyncall)

(include "typedefs.scm")


(define objc-class
  (foreign-lambda objc-class objc_getClass c-string))
(define objc-lookup-class
  (foreign-lambda objc-class objc_lookUpClass c-string))
(define objc-required-class
  (foreign-lambda objc-class objc_getRequiredClass c-string))
(define objc-meta-class
  (foreign-lambda objc-meta-class objc_getMetaClass c-string))
(define objc-allocate-class-pair
  (foreign-lambda objc-class objc_allocateClassPair objc-class c-string size_t))
(define objc-register-class-pair
  (foreign-lambda void objc_registerClassPair objc-class))
(define objc-dispose-class-pair
  (foreign-lambda void objc_disposeClassPair objc-class))
(define objc-protocol
  (foreign-lambda objc-protocol objc_getProtocol c-string))
(define objc-class-list*
  (foreign-lambda int objc_getClassList pointer-vector int))
(define (objc-class-count)
  (objc-class-list* #f 0))
(define (objc-class-list)
  (let* ((class-count (objc-class-count))
         (array (set-finalizer! (make-pointer-vector class-count) free))
	 (return-count (objc-class-list* array class-count)))
    (map (lambda (i)
	   (make-objc-class (tag-pointer (pointer-vector-ref array i) array)))
	 (iota return-count))))

(define selector*
  (foreign-lambda objc-selector sel_registerName c-string))
(define selector-name
  (foreign-lambda c-string sel_getName objc-selector))
(define selector-equal?
  (foreign-lambda bool sel_isEqual objc-selector objc-selector))

(define object-class
  (foreign-lambda objc-class object_getClass objc-class))
(define object-class-name
  (foreign-lambda c-string object_getClassName objc-object))
(define object-clone
  (foreign-lambda objc-object object_copy objc-object size_t))
(define object-dispose
  (foreign-lambda objc-object object_dispose objc-object))
(define object-ivar
  (foreign-lambda objc-ivar object_getInstanceVariable objc-object c-string (c-pointer (c-pointer void))))
(define object-ivar-set!
  (foreign-lambda objc-ivar object_setInstanceVariable objc-object c-string (c-pointer void)))
(define object-ivar-value
  (foreign-lambda objc-object object_getIvar objc-object objc-ivar))
(define object-ivar-value-set!
  (foreign-lambda void object_setIvar objc-object objc-ivar objc-object))

(define ivar-name
  (foreign-lambda c-string ivar_getName objc-ivar))

(define class-meta-class?
  (foreign-lambda bool objc_isMetaClass objc-class))
(define class-super-class
  (foreign-lambda objc-class class_getSuperclass objc-class))
(define class-version
  (foreign-lambda int class_getVersion objc-class))
(define class-version-set!
  (foreign-lambda void class_setVersion objc-class int))
(define class-instance-size
  (foreign-lambda size_t class_getInstanceSize objc-class))
(define class-method-imp
  (foreign-lambda objc-imp class_getMethodImplementation objc-class objc-selector))
(define class-name
  (foreign-lambda c-string class_getName objc-class))
(define class-create-instance
  (foreign-lambda objc-object class_createInstance objc-class unsigned-int))
(define class-method*
  (foreign-lambda objc-method class_getClassMethod objc-class objc-selector))
(define class-method
  (foreign-lambda objc-method class_getInstanceMethod objc-class objc-selector))
(define class-responds-to
  (foreign-lambda bool class_respondeToSelector objc-class objc-selector))
(define class-add-method
  (foreign-lambda bool class_addMethod objc-class objc-selector objc-imp c-string))
(define class-replace-method
  (foreign-lambda bool class_addMethod objc-class objc-selector objc-imp c-string))
(define class-add-ivar
  (foreign-lambda bool class_addIvar objc-class c-string size_t unsigned-int c-string))
(define class-property
  (foreign-lambda objc-property class_getProperty objc-class c-string))
(define class-add-protocol
  (foreign-lambda bool class_addProtocol objc-class objc-protocol))
(define class-conforms-to?
  (foreign-lambda bool class_conformsToProtocol objc-class objc-protocol))
(define class-method-list*
  (foreign-lambda (c-pointer "struct objc_method") class_copyMethodList  objc-class (c-pointer unsigned-int)))
(define (class-method-list objc-class)
  (let ((method-type-size (foreign-type-size "Method")))
    (let-location ((return-count unsigned-int 0))
      (let ((array (set-finalizer! (class-method-list* objc-class (location return-count)) free)))
	(map (lambda (i)
	       (make-objc-method (tag-pointer (pointer+ array (* i method-type-size)) array)))
	     (iota return-count))))))


(define meta-class-name
  (lambda args (print (cadr args))))

(define property-name
  (foreign-lambda c-string property_getName objc-property))
(define property-attributes
  (foreign-lambda c-string property_getAttributes objc-property))

(define protocol-conforms-to?
  (foreign-lambda bool protocol_conformsToProtocol objc-protocol objc-protocol))
(define protocol-equal?
  (foreign-lambda bool protocol_isEqual objc-protocol objc-protocol))
(define protocol-name
  (foreign-lambda c-string protocol_getName objc-protocol))
(define protocol-property
  (foreign-lambda objc-property protocol_getProperty objc-protocol c-string bool bool))


(define method-implementation-set!
  (foreign-lambda objc-imp method_setImplementation objc-method objc-imp))
(define method-exchange-implementations 
  (foreign-lambda void method_exchangeImplementations objc-method objc-method))

;; for some reason im not wise enough to know this works not like all the others
;; when dealing with methods that came from class-method-list which may loose type
;; information for the compiler but i cant think why whis could harm anything :S
(define method-name
  (foreign-lambda* objc-selector ((objc-method m))
    "C_return(((struct objc_selector*)method_getName(m)));"))
(define method-return-type
  (foreign-lambda* c-string ((objc-method m))
    "C_return(method_copyReturnType(*((Method*)m)));"))
(define method-argument-length
  (foreign-lambda* int ((objc-method m))
    "C_return(method_getNumberOfArguments(*((Method*)m)));"))
(define method-argument-type
  (foreign-lambda* c-string ((objc-method m) (unsigned-int i))
    "C_return(method_copyArgumentType(*((Method*)m), i));"))
(define method-implementation
  (foreign-lambda* objc-imp ((objc-method m))
    "C_return(method_getImplementation(*((Method*)m)));"))
(define method-description
  (foreign-lambda* objc-method-description ((objc-method m))
    "C_return(((struct objc_method_description*)method_getDescription(*((Method*)m))));"))


(define class-ivar*
  (foreign-lambda objc-ivar class_getClassVariable objc-class c-string))
(define class-ivar
  (foreign-lambda objc-ivar class_getInstanceVariable objc-class c-string))




(include "macro-defs.scm"))
