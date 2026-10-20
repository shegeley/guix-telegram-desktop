;;; Copyright © 2026 Grigory Shepelev <mail@grigory.tech>
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (telegram-desktop packages rust-compiler)
  #:use-module ((gnu packages rust) #:select (rust-1.95))
  #:use-module ((guix packages) #:select (package package-source origin)))

;; Build-only bootstrap compiler, following (gnu packages rust).
(define-public rust-1.96
  (let ((base ((@@ (gnu packages rust) rust-bootstrapped-package)
               rust-1.95 "1.96.1"
               "19xpk1pamj8v1gpi3ayfvh31smb38432ibqjmqw8b1j1ihcvbafh")))
    (package
      (inherit base)
      (source
       (origin
         (inherit (package-source base))
         (patches '())
         (modules '((guix build utils)
                    (ice-9 ftw)
                    (ice-9 match)
                    (srfi srfi-1)))
         (snippet
          '(begin
             (delete-file-recursively "src/llvm-project")
             (for-each
              (match-lambda
                ((prefix . directory)
                 (for-each
                  (lambda (crate)
                    (delete-file-recursively
                     (string-append "vendor/" crate "/" directory)))
                  (filter (lambda (name) (string-prefix? prefix name))
                          (scandir "vendor")))))
              '(("curl-sys-" . "curl")
                ("jemalloc-sys-" . "jemalloc")
                ("libffi-sys-" . "libffi")
                ("libmimalloc-sys-" . "c_src/mimalloc")
                ("libz-sys-" . "src/zlib")
                ("openssl-src-" . "openssl")
                ("tikv-jemalloc-sys-" . "jemalloc")))
             (for-each delete-file
                       (find-files "vendor" "\\.(a|dll|exe|lib)$"))
             (for-each
              (lambda (crate)
                (let ((directory (string-append "vendor/" crate)))
                  (delete-file-recursively
                   (string-append directory "/nghttp2"))
                  (call-with-output-file (string-append directory "/build.rs")
                    (lambda (port)
                      (display
                       "fn main() { println!(\"cargo:rustc-link-lib=nghttp2\"); }\n"
                       port)))))
              (filter (lambda (name) (string-prefix? "libnghttp2-sys-" name))
                      (scandir "vendor")))
             (for-each
              (lambda (crate)
                (substitute* (string-append "vendor/" crate "/Cargo.toml")
                  (("features = \\[\"fs\"" all)
                   (string-append all ", \"use-libc\""))))
              (filter (lambda (name) (string-prefix? "tempfile-" name))
                      (scandir "vendor"))))))))))
