#>
#include <objc/objc.h>
#include <objc/runtime.h>
#import <Foundation/Foundation.h>
<#

(module objc
*
(import scheme chicken data-structures foreign)
(use lolevel dyncall)

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


(define selector-name
  (foreign-lambda c-string sel_getName objc-selector))
(define selector-register
  (foreign-lambda objc-selector sel_registerName c-string))
(define selector-equal?
  (foreign-lambda bool sel_isEqual objc-selector objc-selector))
(define selector*
  (foreign-lambda* objc-selector ((c-string name))    
    "NSString* baz = [NSString stringWithUTF8String: name];
     SEL  foo = NSSelectorFromString(baz);
     [baz release];
     C_return(foo);"))

(define object-class
  (foreign-lambda objc-class object_getClass objc-class))
(define object-class-name
  (foreign-lambda c-string object_getClassName objc-object))
(define object-clone
  (foreign-lambda objc-object object_copy objc-object size_t))
(define object-dispose
  (foreign-lambda void object_dispose objc-object))


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

(define meta-class-name
  (lambda args (print (cadr args))))


(define method-implementation
  (foreign-lambda objc-imp method_getImplementation objc-method))
(define method-implementation-set!
  (foreign-lambda objc-imp method_setImplementation objc-method objc-imp))
(define method-exchange-implementations 
  (foreign-lambda void method_exchangeImplementations objc-method objc-method))
(define method-argument-length
  (foreign-lambda int method_getNumberOfArguments objc-method))

(define method-copy-argument-type
  (foreign-lambda c-string method_copyArgumentType objc-method unsigned-int))
(define method-argument-type
  (foreign-lambda void method_getArgumentType objc-method unsigned-int c-string size_t))

(define method-copy-return-type
  (foreign-lambda c-string method_copyReturnType objc-method))
(define method-return-type
  (foreign-lambda void method_getReturnType objc-method c-string size_t))

(define method-name
  (foreign-lambda objc-selector method_getName objc-method))

(include "macro-defs.scm"))
