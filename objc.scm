;;;; main interface


(import foreign)
(use lolevel data-structures ports concurrent-native-callbacks)

(begin-for-syntax
 (require-library objc-compile-time))
(import-for-syntax objc-compile-time)

(import-for-syntax chicken matchable fmt)

(include "objc-syntax.scm")

#;(define-syntax d
  (syntax-rules ()
    ((_ args ...)
     (with-output-to-port (current-error-port)
       (lambda () (print args ...))))))

(define-syntax d
  (syntax-rules () ((_ args ...) (void))))

;(declare (unsafe))

(import bind)


#>
#include <dyncall.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#ifdef __APPLE__
#include <Block.h>
#include <dispatch/dispatch.h>
#endif

#ifdef __GNUSTEP__
# define _NATIVE_OBJC_ECXEPTIONS
#elif defined(__APPLE__) && !defined(__arm__)
# include <objc/objc-runtime.h>
# include <objc/objc-class.h>
#endif

#if defined(__APPLE__)
//XXX this is possibly doing a second message lookup on Mac/iOS
static void *objc_msg_lookup(void *rec, void *sel)
{
  Class c = object_getClass(rec);

  return class_getMethodImplementation(c, sel);
}

static void *objc_msg_lookup_super(struct objc_super *sup, void *sel)
{
#if !defined(__cplusplus)  &&  !__OBJC2__
  Class c = sup->class;
#else
  Class c = sup->super_class;
#endif

  return class_getMethodImplementation(c, sel);
}
#else
static void *Block_copy(void *x) { return NULL; }
static void Block_release(void *x) {}
#endif
<#

(bind #<<EOF

void *Block_copy(void *);
void Block_release(void *);

void dcFree(DCCallVM *);

void dcArgChar(DCCallVM *, char);
void dcArgShort(DCCallVM *, short);
void dcArgInt(DCCallVM *, int);
void dcArgLong(DCCallVM *, long);
void dcArgLongLong(DCCallVM *, ___number);
void dcArgFloat(DCCallVM *, float);
void dcArgDouble(DCCallVM *, double);
void dcArgPointer(DCCallVM *, void *);

___safe void dcCallVoid(DCCallVM *, void *);
___safe char dcCallChar(DCCallVM *, void *);
___safe short dcCallShort(DCCallVM *, void *);
___safe int dcCallInt(DCCallVM *, void *);
___safe long dcCallLong(DCCallVM *, void *);
___safe ___number dcCallLongLong(DCCallVM *, void *);
___safe float dcCallFloat(DCCallVM *, void *);
___safe double dcCallDouble(DCCallVM *, void *);
___safe void *dcCallPointer(DCCallVM *, void *);

void *sel_registerName(char *);
char *sel_getName(void *);
void *object_getClass(void *);
void *class_getInstanceMethod(void *, void *);
void *class_getClassMethod(void *, void *);
void *objc_getClass(char *);
char *class_getName(void *);
void *class_getSuperclass(void *);

void *object_getInstanceVariable(void *, char *, void *);
char *ivar_getTypeEncoding(void *);
int ivar_getOffset(void *);
___bool class_isMetaClass(void *);
void *objc_msg_lookup(void *, void *);

EOF
)

