;;; modules/lang/org/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package
 '(org-appear :type git :host github :repo "awth13/org-appear"))
(straight-use-package 'org-cliplink)
(straight-use-package 'org-download)

;; +roam: Zettelkasten-style note network via org-roam (v2).
(when (modulep! +roam)
  (straight-use-package 'org-roam))

;; +hugo: org-to-Hugo exporter (ox-hugo).
(when (modulep! +hugo)
  (straight-use-package 'ox-hugo))

;; evil-org: vim-style heading / list / table manipulation in org-mode,
;; plus dedicated `evil-org-agenda-mode' so the agenda buffer respects
;; evil keys (j/k navigate, etc.).  evil-collection's org support is
;; less thorough, so this is the canonical pairing.
(straight-use-package 'org-superstar)
(straight-use-package
 '(org-pretty-table :type git :host github :repo "Fuco1/org-pretty-table"))

(when (modulep! :editor evil)
  (straight-use-package 'evil-org))
