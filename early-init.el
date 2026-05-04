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

;; PERF: Defer native-comp JIT until after startup. JIT compilation
;;   triggered during init can stall the first frame paint; pushing it
;;   to `emacs-startup-hook' lets the UI come up first, then async
;;   compilation picks up in the background. Only relevant in graphical
;;   sessions -- batch / sync runs don't need it.
(setq native-comp-deferred-compilation nil
      native-comp-jit-compilation nil)
(unless noninteractive
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq native-comp-deferred-compilation t
                    native-comp-jit-compilation t))))

;; PERF: Skip the frame-resize that fires when font/face attributes change
;;   at startup. Halves startup time for users with custom fonts.
(setq frame-inhibit-implied-resize t)

;; PERF: Larger pipe for subprocess output. The default (4kb) is a
;;   bottleneck for LSP servers, magit, eglot, etc. that emit big chunks.
(setq read-process-output-max (* 3 1024 1024))   ; 3 MB

;; UX: Stop prompting on every file over 10 MB -- the default threshold is
;;   from another era. 100 MB is a more 2020s number for "are you sure?".
(setq large-file-warning-threshold (* 100 1024 1024))

;; PERF: Don't compact font caches during GC -- compacting them is slow
;;   and they're rebuilt cheaply on demand.
(setq inhibit-compacting-font-caches t)

;; PERF: Skip distribution-level site-init.el. We don't rely on it.
(setq site-run-file nil)

;; UX: Respect DEBUG envvar as an alternative to --debug-init.
(let ((debug (getenv "DEBUG")))
  (when (and (stringp debug) (not (string-empty-p debug)))
    (setq init-file-debug t
          debug-on-error t)))

;; straight manages packages; keep package.el out of the way.
(setq package-enable-at-startup nil)

;; PERF: Skip straight's `find(1)'-based startup mod check. Default is
;;   `(find-at-startup find-when-checking only-once)', which spawns
;;   `find' across `straight/repos/' on every init -- the cause of
;;   the "Processing repository ..." chatter and a half-second-ish
;;   stall on cold start. With `check-on-save' + `find-when-checking',
;;   straight notices in-Emacs edits via `before-save-hook' and `bin/
;;   scratch sync' picks up new packages explicitly. Mirrors Doom.
(setq straight-check-for-modifications '(check-on-save find-when-checking))

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
