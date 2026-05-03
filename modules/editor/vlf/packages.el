;;; modules/editor/vlf/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; The mainline `vlf' on MELPA installs cleanly. Doom uses an explicit
;; recipe pointing at m00natic/vlfi which is the canonical upstream mirror.
(straight-use-package
 '(vlf :type git :host github :repo "m00natic/vlfi"
       :files ("*.el") :branch "master"))
