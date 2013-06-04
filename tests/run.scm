(use utils posix)

(load "test1.scm")
(load "test2.scm")

(define objcflags
  (cond-expand
   (macosx "")
   (else (with-input-from-pipe "gnustep-config --objc-flags" read-all))))

(compile-file "test3.scm" options: `("-framework" "Cocoa" "-objc" "-C" ,(qs objcflags) "-C -w"))