(bind* #<<EOF

___safe static char *call_with_string_result(DCCallVM *vm, void *ptr) { 
  return dcCallPointer(vm, ptr); 
}

static void push_string_argument(DCCallVM *vm, char *ptr) { dcArgPointer(vm, ptr); }

static DCCallVM *begin_call_setup() { 
  DCCallVM *vm = dcNewCallVM(4096);
  dcMode(vm, DC_CALL_C_DEFAULT);
  dcReset(vm);
  return vm;
}

static char ivar_char_ref(Ivar *v, void *obj, int off) { return *((char *)((char *)obj + off)); }
static short ivar_short_ref(Ivar *v, void *obj, int off) { return *((short *)((char *)obj + off)); }
static int ivar_int_ref(Ivar *v, void *obj, int off) { return *((int *)((char *)obj + off)); }
static long ivar_long_ref(Ivar *v, void *obj, int off) { return *((long *)((char *)obj + off)); }
static ___number ivar_longlong_ref(Ivar *v, void *obj, int off) { return *((long long *)((char *)obj + off)); }
static void *ivar_ptr_ref(Ivar *v, void *obj, int off) { return *((void **)((char *)obj + off)); }
static char *ivar_string_ref(Ivar *v, void *obj, int off) { return *((char **)((char *)obj + off)); }
static float ivar_float_ref(Ivar *v, void *obj, int off) { return *((float *)((char *)obj + off)); }
static double ivar_double_ref(Ivar *v, void *obj, int off) { return *((double *)((char *)obj + off)); }

static void ivar_char_set(Ivar *v, void *obj, int off, char x) { *((char *)((char *)obj + off)) = x; }
static void ivar_short_set(Ivar *v, void *obj, int off, short x) { *((short *)((char *)obj + off)) = x; }
static void ivar_int_set(Ivar *v, void *obj, int off, int x) { *((int *)((char *)obj + off)) = x; }
static void ivar_long_set(Ivar *v, void *obj, int off, long x) { *((long *)((char *)obj + off)) = x; }
static void ivar_longlong_set(Ivar *v, void *obj, int off, ___number x) { *((long long *)((char *)obj + off)) = x; }
static void ivar_ptr_set(Ivar *v, void *obj, int off, void *x) { *((void **)((char *)obj + off)) = x; }
static void ivar_string_set(Ivar *v, void *obj, int off, char *x) { *((char **)((char *)obj + off)) = x; }
static void ivar_float_set(Ivar *v, void *obj, int off, float x) { *((float *)((char *)obj + off)) = x; }
static void ivar_double_set(Ivar *v, void *obj, int off, double x) { *((double *)((char *)obj + off)) = x; }

static char *get_method_description_types(void *mth) { 
#ifdef __APPLE__
  return (char *)method_getTypeEncoding(mth);
#else
  return method_getDescription(mth)->types; 
#endif
}

static void *lookup_message_for_superclass(void *s, void *sel) {
  struct objc_super sc;
#ifdef __APPLE__
  sc.receiver = s;
#else
  sc.self = s;
#endif
#if defined(__APPLE__) && !defined(__cplusplus)  &&  !__OBJC2__
  sc.class = class_getSuperclass(object_getClass(s));
#else
  sc.super_class = class_getSuperclass(object_getClass(s));
#endif
  return objc_msg_lookup_super(&sc, sel);
}

___safe void *create_invocation_block(DCCallVM *vm, void *imp) { 
#ifdef __APPLE__
  void (^b)() = ^{ dcCallVoid(vm, imp); dcFree(vm); };
  Block_copy(b);
  return b;
#else
  fprintf(stderr, "\"@/block\" is not available on this platform.\n");
  exit(1);
#endif
}

___safe void dispatch_invocation_block(DCCallVM *vm, void *imp) { 
#ifdef __APPLE__
  dispatch_async(dispatch_get_main_queue(), 
		 ^{ dcCallVoid(vm, imp); 
	            dcFree(vm); });
#else
  fprintf(stderr, "\"@/main-thread\" is not available on this platform.\n");
  exit(1);
#endif
}

EOF
)


