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
	      (send lookup-method))

(import scheme chicken)
(include "objc.scm")

)
