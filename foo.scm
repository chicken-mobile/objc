(use expand-full trace objc dyncall srfi-18 lolevel)

(trace-module 'objc)
(untrace objc-class-pointer make-objc-class class-name
	 objc-meta-class-pointer make-objc-meta-class meta-class-name
	 objc-object-pointer make-objc-object object-class-name
	 objc-method-pointer make-objc-method method-name
	 objc-selector-pointer make-objc-selector selector-name
	 objc-record->objc-ptr print-objc-record object-dispose
	 objc-class-list class-method-list)

;;(ppexpand* '(objc-lambda* c-pointer NSAutoreleasePool  alloc))
;;(ppexpand* '(objc-lambda  c-pointer NSAutoreleasePool   init))


(let ((sel (selector "alloc")))
  (pp (selector-name sel)))

(let* ((some-method (car (class-method-list (class NSString))))
       (arg-length (method-argument-length some-method))
       (arg-types (map (lambda (x)
			 (method-argument-type some-method x))
		       (iota arg-length)))
       (return-type (method-return-type some-method)))
  
  (pp some-method)
  (pp return-type)
  (pp arg-length)
  (pp arg-types))

(ppexpand* '(objc-lambda* c-pointer NSAutoreleasePool alloc))


(let ((bar (selector* "init"))
      (baz (objc-class "NSAutoreleasePool")))
  (pp bar)
  (pp baz)
  (pp (class-method-imp baz bar))
  (pp (class-method baz bar))
  (pp (selector-name (method-name (class-method baz bar))))
)



(define arp-alloc 
  (objc-lambda* c-pointer NSAutoreleasePool alloc))
(define arp-init
  (objc-lambda c-pointer  NSAutoreleasePool init ))

(define retain
  (objc-lambda c-pointer NSObject retain))
(define release
  (objc-lambda void NSObject release))
(define dealloc
  (objc-lambda void NSObject dealloc))
(define auto-release
  (objc-lambda void NSObject autorelease))

(define retain-count
  (objc-lambda int NSObject retainCount))


(print "\n\n")

(let ((arp (arp-init (arp-alloc))))
  (pp arp))




(exit -1)

(define string-alloc
  (objc-lambda* c-pointer NSString alloc))
(define string-init-with-cstring
  (objc-lambda* c-pointer NSString initWithUTF8String: c-string otherFoo: ))


(pp (string-init-with-cstring (string-alloc)))



;; (method* NSString c-pointer alloc)
;; (method  NSString int length)
;; (method  NSString c-pointer StringWithUtf8String: c-string)
;; (method  NSString c-pointer StringWithUtf8String: c-string  AndSomeOtherFoo: c-pointer WithOptionBar: bool)
;; (method  NSString c-pointer c-string c-pointer bool)  ??? is this possible ??? hmm isnt a good idea afterall

;; + [NSString alloc] =>
;; (objc-lambda* NSString alloc)
;; + [NSString stringWithUTF8String:(const char*) initialString] =>
;; (objc-lambda* NSString stringWithUTF8String: c-string)

;; (ppexpand* '(objc-lambda* NSString stringWithUTF8String: c-string))
;; (ppexpand* '(objc-lambda* NSString stringWithUTF8String: c-string andBar: boolean))


;; (objc:msg* NSString alloc)
;; (objc:msg  nsstring length)
;; (objc:msg  (object-get-class (class NSString)) stringWithUTF8String: foostring)
;; (objc:msg  (meta-class NSString)               stringWithUTF8String: foostring)
;; (objc:msg* NSString                            stringWithUTF8String: foostring)
;; (objc:msg* nstring                             stringWithUTF8String: foostring)
;; (objc:msg  nstring                                   initWithString: foostring)

;; (% NSString alloc)
;; (% nsstring length)
;; (% NSString stringWithUTF8String: foostring)
;; (% nstring        initWithString: foostring)

