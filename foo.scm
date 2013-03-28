(use expand-full trace objc dyncall srfi-18)

(trace-module 'objc)
(untrace objc-class-pointer make-objc-class class-name
	 objc-meta-class-pointer make-objc-meta-class meta-class-name
	 objc-object-pointer make-objc-object object-class-name
	 objc-method-pointer make-objc-method method-name
	 objc-selector-pointer make-objc-selector selector-name
	 objc-record->objc-ptr print-objc-record)

;;(ppexpand* '(objc-lambda* c-pointer NSAutoreleasePool  alloc))
;;(ppexpand* '(objc-lambda  c-pointer NSAutoreleasePool   init))



(print "\n\n\n\n\n")
(let loop ((foo (class NSString))
	   (bar 1))
  (print bar foo)
  (print (class-name foo))

  (unless (> bar 550)
    (loop  foo (+ bar 1))))



(pp ((objc-lambda   c-pointer NSAutoreleasePool init) 
     ((objc-lambda* c-pointer NSAutoreleasePool alloc))))




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

