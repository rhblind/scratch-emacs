;;; modules/editor/ws-butler/config.el -*- lexical-binding: t; -*-
;;
;; Trim trailing whitespace ON SAVE -- but only on lines you've edited
;; in this session. Stops noisy diffs in projects where leading-edge
;; whitespace exists in untouched files.

(use-package ws-butler
  :hook ((prog-mode . ws-butler-mode)
         (text-mode . ws-butler-mode)
         (conf-mode . ws-butler-mode)))
