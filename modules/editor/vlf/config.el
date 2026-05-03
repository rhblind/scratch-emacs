;;; modules/editor/vlf/config.el -*- lexical-binding: t; -*-
;;
;; vlf (Very Large Files): when Emacs would otherwise choke on a
;; multi-GB file, vlf opens it in chunks. `vlf-setup' integrates with
;; `find-file' so large files automatically get the chunked treatment;
;; the threshold is `vlf-application' (default `ask': prompts for
;; large files, normal-loads small ones).

;; `vlf-setup' is a feature inside the `vlf' package (already declared
;; in packages.el), not a separately-installable package. Skip
;; use-package's install machinery and just `require' it lazily.
(use-package vlf-setup
  :straight nil
  :defer t
  :commands (vlf vlf-occur)
  :init
  ;; Pull in vlf-setup once Emacs has been idle for a few seconds.
  ;; Daily startup pays nothing; opening a huge file later still goes
  ;; through `vlf-application' (default `ask').
  (run-with-idle-timer 5 nil (lambda () (require 'vlf-setup nil t))))
