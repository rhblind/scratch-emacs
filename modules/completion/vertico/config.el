;;; modules/completion/vertico/config.el -*- lexical-binding: t; -*-
;;
;; Minibuffer completion stack adapted from Doom's :completion vertico:
;;   vertico     -- vertical interactive UI
;;   orderless   -- match input fragments in any order
;;   marginalia  -- annotations next to candidates
;;   consult     -- richer commands using completing-read
;;
;; Leader bindings for consult live in `:editor leader/config.el', gated by
;; `(modulep! :completion vertico)'.

(use-package vertico
  :demand t
  :init
  (defun scratch-vertico--crm-indicator-a (args)
    "Show a [CRM ...] indicator in `completing-read-multiple' prompts."
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args
              #'scratch-vertico--crm-indicator-a)
  :config
  (setq vertico-resize nil
        vertico-count 17
        vertico-cycle t)
  (vertico-mode 1)

  ;; vertico-directory: smarter file-path handling.
  (require 'vertico-directory)
  (define-key vertico-map (kbd "RET")   #'vertico-directory-enter)
  (define-key vertico-map (kbd "DEL")   #'vertico-directory-delete-char)
  (define-key vertico-map (kbd "M-DEL") #'vertico-directory-delete-word)
  ;; Tidies "~/foo/bar///" -> "/" and "~/foo/bar/~/" -> "~/".
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

  ;; Page-by-page scrolling (vim/less style); vertico's own
  ;; `vertico-scroll-up' moves UP toward older candidates -- inverted
  ;; from the user's mental model where C-d goes "down the list",
  ;; so we swap them.
  (define-key vertico-map (kbd "C-u") #'vertico-scroll-down)
  (define-key vertico-map (kbd "C-d") #'vertico-scroll-up)
  ;; M-RET: accept whatever's typed, even if it doesn't match a
  ;; candidate (useful when typing a new project / file path).
  (define-key vertico-map (kbd "M-RET") #'vertico-exit-input)

  ;; evil-collection-vertico already binds C-n/C-p (insert) and j/k/gg/G/gj/gk
  ;; (normal). Add C-j/C-k aliases on top, plus group-jump and file-aware
  ;; C-h/C-l. Bind via evil-collection-define-key for proper state precedence.
  (when (modulep! :editor evil)
    (with-eval-after-load 'evil-collection
      (evil-collection-define-key 'insert 'vertico-map
        (kbd "C-j")   'vertico-next
        (kbd "C-k")   'vertico-previous
        (kbd "C-M-j") 'vertico-next-group
        (kbd "C-M-k") 'vertico-previous-group
        ;; Page scroll: evil-collection only wires C-u/C-d in normal
        ;; state, but vertico minibuffers are in insert state. Bind
        ;; them here so page-up / page-down work while typing.
        (kbd "C-u")   'vertico-scroll-down
        (kbd "C-d")   'vertico-scroll-up)
      (evil-collection-define-key 'insert 'vertico-map
        (kbd "C-h")
        (lambda ()
          (interactive)
          (if (eq 'file (vertico--metadata-get 'category))
              (vertico-directory-up)
            (call-interactively #'evil-backward-char)))
        (kbd "C-l")
        (lambda ()
          (interactive)
          (if (eq 'file (vertico--metadata-get 'category))
              (vertico-directory-enter)
            (call-interactively #'evil-forward-char)))))))

(use-package orderless
  :demand t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles orderless partial-completion))
          (eglot (styles orderless))
          (eglot-capf (styles orderless)))
        orderless-component-separator #'orderless-escapable-split-on-space))

(use-package marginalia
  :demand t
  :config
  (marginalia-mode 1))

(use-package consult
  :defer t
  :init
  ;; Use consult-xref for xref jumping (richer preview).
  (setq xref-show-xrefs-function       #'consult-xref
        xref-show-definitions-function #'consult-xref
        ;; Async tuning, copied from Doom.
        consult-narrow-key "<"
        consult-line-numbers-widen t
        consult-async-min-input 2
        consult-async-refresh-delay  0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1)
  :config
  ;; (recentf-mode is enabled by the framework's init.el; no advice needed.)

  ;; Replace common builtins with their consult equivalents.
  (define-key global-map [remap goto-line]                #'consult-goto-line)
  (define-key global-map [remap imenu]                    #'consult-imenu)
  (define-key global-map [remap recentf-open-files]       #'consult-recent-file)
  (define-key global-map [remap switch-to-buffer]         #'consult-buffer)
  (define-key global-map [remap switch-to-buffer-other-window]
              #'consult-buffer-other-window)
  (define-key global-map [remap switch-to-buffer-other-frame]
              #'consult-buffer-other-frame)
  (define-key global-map [remap yank-pop]                 #'consult-yank-pop)
  (define-key global-map [remap bookmark-jump]            #'consult-bookmark)
  (define-key global-map [remap project-switch-to-buffer] #'consult-project-buffer)

  ;; Defer preview to C-SPC for slow / large-result commands; same for the
  ;; sources that back `consult-buffer'.
  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file
   consult-source-recent-file consult-source-project-recent-file
   consult-source-bookmark
   :preview-key "C-SPC"))

;; embark: context-aware actions on completion candidates and at point.
;; `embark-act' (SPC a or C-.) opens an action menu for whatever's
;; under point or selected in the minibuffer.
(use-package embark
  :defer t
  :commands (embark-act embark-dwim embark-bindings)
  :init
  ;; Use embark's prefix-help variant, which presents prefix maps via
  ;; completing-read instead of the default text dump.
  (setq prefix-help-command #'embark-prefix-help-command)
  :bind
  (("C-." . embark-act)
   ("M-." . embark-dwim)
   ("C-h B" . embark-bindings)))

;; embark-consult bridges embark with consult so previewing /
;; collecting / exporting consult results gets richer.
(use-package embark-consult
  :after (embark consult)
  :demand t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; wgrep makes consult-grep / consult-ripgrep results editable in
;; place: after `embark-export', `wgrep-change-to-wgrep-mode' makes
;; the buffer writable; edit lines, `C-c C-c' applies edits to the
;; underlying files in batch.
(use-package wgrep
  :commands wgrep-change-to-wgrep-mode
  :config
  (setq wgrep-auto-save-buffer t))

;; Smart "export to writable buffer": picks wgrep / wdired / occur-edit
;; based on the candidate type. Bound to `C-c e' inside the minibuffer.
;; Ported from Doom's `+vertico/embark-export-write'.
(defun scratch/vertico-embark-export-write ()
  "Export the current vertico results to a writable buffer.
Routes to:
  - `wgrep-change-to-wgrep-mode'    for `consult-grep' results
  - `wdired-change-to-wdired-mode'  for file lists
  - `occur-edit-mode'               for `consult-location' (line) results"
  (interactive)
  (require 'embark)
  (require 'wgrep)
  (let* ((edit-command
          (pcase-let ((`(,type . ,_)
                       (run-hook-with-args-until-success 'embark-candidate-collectors)))
            (pcase type
              ('consult-grep     #'wgrep-change-to-wgrep-mode)
              ('file             #'wdired-change-to-wdired-mode)
              ('consult-location #'occur-edit-mode)
              (other (user-error "Embark category %S doesn't support writable export" other)))))
         (embark-after-export-hook (cons edit-command embark-after-export-hook)))
    (embark-export)))

;; Minibuffer-side embark bindings (Doom-shaped):
;;   C-c C-o  embark-export       (snapshot to *Embark Export*)
;;   C-c C-e  smart export-write  (wgrep / wdired / occur-edit dispatcher)
;;   C-c C-l  embark-collect      (snapshot to a live *Embark Collect* buffer)
;;
;; Bound at top level (not under `with-eval-after-load embark') so the
;; keys exist in `minibuffer-local-map' from startup -- which-key can
;; then show the `C-c' prefix popup the moment you press `C-c' inside
;; a consult picker, even before embark has been loaded. The targets
;; are autoloaded; they pull in embark on first invocation.
(define-key minibuffer-local-map (kbd "C-c C-o") #'embark-export)
(define-key minibuffer-local-map (kbd "C-c C-e") #'scratch/vertico-embark-export-write)
(define-key minibuffer-local-map (kbd "C-c C-l") #'embark-collect)

;;;; Leader bindings (this module owns SPC s, the yank-ring under SPC y,
;;;; and upgrades a few of the leader's defaults to the consult variants.)

(when (modulep! :editor leader)
  (map! :leader
    ;; Upgrades of leader baselines to consult variants.
    :desc "switch buffer"      "b b" #'consult-buffer
    :desc "recent files"       "f r" #'consult-recent-file
    :desc "yank ring"          "y"   #'consult-yank-pop
    :desc "project buffers"    "p b" #'consult-project-buffer
    ;; Doom-style top-level shortcut for project-wide ripgrep search.
    :desc "search project (rg)" "/"  #'consult-ripgrep
    ;; Embark "act on candidate / thing at point" (Doom default).
    :desc "embark act"          "a"  #'embark-act
    ;; New SPC s search submenu.
    (:prefix-map ("s" . "search")
     :desc "search buffer"        "s" #'consult-line
     :desc "imenu"                "i" #'consult-imenu
     :desc "search project (rg)"  "p" #'consult-ripgrep
     :desc "find file (project)"  "f" #'consult-find)))
