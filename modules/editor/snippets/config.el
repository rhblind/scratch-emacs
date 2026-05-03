;;; modules/editor/snippets/config.el -*- lexical-binding: t; -*-
;;
;; [[https://github.com/joaotavora/yasnippet][yasnippet]] template expansion. Triggers via `<TAB>' (when point is
;; on a snippet abbreviation) and via the leader picker (`SPC i s'
;; under :editor leader). The bundled
;; [[https://github.com/AndreaCrotti/yasnippet-snippets][yasnippet-snippets]]
;; collection ships ready-made snippets for most major modes; user-
;; defined snippets live under `<user-emacs-directory>/snippets/'.

(use-package yasnippet
  :defer 2
  :commands (yas-minor-mode yas-global-mode yas-expand
             yas-new-snippet yas-visit-snippet-file
             yas-insert-snippet yas-reload-all)
  :init
  ;; User snippets live in `$SCRATCHDIR/snippets/' -- they're user-
  ;; curated content (alongside `config.org'), not generated framework
  ;; state, so they belong with the rest of the user's dotfiles.
  ;; `yasnippet-snippets' bundles its built-in collection on top via
  ;; its own `yasnippet-snippets-dir' entry.
  (setq yas-snippet-dirs
        (list (expand-file-name "snippets/" scratch-user-dir)))
  :config
  ;; Don't print "[yas] reload took ... ms" on every reload.
  (setq yas-verbosity 1)
  ;; `yasnippet-snippets' just auto-adds itself to `yas-snippet-dirs'.
  (require 'yasnippet-snippets nil t)
  (yas-reload-all)
  ;; Activate in prog-mode and text-mode by default; users can M-x
  ;; yas-global-mode if they want it everywhere.
  (add-hook 'prog-mode-hook #'yas-minor-mode)
  (add-hook 'text-mode-hook #'yas-minor-mode))

(use-package consult-yasnippet
  :when (modulep! :completion vertico)
  :after (yasnippet consult)
  :commands (consult-yasnippet consult-yasnippet-visit-snippet-file))

;;;; Leader bindings under `SPC i' (insert prefix)

(when (modulep! :editor leader)
  (with-eval-after-load 'yasnippet
    (map! :leader
      (:prefix-map ("i" . "insert")
       :desc "snippet"            "s" (if (modulep! :completion vertico)
                                          #'consult-yasnippet
                                        #'yas-insert-snippet)
       :desc "new snippet"        "S" #'yas-new-snippet
       :desc "edit snippet file"  "e" #'yas-visit-snippet-file
       :desc "reload snippets"    "r" #'yas-reload-all))))
