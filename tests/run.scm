(use utils posix)

(cond-expand
  (macosx)
  (else 
   (print "\nsorry, this test does not run on " (software-version) "\n")
   (exit)))

(define objcflags
  (cond-expand
   (macosx "-framework Cocoa")
   (else "")))

(compile-file "test1.scm" options: `("-objc" ,objcflags))
