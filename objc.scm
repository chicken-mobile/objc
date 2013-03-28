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
(define objc-meta-class
  (foreign-lambda objc-meta-class objc_getMetaClass c-string))
(define objc-meta-class?
  (foreign-lambda bool objc_isMetaClass objc-class))


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

(define meta-class-name
  (lambda args (print (cadr args))))

(define selector-name
  (foreign-lambda c-string sel_getName objc-selector))
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
(define object-dispose
  (foreign-lambda void object_dispose objc-object))


(define method-implementation
  (foreign-lambda objc-imp method_getImplementation objc-method))
(define method-argument-length
  (foreign-lambda int method_getNumberOfArguments objc-method))
(define method-argument-type
  (foreign-lambda c-string method_copyArgumentType objc-method unsigned-int))
(define method-name
  (foreign-lambda objc-selector method_getName objc-method))

(include "macro-defs.scm"))
