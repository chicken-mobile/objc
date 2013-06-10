(module objc (*enable-inline-cache*
	      objc-import
	      object?
	      define-objc-class
	      define-objc-interface
	      declare-objc-interface
	      define-objc-implementation
	      object-ref object-set!
	      find-class
	      string->NSString
	      NSString->string
	      NSString
	      Object
	      NSObject
	      @selector
	      NSLog
	      @
	      class-of
	      class?
	      metaclass?
	      class-name
	      string->selector
	      selector->string
	      selector?
	      superclass-of
	      nil
	      with-autorelease-pool
	      install-autorelease-pool
	      (send lookup-method))

(import scheme chicken)
(include "objc.scm")

)
