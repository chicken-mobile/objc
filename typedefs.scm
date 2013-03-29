#>
#include <objc/objc.h>
#include <objc/runtime.h>
#import <Foundation/Foundation.h>
<#
(import extras)
(use foreigners)

(define (objc-record->objc-ptr x)
  (record-instance-slot x 0))
(define (print-objc-record out x info)
  (fprintf out "#<~A [~A] 0x~x>" 
	   (record-instance-type x) (info x)
	   (pointer->address (objc-record->objc-ptr x))))

(define-syntax define-objc-type
  (er-macro-transformer
   (lambda (x r c)
     (let* ((type-name (cadr x))
	    (record-print-proc (cddr x))
	    (record-print-proc (if (>= (length x) 3)
				   (caddr x)
				   (symbol-append type-name '-name)))
	    (c-type (if (= (length x) 4)
			(cadddr x) (symbol-append 'objc_ type-name)))
	    (s-type (symbol-append 'objc- type-name))
	    (make-record-proc (symbol-append 'make-objc- type-name)))

       (let ((%begin                 (r 'begin))
	     (%define-record         (r 'define-record))
	     (%define-record-printer (r 'define-record-printer))
	     (%print-objc-record     (r 'print-objc-record))
	     (%define-foreign-type   (r 'define-foreign-type))
	     (%objc-record->objc-ptr (r 'objc-record->objc-ptr))

	     (%record (r 'record))
	     (%out    (r 'out)))

	 `(,%begin
	    (,%define-record ,s-type pointer)
	    (,%define-record-printer (,s-type ,%record ,%out)
	      (,%print-objc-record ,%out ,%record ,record-print-proc))
	    (,%define-foreign-type ,s-type (c-pointer (struct ,c-type))
	      ,%objc-record->objc-ptr ,make-record-proc)))))))


(define-objc-type ivar)
(define-objc-type property)
(define-objc-type protocol protocol-name Protocol)
(define-objc-type object object-class-name)
(define-objc-type class)
(define-objc-type meta-class class-name obj_class)
(define-objc-type selector)
(define-objc-type method (compose selector-name method-name))
(define-foreign-type objc-imp c-pointer)


(define-foreign-enum-type (type-char char)
  (type-char->char char->type-char)

  ((void type-char/void) _C_VOID)
  ((bool type-char/bool) _C_BOOL)
  ((char type-char/char) _C_CHR)
  ((unsigned-char type-char/unsigned-char) _C_UCHR)
  ((short type-char/short) _C_SHT)
  ((unsigned-short type-char/unsigned-short) _C_USHT)
  ((int type-char/int) _C_INT)
  ((unsigned-int type-char/unsigned-int) _C_UINT)
  ((long type-char/long) _C_LNG)
  ((unsigned-long type-char/unsigned-long) _C_ULNG)
  ((integer64 type-char/integer64) _C_LNG_LNG)
  ((unsigned-integer64 type-char/unsigned-integer64) _C_ULNG_LNG)
  ((float type-char/float) _C_FLT)
  ((double type-char/double) _C_DBL)
  ((c-pointer type-char/c-pointer) _C_PTR)
  ((c-string type-char/c-string) _C_CHARPTR)       ;; char array ??
;;((long-double type-char/long-double) _C_LNG_DBL) ;; __float128 ???

  ((objc-objcect type-char/objc-object) _C_ID)
  ((objc-class type-char/objc-class) _C_CLASS)
  ((objc-selector type-char/objc-selector) _C_SEL) 
;;((objc-bitfield type-char/bitfield) _C_BFLD)
;;((objc-undefined type-char) _C_UNDEF)

  ((objc-array-begin type-char/objc-array-begin) _C_ARY_B)
  ((objc-array-end type-char/objc-array-end) _C_ARY_E)
  ((objc-union-begin type-char/objc-union-begin) _C_UNION_B)
  ((objc-union-end type-char/objc-union-end) _C_UNION_E)
  ((objc-struct-begin type-char/objc-struct-begin) _C_STRUCT_B)
  ((objc-struct-end type-char/objc-struct-end) _C_STRUCT_E)
  ((objc-vector type-char/objc-vector) _C_VECTOR)
  ((objc-complex type-char/objc-complex) _C_COMPLEX)

  ((objc-atom type-char/objc-atom) _C_ATOM)  ;; char array ??

  ((objc-const    type-char/objc-const) _C_CONST)
  ((objc-in       type-char/objc-in) _C_IN)
  ((objc-in-out   type-char/objc-in-out) _C_INOUT)
  ((objc-out      type-char/objc-out) _C_OUT)
  ((objc-by-copy  type-char/objc-by-copy) _C_BYCOPY)
  ((objc-by-ref   type-char/objc-by-ref) _C_BYREF)
  ((objc-one-way  type-char/objc-one-way) _C_ONEWAY)
  ((objc-gc-invisible type-char/gc-invisible) _C_GCINVISIBLE))

(define-foreign-record-type (method-description "struct objc_method_description")
  (constructor: make-method-description)
  (destructor:  free-method-description)
  (objc-selector name  method-description-sel   method-description-sel-set!)
  (c-string      types method-description-types method-description-types-set!))
