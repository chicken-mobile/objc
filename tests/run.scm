(use utils posix)

(load "test1.scm")
(load "test2.scm")

(define objcflags
  (with-input-from-pipe "gnustep-config --objc-flags" read-all))

(compile-file "test3.scm" options: `("-objc" "-C" ,(qs objcflags) "-C -w"))
