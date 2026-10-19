;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2021 Raghav Gururajan <rg@raghavgururajan.name>
;;; Copyright © 2022, 2023 Hilton Chain <hako@ultrarare.space>
;;; Copyright © 2023 Saku Laesvuori <saku@laesvuori.fi>
;;; Copyright © 2023 Lu Hui <luhux76@gmail.com>
;;; Copyright © 2023 Camilo Q.S. (Distopico) <distopico@riseup.net>
;;; Copyright © 2024 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2024 dan <i@dan.games>
;;; Copyright © 2025 Sharlatan Hellseher <sharlatanus@gmail.com>
;;; Copyright © 2025 Zheng Junjie <z572@z572.online>
;;; Copyright © 2025 Evgenii Lepikhin <johnlepikhin@gmail.com>
;;; Copyright © 2026 Grigory Shepelev <mail@grigory.tech>

;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (telegram-desktop packages telegram-desktop)
  #:use-module (srfi srfi-26)
  #:use-module (gnu packages)
  #:use-module (gnu packages aidc)
  #:use-module (gnu packages animation)
  #:use-module (gnu packages assembly)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages check)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages c)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages digest)
  #:use-module (gnu packages fcitx5)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages hunspell)
  #:use-module (gnu packages image)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages language)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages lxqt)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-check)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages telephony)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages web)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages xorg)
  #:use-module ((x-files packages telegram-rust) #:select (tdesktop-rust))
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix upstream)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system python)
  #:use-module (guix build-system qt)
  #:use-module (guix utils))

