(module objc (*enable-inline-cache*
	      objc-import
	      object?
	      define-objc-class
	      define-objc-interface
	      declare-objc-interface
	      define-objc-implementation
	      object-ref object-set!
	      find-class
	      Object
	      @selector
	      @
	      @/block
	      @/main-thread
	      class-of
	      class?
	      metaclass?
	      class-name
	      string->selector
	      selector->string
	      selector?
	      superclass-of
	      nil
	      block-copy
	      block-release!
	      (send lookup-method/call)
	      (send/block lookup-method/block)
	      (send/main-thread lookup-method/main-thread))

(import scheme chicken)
(include "objc.scm")

)
