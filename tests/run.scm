(use utils posix)

(define objcflags
  (cond-expand
   (macosx "-framework Cocoa")
   (else (string-append "-C -w -C " (with-input-from-pipe "gnustep-config --objc-flags" read-all)))))

(compile-file "test1.scm" options: `("-objc" ,objcflags))
