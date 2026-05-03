;;; modules/emacs/ibuffer/config.el -*- lexical-binding: t; -*-
;;
;; Built-in `ibuffer' tweaks: nerd-icons in the buffer column when
;; available (`:ui treemacs' or anything else that pulls in
;; `nerd-icons' satisfies this), human-readable sizes, hl-line in
;; the listing, project-aware grouping via `ibuffer-vc', plus a
;; toggle for `*'-prefixed scratch / special buffers.
;;
;; Adapted from Doom's `:emacs ibuffer'.

(use-package ibuffer
  :defer t
  :commands (ibuffer ibuffer-jump)
  :init
  (setq ibuffer-show-empty-filter-groups nil
        ibuffer-filter-group-name-face '(:inherit (success bold)))
  :config
  ;; Buffer list format: mark / modified / read-only / lock, optional
  ;; nerd-icons icon, name, size, mode, optional vc-status, then
  ;; filename. Falls back gracefully when icons or ibuffer-vc are
  ;; unavailable.
  (setq ibuffer-formats
        `((mark modified read-only locked
                ,@(if (require 'nerd-icons nil t)
                      `(" " (icon 2 2 :left :elide)
                        ,(propertize " " 'display `(space :align-to 8)))
                    '(" "))
                (name 30 30 :left :elide)
                " " (size 9 -1 :right)
                " " (mode 16 16 :left :elide)
                ,@(when (require 'ibuffer-vc nil t)
                    '(" " (vc-status 12 :left)))
                " " filename-and-process)
          (mark " " (name 30 -1) " " filename)))

  ;; Icon column. Only fires when `nerd-icons' is available (an
  ;; explicit dep -- many of our :ui modules pull it in).
  (when (require 'nerd-icons nil t)
    (define-ibuffer-column icon (:name "  ")
      (let ((icon (if (and (buffer-file-name)
                           (nerd-icons-auto-mode-match?))
                      (nerd-icons-icon-for-file
                       (file-name-nondirectory (buffer-file-name))
                       :v-adjust -0.05)
                    (nerd-icons-icon-for-mode major-mode :v-adjust -0.05))))
        (if (symbolp icon)
            (nerd-icons-faicon "nf-fa-file_o"
                               :face 'nerd-icons-dsilver
                               :height 0.8 :v-adjust 0.0)
          icon))))

  ;; Human-readable size column.
  (define-ibuffer-column size
    (:name "Size"
     :inline t
     :header-mouse-map ibuffer-size-header-map)
    (file-size-human-readable (buffer-size)))

  (add-hook 'ibuffer-mode-hook #'hl-line-mode)
  (add-hook 'ibuffer-mode-hook #'ibuffer-auto-mode))

;; ibuffer-vc: group buffers by their git/svn/hg root so each project
;; ends up in its own collapsible section.
(use-package ibuffer-vc
  :defer t
  :hook (ibuffer . scratch-ibuffer--vc-group)
  :init
  (defun scratch-ibuffer--vc-group ()
    "Group buffers by VC root via `ibuffer-vc'. Hooked to `ibuffer-hook'."
    (ibuffer-vc-set-filter-groups-by-vc-root)
    (unless (eq ibuffer-sorting-mode 'alphabetic)
      (ibuffer-do-sort-by-alphabetic))))

;;;; Toggle for `*'-prefixed special buffers (`H' in the ibuffer)

(defvar scratch-ibuffer--hide-special nil
  "Buffer-local-ish flag: when non-nil, `*'-prefixed buffers are hidden.")

(defun scratch-ibuffer--special-buffer-p (buf)
  "Return non-nil when BUF's name starts with `*'."
  (string-prefix-p "*" (buffer-name buf)))

(defun scratch/ibuffer-toggle-special-buffers ()
  "Toggle visibility of `*'-prefixed special buffers in `ibuffer'."
  (interactive)
  (setq scratch-ibuffer--hide-special (not scratch-ibuffer--hide-special))
  (cond
   (scratch-ibuffer--hide-special
    (add-to-list 'ibuffer-never-show-predicates
                 #'scratch-ibuffer--special-buffer-p)
    (message "ibuffer: hiding `*'-prefixed buffers"))
   (t
    (setq ibuffer-never-show-predicates
          (remove #'scratch-ibuffer--special-buffer-p
                  ibuffer-never-show-predicates))
    (message "ibuffer: showing all buffers")))
  (when (derived-mode-p 'ibuffer-mode)
    (ibuffer-update nil t)))

;;;; Evil bindings inside ibuffer

(when (modulep! :editor evil)
  (with-eval-after-load 'ibuffer
    (with-eval-after-load 'evil
      (evil-define-key 'normal ibuffer-mode-map
        (kbd "H")   #'scratch/ibuffer-toggle-special-buffers
        (kbd "C-j") #'ibuffer-forward-filter-group
        (kbd "C-k") #'ibuffer-backward-filter-group
        (kbd "$")   #'ibuffer-toggle-filter-group))))
