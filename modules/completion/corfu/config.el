;;; modules/completion/corfu/config.el -*- lexical-binding: t; -*-
;;
;; In-buffer (at-point) completion popup. Adapted from Doom's
;; :completion corfu, minus Doom-specific helpers and projectile/persp
;; integration.

(use-package corfu
  :demand t
  :init
  (setq corfu-auto t
        corfu-auto-delay 0.24
        corfu-auto-prefix 2
        corfu-cycle t
        corfu-preselect 'prompt
        corfu-count 16
        corfu-max-width 120
        corfu-on-exact-match nil
        corfu-quit-at-boundary 'separator
        corfu-quit-no-match    'separator
        ;; Pressing TAB completes when there's something to complete; falls
        ;; through to indent otherwise.
        tab-always-indent 'complete
        ;; Skip corfu in modes where popups are noise.
        global-corfu-modes
        '((not erc-mode
               circe-mode
               help-mode
               gud-mode
               vterm-mode)
          t))
  :config
  (global-corfu-mode 1)

  ;; In evil insert state, finishing the insert should dismiss the popup.
  ;; C-n/C-p and C-j/C-k come from evil-collection-corfu; nothing to add.
  (when (modulep! :editor evil)
    (add-hook 'evil-insert-state-exit-hook #'corfu-quit))

  ;; Terminal popup support: only require/configure corfu-terminal when we
  ;; might serve a TTY frame. Pure GUI launches never load it.
  (when (or (daemonp) (not (display-graphic-p)))
    (require 'corfu-terminal)
    (defun scratch-corfu--enable-terminal-for-tty (&optional frame)
      "Activate `corfu-terminal-mode' when FRAME is a TTY frame."
      (when (and frame (not (display-graphic-p frame)))
        (corfu-terminal-mode +1)))
    (unless (or (daemonp) (display-graphic-p))
      (corfu-terminal-mode +1))
    (add-hook 'after-make-frame-functions
              #'scratch-corfu--enable-terminal-for-tty)))

;; corfu-history / corfu-popupinfo ship as files inside the corfu repo's
;; extensions/ directory (available on load-path via the recipe override
;; in packages.el). Just require them.
(require 'corfu-history)
(add-hook 'corfu-mode-hook #'corfu-history-mode)
(with-eval-after-load 'savehist
  (add-to-list 'savehist-additional-variables 'corfu-history))

(require 'corfu-popupinfo)
(setq corfu-popupinfo-delay '(0.5 . 1.0))
(add-hook 'corfu-mode-hook #'corfu-popupinfo-mode)

;; nerd-icons-corfu -- glyphs in the popup margin (matches the modeline icons).
(use-package nerd-icons-corfu
  :after corfu
  :init
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; cape -- completion-at-point extensions. Composable functions that plug
;; into `completion-at-point-functions' to add file paths, in-buffer
;; word completion, and elisp blocks in org/markdown.
(use-package cape
  :defer t
  :init
  (add-hook 'prog-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-file -10 t)))
  (dolist (hook '(org-mode-hook markdown-mode-hook))
    (add-hook hook
              (lambda ()
                (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t))))
  :config
  ;; Make LSP/eglot capfs composable so cape extensions can stack on top.
  (advice-add #'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-nonexclusive))