;; Use abseil-cpp-20250127 because the latest version (20250814) removed
;; template-based absl::Nonnull which is required by tg_owt.
;; The newer abseil replaced it with macros which are not compatible.
(define abseil-cpp-cxxstd17-compat
  (hidden-package
   (package/inherit abseil-cpp-20250127
     (arguments
      (substitute-keyword-arguments (package-arguments abseil-cpp-20250127)
        ((#:configure-flags flags #~'())
         #~(cons* "-DCMAKE_CXX_STANDARD=17"
                  #$flags)))))))

(define %telegram-version "7.3.1")

(define libyuv-for-telegram-desktop
  (let ((commit "04821d1e7d60845525e8db55c7bcd41ef5be9406")
        (revision "2440"))
    (origin
      (method git-fetch)
      (uri (git-reference
            (url "https://chromium.googlesource.com/libyuv/libyuv")
            (commit commit)))
      (file-name (git-file-name
                  "libyuv-for-telegram-desktop"
                  (git-version "0" revision commit)))
      (sha256
       (base32
        "1fsvc0f8mckrdzys8lnlnbw6676mjamm6p3ghr2h9liqfa83s6wg")))))

(define cppgir-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://gitlab.com/mnauw/cppgir.git")
          (commit "47cf94f83b54cda59018135601e19d7fb0c77776")))
    (file-name
     (git-file-name "cppgir-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "1p5rigy4vc034kgm2zabn8q8sd4drbdhbmygmqzzd3mppbfkw69v"))))

(define tde2e-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/tdlib/td.git")
          (commit "51743dfd01dff6179e2d8f7095729caa4e2222e9")))
    (file-name
     (git-file-name "tde2e-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "009ayf0hlcm6h5fdas5l5qnw46f5s9v1xr5v5ad4k9p9yxmzrq3n"))))

(define cmake-helpers-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/cmake_helpers.git")
          (commit "699262e441dbc6270f0ba6cc74f2e7a8e4c7e422")))
    (file-name
     (git-file-name "cmake-helpers-for-telegram-desktop" %telegram-version))
    (patches
     (map (lambda (patch)
            (search-path
             (map (cut string-append <> "/telegram-desktop/packages/patches")
                  %load-path)
             patch))
          '("telegram-desktop-unbundle-cppgir-v2.patch")))
    (sha256
     (base32
      "0wlz2jw6d69czqm9jcx18qz42drypd41r788lfsir3z669p42n6a"))))

(define codegen-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/codegen.git")
          (commit "dbd1d53137cd581cfdbeebe93bcaf54abf55ec74")))
    (file-name
     (git-file-name "codegen-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "0slsdpc28zxdgddd6z1i3028v5pgsrsdwz26idk15950jjwbc3nh"))))

(define lib-base-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_base.git")
          (commit "de35c7abcbf6464a0845695a55568bdac12a5fba")))
    (file-name
     (git-file-name "lib-base-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "0k2ca3im88h8b096rfnrqvp6irsr2556m1v6cfvx5nv139r496vi"))))

(define lib-crl-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_crl.git")
          (commit "de724667d7bdfbf906f78fc405af1ee9f7723d49")))
    (file-name
     (git-file-name "lib-crl-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "089pn2sgcm6s8l1mx6hdn84v9mwdl66r469j0rg08pggv1jr56lr"))))

(define lib-lottie-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_lottie.git")
          (commit "fbb922c30b7c30ba17ad5fd4fcb989eadd620062")))
    (file-name
     (git-file-name "lib-lottie-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "0cx98kv22iqplb8b8xhwq1lna4hjqjgizcp8s02zl0ap5wrv577c"))))

(define lib-qr-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_qr.git")
          (commit "6fdf60461444ba150e13ac36009c0ffce72c4c83")))
    (file-name
     (git-file-name "lib-qr-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "1i5n3qvjkf4nv8k75cc0a71xyvpklc4nzg4k2zsfr2pxk0cy7hkw"))))

(define lib-rpl-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_rpl.git")
          (commit "c57cccffb01d85570decd7fccb88419c9a682e63")))
    (file-name
     (git-file-name "lib-rpl-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "0s9sza56fsrcd366ii6isc3w27ii2n9k48drn2q4vrq4jy1hy9ln"))))

(define lib-spellcheck-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_spellcheck.git")
          (commit "3273fd25c185fb626a9836dafbd644c2bd129ee1")))
    (file-name
     (git-file-name "lib-spellcheck-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "10xbyl4hs4zbifmvf5xnafr9nrdg6rl866m76c0f855xpr1gs0vy"))))

(define lib-storage-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_storage.git")
          (commit "ccdc72548a5065b5991b4e06e610d76bc4f6023e")))
    (file-name
     (git-file-name "lib-storage-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "0b11ix95dzpkz335q0a6b5yg8qhj33s4fgj9ppl37pszcqq1j3wi"))))

(define lib-tl-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_tl.git")
          (commit "29746d31247c915a9ec870241399a9d103c39f87")))
    (file-name
     (git-file-name "lib-tl-for-telegram-desktop" %telegram-version))
    (patches
     (map (lambda (patch)
            (search-path
             (map (cut string-append <> "/telegram-desktop/packages/patches")
                  %load-path)
             patch))
          '("lib-tl-for-telegram-memcpy.patch")))
    (sha256
     (base32
      "0hzxg53hcff0xbckxnxwpsh2qdlwm3gj1gm1i6wbz9ac3pavk64y"))))

(define lib-translate-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_translate.git")
          (commit "b23983df9dd87b6993afdcefb48daf890beb545e")))
    (file-name
     (git-file-name "lib-translate-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "13wwq88wiwb27alisfi55aiifq0s7fbq9mnpj81hby24njfh313v"))))

(define lib-ui-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_ui.git")
          (commit "91ff4463899f23f4227bc4cbbdbe7696d479b9bd")))
    (file-name
     (git-file-name "lib-ui-for-telegram-desktop" %telegram-version))
    (patches
     (map (lambda (patch)
            (search-path
             (map (cut string-append <> "/telegram-desktop/packages/patches")
                  %load-path)
             patch))
          '("lib-ui-for-telegram-accessible-orientation.patch")))
    (sha256
     (base32
      "1glqnr99czjzfyjbk1g1rifb3lv7l6235rcdf5md5hgf83f9rgzv"))))

(define lib-webrtc-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_webrtc.git")
          (commit "52636e86eaa493de670daf71959d000b281bd153")))
    (file-name
     (git-file-name "lib-webrtc-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "1y50q6b33r506qn4pw0sn6cmxhwjcxdb79qrw7laz45l1iw1zhm0"))))

(define lib-webview-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/desktop-app/lib_webview.git")
          (commit "d6e2e0b8b171a104cd7b63bd351f056563e964b0")))
    (file-name
     (git-file-name "lib-webview-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "18lm8wx608npagl1g7n2w3skykh7v5z2gf2yq1msi7cpswq1q9pr"))))

(define tgcalls-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/TelegramMessenger/tgcalls.git")
          (commit "1c236c09f8d8569fead14bd68000618a52051225")))
    (file-name
     (git-file-name "tgcalls-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "194r0qnpwlqkm31iw61lpcfji2cmc2kfqjjakzzi3habjzzaagg8"))))

(define fcitx5-qt-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/fcitx/fcitx5-qt.git")
          (commit "0285a5d18367d8f3af80dab7e4819d5555982340")))
    (file-name
     (git-file-name "fcitx5-qt-for-telegram-desktop" %telegram-version))
    (sha256
     (base32
      "0lbmnrfyd32y6d9dp5z1qpzz1v7ivdcbcrppc45v5mf329ziavfv"))))

(define-public webrtc-for-telegram-desktop
  (let ((commit "8c233a4c12d6ec1f2aa87991564ac28cc996c57a")
        (revision "489"))
    (hidden-package
     (package
       (name "webrtc-for-telegram-desktop")
       (version
        (git-version "0" revision commit))
       (source
        (origin
          (method git-fetch)
          (uri
           (git-reference
            (url "https://github.com/desktop-app/tg_owt.git")
            (commit commit)))
          (file-name
           (git-file-name name version))
          (sha256
           (base32 "0d1nglf8irxgavw0p1d23wffmzyzbwapnli45ssgmrn1czzri4gw"))
          (patches
           (map (lambda (patch)
                  (search-path
                   (map (cut string-append <> "/telegram-desktop/packages/patches")
                        %load-path)
                   patch))
                '("webrtc-for-telegram-desktop-pipewire-1.5.patch")))
          (modules '((guix build utils)
                     (ice-9 ftw)
                     (srfi srfi-1)))
          (snippet
           #~(begin
               (let ((keep
                      '("rnnoise"
                        ;; Not available in Guix.
                        "pffft")))
                 (with-directory-excursion "src/third_party"
                   (for-each delete-file-recursively
                             (lset-difference string=?
                                              (scandir ".")
                                              (cons* "." ".." keep)))))
               ;; Unbundle abseil-cpp, crc32c and openh264.
               (substitute* "CMakeLists.txt"
                 (("\\include\\(cmake\\/libopenh264\\.cmake\\)")"")
                 (("\\include\\(cmake\\/libabsl\\.cmake\\)")"")
                 (("\\include\\(cmake\\/libcrc32c\\.cmake\\)")""))))))
       (build-system cmake-build-system)
       (arguments
        (list
         #:tests? #f                    ; No target
         #:phases
         #~(modify-phases %standard-phases
             (add-after 'unpack 'unpack-additional-sources
               (lambda _
                 (let* ((third-party (string-append (getcwd) "/src/third_party"))
                        (libyuv-to (string-append third-party "/libyuv")))
                   (copy-recursively #$libyuv-for-telegram-desktop
                                     libyuv-to)))))))
       (native-inputs (list pkg-config python-wrapper yasm))
       (inputs
        (list abseil-cpp-cxxstd17-compat
              crc32c
              ffmpeg
              glib
              glibmm
              libdrm
              libglvnd
              libjpeg-turbo
              libsrtp
              libvpx
              libxcomposite
              libxdamage
              libxext
              libxfixes
              libxrandr
              libxrender
              libxtst
              mesa
              openh264
              openssl
              opus
              pipewire
              protobuf))
       (synopsis "WebRTC support for Telegram Desktop")
       (description "WebRTC-for-Telegram-Desktop is a custom WebRTC fork by
Telegram project, for its use in telegram desktop client.")
       (home-page "https://github.com/desktop-app/tg_owt")
       (license
        (list
         ;; Abseil-CPP
         license:asl2.0
         ;; LibYuv
         (license:non-copyleft "file:///src/third_party/libyuv/LICENSE")
         ;; PFFFT
         (license:non-copyleft "file:///src/third_party/pffft/LICENSE")
         ;; RnNoise
         license:gpl3
         ;; LibSRTP, Crc32c and Others
         license:bsd-3))))))

(define-public rlottie-for-telegram-desktop
  (let ((commit "dcfe6f62f27522cda4f06f6d6b497ed7fd0917e9")
        (revision "680"))
    (hidden-package
     (package
       (name "rlottie-for-telegram-desktop")
       (version (git-version "0.0.1" revision commit))
       (source
        (origin
          (method git-fetch)
          (uri (git-reference
                (url "https://github.com/desktop-app/rlottie.git")
                (commit commit)))
          (file-name
           (git-file-name name version))
          (sha256
           (base32 "0lg0mjcpp7drr1wb7aqxik7014xkh1ng7hcfihjvdi02gvmpzf3k"))
          (modules '((guix build utils)))
          (snippet
           #~(begin
               (substitute* "meson.build"
                 (("werror=true") "werror=false"))))))
       (build-system meson-build-system)
       (arguments
        (list #:configure-flags #~(list
                                   "-Dlog=true"
                                   "-Dtest=true"
                                   "-Dcpp_std=gnu++17")))
       (native-inputs
        (list googletest
              pkg-config))
       (synopsis "Rlottie for Telegram desktop")
       (home-page "https://github.com/desktop-app/rlottie")
       (description
        "This package is an alternative fork of
https://github.com/Samsung/rlottie with changes adopted for Telegram desktop
and not propagated to upstream.")
       ;; All Licenses are listed in README and provided in licenses
       ;; directory.
       (license (list license:bsd-3
                      license:expat
                      license:freetype
                      license:lgpl2.1+))))))

(define cld3-for-telegram-desktop
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/google/cld3.git")
         (commit "b48dc46512566f5a2d41118c8c1116c4f96dc661")))
   (file-name
    (git-file-name "cld3-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "0ayrrhfdwrf4260h9fsirkhhfrcvc3qqnh6h9wj3ixij2lq0wwqb"))))

(define libprisma-for-telegram-desktop
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/desktop-app/libprisma")
         (commit "75f26c17308871bee69f69a2831a8af2bc2f3627")))
   (file-name
    (git-file-name "libprisma-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "1bbnvrc2yvq8g4km0bdy6q6bysqp2y7hlp41m67flijkhgvwx4p2"))))

(define kimageformats-for-telegram-desktop
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/KDE/kimageformats.git")
         (commit "df82311a1081e576c4ac020204578bb8a81b21ec")))
   (file-name
    (git-file-name "kimageformats-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "0pazpqm1arm9685hv6hfygvpmqfyfy2mx6w5rzjfy8w84hm6fl79"))))

(define nimf-for-telegram-desktop
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/hamonikr/nimf.git")
         (commit "498ec7ffab3ac140c2469638a14451788f03e798")))
   (file-name
    (git-file-name "nimf-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "0xsyh12cn19sa699ly5hs7s9356x7nsiy17ghin91ajwdrlci5vh"))))

(define hime-for-telegram-desktop
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/hime-ime/hime.git")
         (commit "9b3e6f9ab59d1fe4d9de73d3bf0fed7789f921c5")))
   (file-name
    (git-file-name "hime-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "1b98ql30ihbqz1zwlm0c3c1qmxp3gdz96wsic3h6ypqcr3xyj28f"))))

(define microtex-for-telegram-desktop
  ;; The desktop-app fork (Qt setPixelSize fix, \mathop limits-mode fix,
  ;; tinyxml2 strip); cmake_helpers' external/microtex explicitly has no
  ;; system-package fallback, this fork is required.  Renders Instant View
  ;; (Telegram/lib_iv's "td_iv") math formulas.
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/desktop-app/MicroTeX.git")
         (commit "61aaa7cc354de91d5898ffb0b2a6c62628d9a76f")))
   (file-name
    (git-file-name "microtex-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "1isplcrdwyadlgz251817096y793cnmqms3ial36hvbigjq60qf4"))))

(define toomanycooks-for-telegram-desktop
  ;; Header-only C++20 coroutine task scheduler; replaced libdispatch on
  ;; Linux in tdesktop 6.9.1.  cmake_helpers' external/tmc only needs its
  ;; headers on the include path (no separate build/link).
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/tzcnt/TooManyCooks.git")
         (commit "b86af81982860c96295a7e95e4c60cb335615cef")))
   (file-name
    (git-file-name "toomanycooks-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "1lpmddx0plhl2g3h86lbv184iaf38gsyjkd1bczv7q9xq4fclppr"))))

(define libcbor-for-telegram-desktop
  ;; Vendored (not the system libcbor): Telegram/cmake/lib_fido2.cmake glob
  ;; s-compiles it straight from Telegram/ThirdParty/libcbor's sources
  ;; alongside libfido2, generating its own configuration.h.
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/PJK/libcbor.git")
         (commit "170bee2b82cdb7b2ed25af301f62cb6efdd40ec1")))
   (file-name
    (git-file-name "libcbor-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "00ibddiy62kbs9wl52c35j0hbqanx6pi7lvzkpzmbsizkj8mhp1p"))))

(define libfido2-for-telegram-desktop
  ;; Vendored: USB-HID CTAP2 security-key backend for webauthn/passkeys,
  ;; linked against tdesktop's bundled OpenSSL rather than the system one.
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/Yubico/libfido2.git")
         (commit "b974e7cf2ee7392134cc12c08b76a068cf250dd8")))
   (file-name
    (git-file-name "libfido2-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "0nkdigwry5bwzkxk1piww89rrb0g3zwdvn1nk5iq8hw5d47r5npm"))))

(define cmark-gfm-for-telegram-desktop
  ;; Markdown rendering for Instant View articles (td_iv).
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/github/cmark-gfm.git")
         (commit "d7d4a24a9ebfa7581994ea6df0297662bfeaf413")))
   (file-name
    (git-file-name "cmark-gfm-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "1xil7lq50qvz623r8v3d92iggb871j9wsc3s7z6v4x7nrn3x8mg0"))))

(define kcoreaddons-for-telegram-desktop
  ;; tdesktop 7.x wires KCoreAddons through cmake_helpers'
  ;; external/kcoreaddons (bundled by default; DESKTOP_APP_USE_PACKAGED is
  ;; not set here), replacing the direct system find_package(KCoreAddons)
  ;; the 6.x tree used.
  (origin
   (method git-fetch)
   (uri (git-reference
         (url "https://github.com/KDE/kcoreaddons.git")
         (commit "fd84da51b554eac25e35b1e3f373edaab3029b15")))
   (file-name
    (git-file-name "kcoreaddons-for-telegram-desktop" %telegram-version))
   (sha256
    (base32
     "0s6d3hnl33kkbkk19w2c4r1rvmrlsc23jz92spxxhmfn234smir3"))))

(define zxcvbn-for-telegram-desktop
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/tsyrogit/zxcvbn-c.git")
          (commit "ab51000506afc1a450557a3608646bc04ba951fa")))
    (file-name (git-file-name "zxcvbn-for-telegram-desktop" %telegram-version))
    (sha256
     (base32 "035jgrjvn6lhcii7yxh2a6wyz9y8il81pwz3i7zp10jz6dqv2nvd"))))

(define-public tde2e
  (package
    (name "tde2e")
    (version "tdlib-51743df")
    (source tde2e-for-telegram-desktop)
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f  ; No tests in E2E-only mode
           #:build-type "Release"           ; Reduce memory requirements
           #:configure-flags
           #~(list "-DTD_E2E_ONLY=ON")))
    (native-inputs
     (list gperf))
    (inputs
     (list openssl zlib))
    (home-page "https://github.com/tdlib/td")
    (synopsis "End-to-end encryption library for Telegram")
    (description
     "TdE2E provides end-to-end encryption functionality for Telegram
applications, extracted from the TDLib project.  This library enables
secure group calls with end-to-end encryption.")
    (license license:boost1.0)))

(define-public telegram-desktop
  (package
    (name "telegram-desktop")
    (version %telegram-version)
    (source
     (origin
       (method git-fetch)
       (uri
        (git-reference
         (url "https://github.com/telegramdesktop/tdesktop.git")
         (commit
          (string-append "v" version))))
       (file-name
        (git-file-name name version))
       (sha256
        (base32 "08p0yzvci17lqbvz3k0vdqlpp83l8aba822ha506yb4mrf8phdix"))
       (patches
        (map (lambda (patch)
               (search-path
                (map (cut string-append <> "/telegram-desktop/packages/patches")
                     %load-path)
                patch))
             '(;; Make it compatible with GCC 11.
               "telegram-desktop-qguiapp.patch"
               "telegram-desktop-hashmap-incomplete-value.patch"
               ;; Fix LaunchMaps for xdg-desktop-portal < 1.19.1
               "telegram-desktop-fix-launch-maps.patch")))
       (modules '((guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1)))
       (snippet
        #~(begin
            (let ((keep
                   '(;; Not available in Guix, or wired through
                     ;; cmake_helpers' bundled-by-default external/* path.
                     "tgcalls" "cld3" "fcitx5-qt" "kimageformats" "nimf" "hime"
                     "MicroTeX" "TooManyCooks" "libcbor" "libfido2"
                     "cmark-gfm" "kcoreaddons" "zxcvbn")))
              (with-directory-excursion "Telegram/ThirdParty"
                (for-each delete-file-recursively
                          (lset-difference string=?
                                           (scandir ".")
                                           (cons* "." ".." keep)))))))))
    (build-system qt-build-system)
    (arguments
     (list #:qtbase qtbase
           #:tests? #f                      ; No target
           #:build-type "Release"           ; Reduce memory requirements
           ;; Respect --cores even on a busy remote build host.
           #:make-flags #~(list "-l")
           #:imported-modules
           `(,@%qt-build-system-modules
             (guix build glib-or-gtk-build-system))
           #:modules
           '((guix build qt-build-system)
             ((guix build glib-or-gtk-build-system)
              #:prefix glib-or-gtk:)
             (guix build utils)
             (ice-9 match))
           #:configure-flags
           #~(list
              ;; Client applications must provide their own API-ID and API-HASH,
              ;; see also <https://core.telegram.org/api/obtaining_api_id>.
              ;; Here, we snarf the keys from the official Snaps, which are
              ;; also stored in <#$source/snap/snapcraft.yaml>.
              "-DTDESKTOP_API_ID=611335"
              "-DTDESKTOP_API_HASH=d524b414d21f4d37f08684c1df41ac9c"
              "-DDESKTOP_APP_DISABLE_CRASH_REPORTS=ON"
              "-DDESKTOP_APP_DISABLE_AUTOUPDATE=ON"
              ;; Enabling jemalloc causes SIGSEGV.  This probably happened
              ;; after upgrading to glibc 2.39.
              "-DDESKTOP_APP_DISABLE_JEMALLOC=ON")
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'unpack-additional-sources
                 (lambda _
                   (for-each make-file-writable (find-files "."))
                   (for-each
                    (match-lambda
                      ((dst src)
                       (copy-recursively src dst)
                       (for-each make-file-writable (find-files dst))))
                    '(("cmake" #$cmake-helpers-for-telegram-desktop)
                      ("cmake/external/glib/cppgir" #$cppgir-for-telegram-desktop)
                      ("Telegram/codegen" #$codegen-for-telegram-desktop)
                      ("Telegram/lib_base" #$lib-base-for-telegram-desktop)
                      ("Telegram/lib_crl" #$lib-crl-for-telegram-desktop)
                      ("Telegram/lib_lottie" #$lib-lottie-for-telegram-desktop)
                      ("Telegram/lib_qr" #$lib-qr-for-telegram-desktop)
                      ("Telegram/lib_rpl" #$lib-rpl-for-telegram-desktop)
                      ("Telegram/lib_spellcheck" #$lib-spellcheck-for-telegram-desktop)
                      ("Telegram/lib_storage" #$lib-storage-for-telegram-desktop)
                      ("Telegram/lib_tl" #$lib-tl-for-telegram-desktop)
                      ("Telegram/lib_translate" #$lib-translate-for-telegram-desktop)
                      ("Telegram/lib_ui" #$lib-ui-for-telegram-desktop)
                      ("Telegram/lib_webrtc" #$lib-webrtc-for-telegram-desktop)
                      ("Telegram/lib_webview" #$lib-webview-for-telegram-desktop)
                      ("Telegram/ThirdParty/cld3" #$cld3-for-telegram-desktop)
                      ("Telegram/ThirdParty/fcitx5-qt" #$fcitx5-qt-for-telegram-desktop)
                      ("Telegram/ThirdParty/libprisma" #$libprisma-for-telegram-desktop)
                      ("Telegram/ThirdParty/tgcalls" #$tgcalls-for-telegram-desktop)
                      ("Telegram/ThirdParty/kimageformats"
                       #$kimageformats-for-telegram-desktop)
                      ("Telegram/ThirdParty/nimf" #$nimf-for-telegram-desktop)
                      ("Telegram/ThirdParty/hime" #$hime-for-telegram-desktop)
                      ("Telegram/ThirdParty/MicroTeX"
                       #$microtex-for-telegram-desktop)
                      ("Telegram/ThirdParty/TooManyCooks"
                       #$toomanycooks-for-telegram-desktop)
                      ("Telegram/ThirdParty/libcbor" #$libcbor-for-telegram-desktop)
                      ("Telegram/ThirdParty/libfido2" #$libfido2-for-telegram-desktop)
                      ("Telegram/ThirdParty/cmark-gfm"
                       #$cmark-gfm-for-telegram-desktop)
                      ("Telegram/ThirdParty/kcoreaddons"
                       #$kcoreaddons-for-telegram-desktop)
                      ("Telegram/ThirdParty/zxcvbn"
                       #$zxcvbn-for-telegram-desktop)))))
               (add-after 'unpack-additional-sources 'setup-expected-lite-for-cppgir
                 (lambda _
                   ;; cppgir needs expected-lite, provide it from system package
                   (let ((expected-lite-include
                          (string-append #$(this-package-input "expected-lite")
                                         "/include")))
                     (copy-recursively
                      expected-lite-include
                      "cmake/external/glib/cppgir/expected-lite/include"))))
               (add-after 'unpack-additional-sources 'use-system-xdg-desktop-portal
                 (lambda _
                   (substitute* (list "Telegram/CMakeLists.txt"
                                      "Telegram/lib_base/CMakeLists.txt")
                     (("\\$\\{third_party_loc\\}/xdg-desktop-portal/data")
                      (string-append
                       #$(this-package-native-input "xdg-desktop-portal")
                       "/share/dbus-1/interfaces")))))
               ;; Remove a problematic 'constexpr' keyword, otherwise
               ;; compilation fails with GCC 11.
               (add-after 'use-system-xdg-desktop-portal 'patch-libwebview
                 (lambda _
                   (substitute* "Telegram/lib_webview/webview/webview_interface.h"
                     (("constexpr ") ""))))
               (add-after 'install 'glib-or-gtk-compile-schemas
                 (assoc-ref glib-or-gtk:%standard-phases 'glib-or-gtk-compile-schemas))
               (add-after 'glib-or-gtk-compile-schemas 'glib-or-gtk-wrap
                 (assoc-ref glib-or-gtk:%standard-phases 'glib-or-gtk-wrap))
               (add-after 'glib-or-gtk-wrap 'create-telegram-desktop-symlink
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let* ((out (assoc-ref outputs "out"))
                          (bin (string-append out "/bin")))
                     (with-directory-excursion bin
                       (symlink "Telegram" "telegram-desktop"))))))))
    (native-inputs
     (list cpp-ada-url-parser
           gperf
           `(,glib "bin")
           gobject-introspection
           `(,gtk+ "bin")
           pkg-config
           python-wrapper
           qtshadertools
           xdg-desktop-portal))
    (inputs
     (list abseil-cpp-cxxstd17-compat
           alsa-lib
           boost
           c++-gsl
           crc32c
           eudev
           expected-lite
           ffmpeg
           glib
           glibmm-2.76
           gtk+
           hime
           hunspell
           kcoreaddons
           kimageformats
           libdispatch
           libexpected
           libjpeg-turbo
           libvpx
           libxcb
           lz4
           minizip
           nimf
           openal
           openssl
           opus
           plasma-wayland-protocols
           pulseaudio
           protobuf
           qrcodegen-cpp
           qtdeclarative
           qtimageformats
           qtsvg
           qtwayland
           range-v3
           tde2e
           tdesktop-rust
           rnnoise
           wayland
           wayland-protocols
           webkitgtk-for-gtk3
           webrtc-for-telegram-desktop
           xcb-util-keysyms
           xxhash
           zlib))
    (synopsis "Telegram Desktop")
    (description "Telegram desktop is the official desktop version of the
Telegram instant messenger.")
    (home-page "https://github.com/telegramdesktop/tdesktop")
    (license
     (list
      ;; ThirdParty
      license:lgpl3
      ;; Others
      license:gpl3+))))

;; Falls back to the pin on lookup failure (rate limit, no network,
;; or -- inside a sandboxed `guix pull' build with no resolver at all --
;; an uncaught getaddrinfo-error; PACKAGE-LATEST-RELEASE only itself
;; guards against SOME failure modes, so wrap unconditionally.
(define telegram-desktop-latest-version
  (let ((update (false-if-exception (package-latest-release telegram-desktop))))
    (if update (upstream-source-version update) %telegram-version)))

(define* (%latest-source-fetch source hash-algo hash
                               #:optional name
                               #:key (system (%current-system))
                               (guile (default-guile))
                               executable?)
  "Fetch @var{source}, an @code{<upstream-source>}; the hash is computed
live instead of checked against @var{hash} (same trick @samp{--with-latest}
uses via the unexported @code{upstream-fetch} in
@code{(guix transformations)})."
  (lower-object source system))

;; Recursive checkout of upstream's newest tag; coexists with the pinned
;; TELEGRAM-DESKTOP above (submodule commits stay in sync automatically
;; instead of being hand-tracked).
(define-public telegram-desktop/latest
  (package
    (inherit telegram-desktop)
    (version telegram-desktop-latest-version)
    (source
     (origin
       (method %latest-source-fetch)
       (uri (upstream-source
             (package "telegram-desktop")
             (version telegram-desktop-latest-version)
             (urls (git-reference
                    (url "https://github.com/telegramdesktop/tdesktop.git")
                    (commit (string-append "v" telegram-desktop-latest-version))
                    (recursive? #t)))))
       (sha256
        (base32 "0mf9qgylnvkl76n8zgyb1dlkgznlqxn4n2kgyxg1p7aqngqjwjkw")) ;unused
       (file-name
        (git-file-name "telegram-desktop" telegram-desktop-latest-version))
       (patches
        (map (lambda (patch)
               (search-path
                (map (cut string-append <> "/telegram-desktop/packages/patches")
                     %load-path)
                patch))
             '("telegram-desktop-qguiapp.patch"
               "telegram-desktop-hashmap-incomplete-value.patch"
               "telegram-desktop-fix-launch-maps.patch"
               ;; Path-adjusted for the recursive checkout above.
               "telegram-desktop-latest-lib-tl-memcpy.patch"
               "telegram-desktop-latest-unbundle-cppgir.patch"
               "telegram-desktop-latest-lib-ui-accessible-orientation.patch")))))
    (arguments
     (substitute-keyword-arguments (package-arguments telegram-desktop)
       ((#:phases phases)
        #~(modify-phases #$phases
            ;; Submodules already present via the recursive checkout.
            (replace 'unpack-additional-sources
              (lambda _
                (for-each make-file-writable (find-files "."))))))))))
