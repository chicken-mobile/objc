(load "objc")
(import objc)

(import-for-syntax objc)
(use expand-full trace)

(trace-module 'objc)
(untrace objc-class-pointer class-get-name* object-get-class-name make-objc-meta-class
	 objc-meta-class-pointer class-get-meta-class*
	 objc-object-pointer object-get-class-name*
	 objc-method-pointer method-get-name* selector-get-name
	 objc-record->objc-ptr object-dispose print-objc-record)

(ppexpand* '(objc-lambda* c-pointer NSAutoreleasePool  alloc))
(ppexpand* '(objc-lambda  c-pointer NSAutoreleasePool   init))

(pp (object-get-class-name
     ((objc-lambda c-pointer NSAutoreleasePool init)
      ((objc-lambda* c-pointer NSAutoreleasePool alloc)))))


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