(define (object? x)
  (tagged-pointer? x 'objective-c-object))

(define (make-object ptr)
  (and ptr
       (tag-pointer ptr 'objective-c-object)))

(define (check-object x loc)
  ;;XXX loc not used yet
  (cond ((not x) #f)
	((pointer? x) (make-object x))
	(else (error loc "not an object" x))))

(define *enable-inline-cache* #f)	;XXX #t

(define (get-method class sel)
  (cond-expand
    (macosx
     (if (class_isMetaClass class)
	 (class_getClassMethod class sel)
	 (class_getInstanceMethod class sel)))
    (else (class_getInstanceMethod class sel))))

(define (skip-type p str)
  (let ((len (string-length str)))
    (let loop ((i p) (d #f) (beyond #f))
      (if (fx>= i len)
	  (if d
	      (error 'lookup-method "incomplete signature" str)
	      len)
	  (let ((c (string-ref str i)))
	    (if d
		(loop (fx+ i 1) (not (char=? d c)) #t)
		(case c
		  ((#\r #\R #\o #\O #\V #\n #\N #\^)
		   (if beyond
		       i
		       (loop (fx+ i 1) #f #f)))
		  ((#\() (loop (fx+ i 1) #\) #f))
		  ((#\{) (loop (fx+ i 1) #\} #f))
		  ((#\[) (loop (fx+ i 1) #\] #f))
		  (else
		   (cond ((char-numeric? c) (loop (fx+ i 1) #f beyond))
			 (beyond i)
			 (else (loop (fx+ i 1) #f #t)))))))))))

(define (build-argument-passing types invoke selector)
  (let-syntax ((dpush
		(syntax-rules ()
		  ((_ op k)
		   (lambda (vm args)
		     (op vm (car args))
		     (k vm (cdr args)))))))
    (let ((len (string-length types)))
      (let loop ((i (skip-type 0 types)))
	(if (fx>= i len)
	    invoke
	    (let ((t (string-ref types i))
		  (k (loop (skip-type i types))))
	      (case t
		((#\c #\C)
		 ;; hack around absent "bool" type
		 (lambda (vm args)
		   (let ((x (car args)))
		     (dcArgChar
		      vm
		      (case x
			((#f) #\x00)
			((#t) #\x01)
			(else x)))
		     (k vm (cdr args)))))
		((#\s #\S) (dpush dcArgShort k))
		((#\b #\i #\I) (dpush dcArgInt k))
		((#\l #\L) (dpush dcArgLong k))
		((#\Q #\q) (dpush dcArgLongLong k))
		((#\f) (dpush dcArgFloat k))
		((#\d #\D) (dpush dcArgDouble k))
		((#\*) 
		 (lambda (vm args)
		   (push_string_argument vm (car args))
		   (k vm (cdr args))))
		((#\r #\R #\n #\N #\o #\O #\V)
		 (loop (fx+ i 1)))
		((#\^) (dpush dcArgPointer k))
		((#\:) (lambda (vm args)
			 (dcArgPointer vm (check-selector (car args) 'lookup-method))
			 (k vm (cdr args))))
		((#\@ #\#) 
		 (lambda (vm args)
		   (dcArgPointer vm (check-object (car args) 'lookup-method))
		   (k vm (cdr args))))
		(else
		 (error "unsupported argument type" types 
			(string-append (make-string i #\space) "^") ; aren't we clever?
			selector)))))))))

(define (build-invocation types imp selector)
  (let-syntax ((dcall
		(syntax-rules ()
		  ((_ op imp)
		   (lambda (vm args)
		     (let ((r (op vm imp)))
		       (dcFree vm)
		       r))))))
    (let loop ((i 0))
      (case (string-ref types i)
	((#\v)
	 (lambda (vm args)
	   (dcCallVoid vm imp)))
	((#\c #\C) 
	 (lambda (vm args)
	   ;; hack around absent "bool" type
	   (let ((r (dcCallChar vm imp)))
	     (dcFree vm)
	     (if (char=? #\x00 r) #f r))))
	((#\s #\S) (dcall dcCallShort imp))
	((#\b #\i #\I) (dcall dcCallInt imp))
	((#\l #\L) (dcall dcCallLong imp))
	((#\q #\Q) (dcall dcCallLongLong imp))
	((#\f) (dcall dcCallFloat imp))
	((#\d #\D) (dcall dcCallDouble imp))
	((#\* #\%) (dcall call_with_string_result imp))
	((#\r #\R #\n #\N #\o #\O #\V) (loop (fx+ i 1)))
	((#\^) (dcall dcCallPointer imp))
	((#\:) (lambda (vm args)
		 (let ((r (make-selector (dcCallPointer vm imp))))
		   (dcFree vm)
		   r)))
	((#\@ #\#)
	 (lambda (vm args) 
	   (let ((r (make-object (dcCallPointer vm imp))))
	     (dcFree vm)
	     r)))
	(else (error "unsupported result type" types selector))))))

(define (make-caller receiver sel push)
  (lambda args
    (push (begin_call_setup) (cons receiver (cons sel args)))))

(define (lookup-method/call receiver selector cache argc super?)
  (let ((class (object_getClass (check-object receiver 'lookup-method))))
    (d "[" receiver " (" (class_getName class) ") " selector " - cache: " cache "]")
    (cond ((not class) (error "invalid object pointer" receiver selector))
	  ((and *enable-inline-cache* (equal? (##sys#slot cache 0) class))
	   (d "[cache hit " cache "]")
	   (make-caller receiver (##sys#slot cache 1) (##sys#slot cache 2)))
	  (else
	   (let* ((sel (sel_registerName selector))
		  (mth (get-method class sel)))
	     (if mth
		 (let* ((types (get_method_description_types mth))
					;(_ (print "types: " selector " - " types))
			(len (string-length types))
			(imp ((if super? lookup_message_for_superclass objc_msg_lookup) receiver sel))
			(selobj (make-selector sel))
			(invoke (build-invocation types imp selector))
			(push (build-argument-passing types invoke selector))
			(call (make-caller receiver selobj push)))
		   (when *enable-inline-cache*
		     (##sys#setslot cache 0 class)
		     (##sys#setslot cache 1 selobj)
		     (##sys#setslot cache 2 push)
		     (d "[updated cache " cache "]"))
		   call)
		 (error "method not found" receiver selector)))))))

;; this one does not cache
(define (lookup-method/block receiver selector argc super?)
  (let ((class (object_getClass (check-object receiver 'lookup-method))))
    (d "[(block) " receiver " (" (class_getName class) ") " selector "]")
    (cond ((not class) (error "invalid object pointer" receiver selector))
	  (else
	   (let* ((sel (sel_registerName selector))
		  (mth (get-method class sel)))
	     (if mth
		 (let* ((types (get_method_description_types mth))
			(len (string-length types))
			(imp ((if super? lookup_message_for_superclass objc_msg_lookup) receiver sel))
			(selobj (make-selector sel))
			(invoke (lambda (vm args) 
				  (tag-pointer (create_invocation_block vm imp) 'block)))
			(push (build-argument-passing types invoke selector))
			(call (make-caller receiver selobj push)))
		   call)
		 (error "method not found" receiver selector)))))))

;; this one does not cache as well
(define (lookup-method/main-thread receiver selector argc super?)
  (let ((class (object_getClass (check-object receiver 'lookup-method))))
    (d "[(block) " receiver " (" (class_getName class) ") " selector "]")
    (cond ((not class) (error "invalid object pointer" receiver selector))
	  (else
	   (let* ((sel (sel_registerName selector))
		  (mth (get-method class sel)))
	     (if mth
		 (let* ((types (get_method_description_types mth))
			(len (string-length types))
			(imp ((if super? lookup_message_for_superclass objc_msg_lookup) receiver sel))
			(selobj (make-selector sel))
			(invoke (lambda (vm args) (dispatch_invocation_block vm imp)))
			(push (build-argument-passing types invoke selector))
			(call (make-caller receiver selobj push)))
		   call)
		 (error "method not found" receiver selector)))))))

(define (find-class name #!optional (err #t))
  (make-object
   (or (objc_getClass (->string name))
       (and err (error "class not found" name)))))

(define (lookup-ivar obj name loc)
  (let ((ivar (object_getInstanceVariable (check-object obj loc) (->string name) #f)))
    (unless ivar
      (error loc "instance variable not found in object" name obj))
    ivar))

;;XXX this is supposed to be slow, we could use caching here
(define (object-set! obj var x)
  (let* ((ivar (lookup-ivar obj var 'object-set!))
	 (enc (ivar_getTypeEncoding ivar))
	 (off (ivar_getOffset ivar))
	 (len (string-length enc)))
    (let loop ((i 0))
      (case (string-ref enc i)
	((#\c #\C)
	 ;; hack around absent "bool" type
	 (ivar_char_set 
	  ivar obj off
	  (case x
	    ((#t) #\x01)
	    ((#f) #\x00)
	    (else x))))
	((#\s #\S) (ivar_short_set ivar obj off x))
	((#\b #\i #\I) (ivar_int_set ivar obj off x))
	((#\l #\L) (ivar_long_set ivar obj off x))
	((#\q #\Q) (ivar_longlong_set ivar obj off x))
	((#\f) (ivar_float_set ivar obj off x))
	((#\d #\D) (ivar_double_set ivar obj off x))
	((#\*) (ivar_string_set ivar obj off x))
	((#\r #\R #\n #\N #\o #\O #\V)
	 (loop (fx+ i 1)))
	((#\^) (ivar_ptr_set ivar obj off x))
	((#\:) (ivar_ptr_set ivar obj off (check-selector x 'object-set!)))
	((#\@ #\#) (ivar_ptr_set ivar obj off (check-object x 'object-set!)))
	(else (error 'object-set! "unsupported instance-variable type" var enc obj))))))

;;XXX s.a.
(define object-ref
  (getter-with-setter
   (lambda (obj var)
     (let* ((ivar (lookup-ivar obj var 'object-ref))
	    (enc (ivar_getTypeEncoding ivar))
	    (off (ivar_getOffset ivar))
	    (len (string-length enc)))
       (let loop ((i 0))
	 (case (string-ref enc i)
	   ((#\c #\C)
	    ;; hack around absent "bool" type
	    (let ((c (ivar_char_ref ivar obj off)))
	      (case c
		((#\x00) #f)
		((#\x01) #t)
		(else c))))
	   ((#\s #\S) (ivar_short_ref ivar obj off))
	   ((#\b #\i #\I) (ivar_int_ref ivar obj off))
	   ((#\l #\L) (ivar_long_ref ivar obj off))
	   ((#\Q #\q) (ivar_longlong_ref ivar obj off))
	   ((#\f) (ivar_float_ref ivar obj off))
	   ((#\d) (ivar_double_ref ivar obj off))
	   ((#\*) (ivar_string_ref ivar obj off))
	   ((#\r #\R #\n #\N #\o #\O #\V)
	    (loop (fx+ i 1)))
	   ((#\^) (ivar_ptr_ref ivar obj off))
	   ((#\:) (make-selector (ivar_ptr_ref ivar obj off)))
	   ((#\@ #\#) (make-object (ivar_ptr_ref ivar obj off)))
	   (else (error 'object-ref "unsupported instance-variable type" var enc obj))))))
   object-set!))

(define Object (find-class "Object"))

(define (make-selector ptr)
  (tag-pointer ptr 'objective-c-selector))

(define (selector? x)
  (tagged-pointer? x 'objective-c-selector))

(define (check-selector x loc)
  (assert (selector? x) "not a selector" x)
  x)

(define (selector->string sel)
  (sel_getName (check-selector sel 'selector->string)))

(define (string->selector str)
  (make-selector (sel_registerName str)))

(define (class? x)
  (and x
       (object? x)
       (class_isMetaClass (class-of x))))

(define (metaclass? x)
  (and x
       (object? x)
       (class_isMetaClass x)))

(define (class-name obj)
  (if obj
      (let ((cls (check-object obj 'class-name)))
	(if (class? cls) 
	(class_getName (check-object obj 'class-name))
	(error 'class-name "not a class" obj)))
      "Nil"))

(define (class-of obj)
  (and obj
       (make-object (object_getClass (check-object obj 'class-of)))))

(define (superclass-of cls)
  (and cls
       (if (class? cls)
	   (make-object (class_getSuperclass cls))
	   (error 'superclass-of "not a class" cls))))

(define nil #f)

;;XXX why do these exist?
(define ##objc#make-object make-object)
(define ##objc#make-selector make-selector)

(define (block-copy block)
  (assert (tagged-pointer? block 'block) "not a block" block)
  (tag-pointer (Block_copy block) 'block))

(define (block-release! block)
  (assert (tagged-pointer? block 'block) "not a block" block)
  (Block_release block))
