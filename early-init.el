;;; early-init.el --- scratch framework early init -*- lexical-binding: t; -*-

;; PERF: Defer GC during startup. With gc-cons-threshold at most-positive-fixnum
;;   garbage collection effectively never fires until we reset it. The hook
;;   below restores a saner value once init.el is done.
(setq gc-cons-threshold (if noninteractive (* 128 1024 1024) most-positive-fixnum)
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))

;; PERF: Disable file-name handlers during startup, restore afterwards.
;;   `file-name-handler-alist' is consulted on every file op; many handlers
;;   (TRAMP, jka-compr, archive-mode) aren't relevant during init.
(let ((original file-name-handler-alist))
  (setq file-name-handler-alist nil)
  (add-hook 'emacs-startup-hook
            (lambda () (setq file-name-handler-alist original))))

;; PERF: Skip mtime checks on .elc files in interactive sessions; trust the
;;   build. In CLI (sync, batch scripts), prefer newer for correctness.
(setq load-prefer-newer noninteractive)

;; UX: Don't pop up the *Warnings* buffer for every "function X not known to
;;   be defined" warning native-comp emits when a package references optional
;;   integrations (mu4e, elfeed, etc.) you don't have installed. The
;;   warnings still go to *Async-native-compile-log* if you need them.
(setq native-comp-async-report-warnings-errors 'silent)

;; UX: Respect DEBUG envvar as an alternative to --debug-init.
(let ((debug (getenv "DEBUG")))
  (when (and (stringp debug) (not (string-empty-p debug)))
    (setq init-file-debug t
          debug-on-error t)))

;; straight manages packages; keep package.el out of the way.
(setq package-enable-at-startup nil)

;; UX: Strip default frame chrome (menu / tool / scroll bars). Setting these
;;   via `default-frame-alist' in early-init means the initial frame is
;;   created without them -- no flash of chrome during startup. Re-enable
;;   any of these in your ~/.scratch.d/config.org if you prefer them.
;;   OS-specific window chrome (e.g. macOS' undecorated-round) lives in
;;   the corresponding `modules/os/<system>' module.
(push '(menu-bar-lines . 0)    default-frame-alist)
(push '(tool-bar-lines . 0)    default-frame-alist)
(push '(vertical-scroll-bars)  default-frame-alist)

;; UX: Silence the bell entirely. Both audible and visible variants. To
;;   restore the default behavior, `(setq ring-bell-function nil)' in
;;   your config; or `(setq visible-bell t)' for the visual flash only.
(setq ring-bell-function #'ignore)
