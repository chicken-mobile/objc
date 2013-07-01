(use test objc)


(test-begin)

(define NSAutoreleasePool (find-class "NSAutoreleasePool"))

(@ NSAutoreleasePool new)

(objc-import "<objc/Object.h>")
(objc-import "<Foundation/NSObject.h>")

(define-objc-interface Foo2 : NSObject
  (- ping: (int)x))

(define pinged #f)

(define-objc-implementation Foo2
  ((-/async ping: (int)x)
   (print "ping: " x)
   (test 42 x)
   (set! pinged #t)
   self))

(define f1 (@ Foo2 new))

(test-assert (object? f1))

#>
#include <pthread.h>

static void *start_thread(void *arg)
{
  Foo2 *f1 = (Foo2 *)arg;

  printf("thread sleeps ...\n");
  sleep(2);
  printf("sending message\n");
  [f1 ping: 42];
  return NULL;
}
<#

((foreign-lambda* void ((c-pointer f1)) #<<EOF
  pthread_t t;

  pthread_create(&t, NULL, start_thread, f1);
EOF
) f1)

(let loop () (unless pinged (loop)))

(test-end)
