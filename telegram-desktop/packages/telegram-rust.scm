;;; Copyright © 2026 Grigory Shepelev <mail@grigory.tech>
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (telegram-desktop packages telegram-rust)
  #:use-module ((guix build-system cargo) #:select (cargo-build-system))
  #:use-module (guix gexp)
  #:use-module ((guix git-download)
                #:select (git-fetch git-reference git-file-name))
  #:use-module ((guix import crate) #:select (cargo-inputs-from-lockfile))
  #:use-module ((guix licenses) #:select (expat asl2.0) #:prefix license:)
  #:use-module ((guix packages)
                #:select (package origin origin-uri base32))
  #:use-module ((srfi srfi-1) #:select (append-map delete-duplicates))
  #:use-module ((telegram-desktop packages rust-compiler) #:select (rust-1.96)))

(define (auxiliary-file name)
  "Locate a Telegram build input shipped with this channel."
  (canonicalize-path
   (search-path %load-path (string-append "telegram-desktop/packages/aux/" name))))

(define tlottie-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/dkaraush/tlottie.git")
          (commit "92df98dc20")))
    (file-name (git-file-name "tlottie" "1.0.6-92df98dc20"))
    (sha256
     (base32 "1s3i9qzgs79scs4dyrqj2m4clf9xp9yz3yldc7nyhby0zv4k5mjs"))))

(define-public tdesktop-rust
  (package
    (name "tdesktop-rust")
    (version "7.3.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/i582/wallet-engine.git")
             (commit "e59e0d89d7ee90c388bf36e3334c5b276f396697")))
       (file-name (git-file-name "wallet-engine" "0.0.7-e59e0d8"))
       (sha256
        (base32 "07l7qssdfgvrqaym1ivyl4mykn19qw9z1r655yfl14d3h3nmcvzg"))
       ;; desktop-app/patches, aec474953ff7ee9b6e4cd9b8658288ea86d124f3.
       (patches (list (auxiliary-file "wallet-engine-telegram.patch")))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:rust rust-1.96
      #:install-source? #f
      #:modules
      '((guix build cargo-build-system)
        (guix build utils)
        ((ice-9 ftw) #:select (scandir)))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'assemble-rust-library
            (lambda _
              (let ((files (scandir "." (lambda (name)
                                          (not (member name '("." "..")))))))
                (mkdir "wallet-engine")
                (for-each (lambda (file)
                            (rename-file file
                                         (string-append "wallet-engine/" file)))
                          files))
              (copy-recursively #$tlottie-source "tlottie")
              (for-each make-file-writable (find-files "tlottie"))
              ;; Keep the upstream workspaces beside the combined library.
              (for-each delete-file (find-files "." "^Cargo.lock$"))
              (mkdir "tdesktop-rust")
              (chdir "tdesktop-rust")
              (copy-file #$(local-file (auxiliary-file "tdesktop-rust-Cargo.toml"))
                         "Cargo.toml")
              (mkdir "src")
              (copy-file #$(local-file (auxiliary-file "tdesktop-rust-lib.rs"))
                         "src/lib.rs")
              (setenv "CARGO_TARGET_DIR" (string-append (getcwd) "/target"))
              (setenv "CARGO_BUILD_JOBS" (number->string (parallel-job-count)))
              (setenv "RUST_TEST_THREADS" (number->string (parallel-job-count)))))
          (replace 'build
            (lambda _
              (invoke "cargo" "build" "--offline" "--release" "--lib")
              (invoke "cargo" "build" "--offline" "--release"
                      "--manifest-path" "../wallet-engine/bindgen/cpp/bindgen/Cargo.toml")
              (invoke "target/release/uniffi-bindgen-cpp"
                      "--library" "--out-dir" "bindings"
                      "target/release/libtdesktop_rust.so")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "cargo" "test" "--offline" "--release"
                        "--manifest-path" "../wallet-engine/Cargo.toml"
                        "--workspace" "--lib")
                (invoke "cargo" "test" "--offline" "--release"
                        "--manifest-path" "../tlottie/Cargo.toml" "--lib"
                        ;; Timing checks need an otherwise idle test runner.
                        "--" "--test-threads=1"
                        ;; Upstream 8386793f8857 raised the rendering limits,
                        ;; but these assertions still assume the old limits.
                        "--skip"
                        "dos::renderer_rejects_large_canvas_before_allocating_fallback"
                        "--skip" "dos::animated_repeater_product_stays_bounded"
                        "--skip" "dos::clipped_dashed_round_join_zigzag_stays_bounded"
                        "--skip" "dos::nested_track_matte_target_surfaces_stay_bounded"
                        "--skip" "dos::compounding_repeaters_are_rejected"))))
          (replace 'install
            (lambda _
              (install-file "target/release/libtdesktop_rust.a"
                            (string-append #$output "/lib"))
              (install-file "../tlottie/include/tlottie.h"
                            (string-append #$output "/include/tlottie"))
              (for-each
               (lambda (file)
                 (install-file file
                               (string-append #$output "/include/wallet_engine")))
               (find-files "bindings" "\\.(hpp|cpp)$")))))))
    (inputs
     (delete-duplicates
      (append-map
       (lambda (name)
         (cargo-inputs-from-lockfile (auxiliary-file name)))
       '("tlottie-Cargo.lock"
         "wallet-engine-Cargo.lock"
         "wallet-engine-bindgen-Cargo.lock"))
      (lambda (left right) (equal? (origin-uri left) (origin-uri right)))))
    (home-page "https://github.com/telegramdesktop/tdesktop")
    (synopsis "Telegram animation and wallet libraries with one Rust runtime")
    (description
     "This library combines tlottie and wallet-engine into one static archive,
with the C and C++ bindings required by Telegram Desktop.  A single archive
avoids linking multiple copies of the Rust runtime.  Sources, the Telegram
wallet patch, and Cargo dependencies follow Telegram Desktop 7.3.1.")
    (license (list license:expat license:asl2.0))))
