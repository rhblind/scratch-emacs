;;; modules/ui/fonts/config.el -*- lexical-binding: t; -*-
;;
;; Doom-style font configuration: set `scratch-font',
;; `scratch-variable-pitch-font', etc. to `font-spec' objects (or XFT
;; strings) and the module wires them to the right faces, sets up
;; symbol / emoji fallbacks, and provides big-font-mode for
;; presentations.
;;
;; Flags:
;;   +ligatures  -- enable font ligatures (-> => != etc.) in prog-mode.
;;                  Requires a ligature-capable font (Fira Code, JetBrains
;;                  Mono, Cascadia Code, ...).
;;
;; Overrides (set BEFORE calling `scratch!'):
;;   scratch-font                   -- primary monospace (default + fixed-pitch).
;;   scratch-variable-pitch-font    -- prose / variable-pitch face.
;;   scratch-serif-font             -- fixed-pitch-serif face.
;;   scratch-symbol-font            -- symbol / math glyph fallback.
;;   scratch-big-font               -- for scratch-big-font-mode.
;;   scratch-mixed-pitch-modes      -- modes to auto-enable mixed-pitch in.
;;
;; Each font variable accepts a `font-spec', a font object, or an
;; XFT / XLFD string:
;;
;;   (setq scratch-font (font-spec :family "Fira Code" :size 13))
;;   (setq scratch-font "JetBrains Mono-14")

(require 'cl-lib)

;;;; Font variables

(defvar scratch-font nil
  "The primary font for editing (applies to `default' and `fixed-pitch').
Must be a `font-spec', a font object, or an XFT/XLFD string.
nil keeps the system default at `scratch-font-height'.

Examples:
  (setq scratch-font (font-spec :family \"Fira Code\" :size 13 :weight 'semi-light))
  (setq scratch-font \"JetBrains Mono-14\")

Override by `setq' BEFORE calling `scratch!'.")

(defvar scratch-variable-pitch-font nil
  "Variable-pitch font for prose modes (org, markdown, help, ...).
Same formats as `scratch-font'. An omitted size inherits from
`scratch-font'. Override by `setq' BEFORE calling `scratch!'.")

(defvar scratch-serif-font nil
  "Font for the `fixed-pitch-serif' face.
Same formats as `scratch-font'. Override by `setq' BEFORE calling `scratch!'.")

(defvar scratch-symbol-font nil
  "Fallback font for symbols and mathematical glyphs.
Same formats as `scratch-font'. Avoid specifying a size (it hard-locks
all uses of this font to that size). Override by `setq' BEFORE
calling `scratch!'.")

(defvar scratch-big-font nil
  "Font for `scratch-big-font-mode' (presentations / streaming).
If nil, `scratch-font' is scaled up by `scratch-big-font-increment'.
Same formats as `scratch-font'.")

(defvar scratch-font-height 140
  "Default font height in 1/10 pt (e.g. 140 = 14pt).
Only used when `scratch-font' is nil. Override by `setq' BEFORE
calling `scratch!'.")

(defvar scratch-font-increment 2
  "Font-size step for `scratch/increase-font-size' and
`scratch/decrease-font-size'.")

(defvar scratch-big-font-increment 4
  "Font-size steps when `scratch-big-font-mode' is on and
`scratch-big-font' is nil.")

;;;; Core

(defun scratch-fonts--apply (&optional reload)
  "Apply `scratch-*-font' variables to the appropriate faces.
When RELOAD is non-nil, re-initialize symbol/emoji fontsets too."
  (dolist (mapping `((default          . ,scratch-font)
                     (fixed-pitch      . ,scratch-font)
                     (fixed-pitch-serif . ,scratch-serif-font)
                     (variable-pitch   . ,scratch-variable-pitch-font)))
    (let ((face (car mapping))
          (font (cdr mapping)))
      (condition-case err
          (if font
              (when (display-multi-font-p)
                (set-face-attribute face nil
                                    :width 'normal :weight 'normal
                                    :slant 'normal :font font))
            (when (eq face 'default)
              (set-face-attribute 'default nil :height scratch-font-height)))
        (error
         (message "scratch-fonts: error setting %s face: %s"
                  face (error-message-string err))))))
  ;; Sync fixed-pitch family with default when no explicit font is set,
  ;; so mixed-pitch-mode doesn't fall back to generic "Monospace" (which
  ;; resolves to Courier on macOS).
  (unless scratch-font
    (let ((resolved (face-attribute 'default :family)))
      (when resolved
        (set-face-attribute 'fixed-pitch nil :family resolved))))
  ;; Symbol / emoji fontset registration (once, or on reload).
  (when (and (fboundp 'set-fontset-font)
             (display-multi-font-p)
             (or reload (not (get 'scratch-font 'fontset-initialized))))
    (let* ((families (font-family-list))
           (find (lambda (candidates)
                   (cl-find-if (lambda (f) (member f families)) candidates)))
           (sym-font (or scratch-symbol-font
                         (funcall find '("Symbola" "Apple Symbols" "Symbol"))))
           (emoji-font (funcall find '("Apple Color Emoji" "Segoe UI Emoji"
                                       "Noto Color Emoji" "Noto Emoji"))))
      (when sym-font
        (dolist (script '(symbol mathematical))
          (set-fontset-font t script sym-font)))
      (when emoji-font
        (when (>= emacs-major-version 28)
          (set-fontset-font t 'emoji emoji-font))
        (set-fontset-font t 'symbol emoji-font nil 'append))
      (when (member "Symbols Nerd Font Mono" families)
        (dolist (range '((#xe000 . #xf8ff) (#xf0000 . #xfffff)))
          (set-fontset-font t range "Symbols Nerd Font Mono"))))
    (put 'scratch-font 'fontset-initialized t))
  (run-hooks 'after-setting-font-hook))

(if (daemonp)
    (add-hook 'server-after-make-frame-hook
              (lambda () (scratch-fonts--apply)))
  (scratch-fonts--apply))

;;;; Commands

(defun scratch/reload-font ()
  "Reload fonts from `scratch-*-font' variables."
  (interactive)
  (scratch-fonts--apply 'reload)
  (message "Fonts reloaded"))

;;;; Zoom keybindings
;;
;; Per-buffer: M-= / M-- / M-0 (text-scale-*).
;; All buffers: C-M-= / C-M-- / C-M-0 (scratch/increase- / decrease- /
;; reset-font-size). The :os macos module adds Cmd variants.

(setq text-scale-mode-step 1.07)

(global-set-key (kbd "M-=") #'text-scale-increase)
(global-set-key (kbd "M--") #'text-scale-decrease)
(global-set-key (kbd "M-0") #'scratch/reset-font-size)
(global-set-key (kbd "C-M-=") #'scratch/increase-font-size)
(global-set-key (kbd "C-M--") #'scratch/decrease-font-size)
(global-set-key (kbd "C-M-0") #'scratch/reset-font-size)

(defun scratch/increase-font-size (count)
  "Increase font size by COUNT steps (each step = `scratch-font-increment' pt)."
  (interactive "p")
  (scratch-fonts--adjust-size (* count scratch-font-increment)))

(defun scratch/decrease-font-size (count)
  "Decrease font size by COUNT steps."
  (interactive "p")
  (scratch-fonts--adjust-size (* (- count) scratch-font-increment)))

(defun scratch/reset-font-size ()
  "Reset font size to the original value."
  (interactive)
  (when (and (boundp 'text-scale-mode-amount)
             (/= text-scale-mode-amount 0))
    (text-scale-set 0))
  (when (bound-and-true-p scratch-big-font-mode)
    (scratch-big-font-mode -1))
  (scratch-fonts--adjust-size nil)
  (message "Font size reset"))

(defun scratch-fonts--adjust-size (increment)
  "Adjust font size by INCREMENT points. nil resets to original."
  (unless (display-multi-font-p)
    (user-error "Cannot resize fonts in terminal Emacs"))
  (dolist (mapping '((scratch-font . default)
                     (scratch-serif-font . fixed-pitch-serif)
                     (scratch-variable-pitch-font . variable-pitch)))
    (let* ((var (car mapping))
           (face (cdr mapping))
           (original (or (symbol-value var)
                         (face-font face)
                         (face-font 'default))))
      (when original
        (if (null increment)
            (when (get var 'pre-adjust-value)
              (set var (get var 'pre-adjust-value))
              (put var 'pre-adjust-value nil))
          (unless (get var 'pre-adjust-value)
            (put var 'pre-adjust-value original))
          (let* ((font (scratch-fonts--normalize original))
                 (old-size (font-get font :size))
                 (new-size (+ old-size increment)))
            (when (<= new-size 0)
              (error "Font `%s' too small to resize (%d)" var new-size))
            (font-put font :size new-size)
            (set var font))))))
  (scratch-fonts--apply 'reload))

(defun scratch-fonts--normalize (font)
  "Return FONT as a mutable font-spec with :size populated."
  (let* ((font-obj (cond ((stringp font)
                          (font-spec :name font))
                         ((fontp font)
                          (font-spec :name (font-xlfd-name font)))
                         (t (error "Unsupported font type: %S" (type-of font))))))
    (unless (font-get font-obj :size)
      (font-put font-obj :size
                (font-get (font-spec :name (face-font 'default)) :size)))
    font-obj))

;;;; Big-font mode

(define-minor-mode scratch-big-font-mode
  "Globally resize fonts for presentations or streaming.
Uses `scratch-big-font' if set, otherwise scales `scratch-font'
up by `scratch-big-font-increment' points."
  :init-value nil
  :lighter " BIG"
  :global t
  (cond
   ((not scratch-big-font-mode)
    (scratch-fonts--adjust-size nil))
   (scratch-big-font
    (let ((size (font-get (scratch-fonts--normalize scratch-big-font) :size)))
      (scratch-fonts--adjust-size nil)
      (scratch-fonts--adjust-size size)))
   (t
    (scratch-fonts--adjust-size scratch-big-font-increment))))

;;;; Mixed-pitch -- variable-pitch in prose modes

(defvar scratch-mixed-pitch-modes
  '(org-mode markdown-mode gfm-mode Info-mode
             help-mode apropos-mode
             Man-mode woman-mode)
  "Modes in which `mixed-pitch-mode' should auto-enable.
Covers prose modes (org / markdown), the help / describe-* family
\(`SPC h f' / `h v' / `h m' / ...), and Unix man / woman pages.
Code samples, identifiers, and font-lock'd regions stay fixed-pitch
via `mixed-pitch-fixed-pitch-faces'.

Override by `setq' BEFORE calling `scratch!'. To disable mixed-pitch
entirely, `(setq scratch-mixed-pitch-modes nil)'.")

(use-package mixed-pitch
  :commands mixed-pitch-mode
  :init
  (defun scratch-fonts--init-mixed-pitch-h ()
    "Enable mixed-pitch in already-open buffers and add a hook to each
mode in `scratch-mixed-pitch-modes' so future buffers get it too."
    (when (memq major-mode scratch-mixed-pitch-modes)
      (mixed-pitch-mode 1))
    (dolist (mode scratch-mixed-pitch-modes)
      (add-hook (intern (format "%s-hook" mode)) #'mixed-pitch-mode)))
  (add-hook 'emacs-startup-hook #'scratch-fonts--init-mixed-pitch-h)
  :config
  (setq mixed-pitch-set-height t)
  (add-to-list 'mixed-pitch-fixed-pitch-faces 'Info-quoted))

;;;; Ligatures (+ligatures flag)
;;
;; Font-level ligatures via composition-function-table. Requires a
;; ligature-capable font (Fira Code, JetBrains Mono, Cascadia Code, ...).
;; Enable with `(fonts +ligatures)' in the scratch! declaration.

(when (modulep! +ligatures)
  (use-package ligature
    :config
    (ligature-set-ligatures
     'prog-mode
     '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
       ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
       "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
       "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
       "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
       "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
       "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
       "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
       ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
       "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
       "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
       "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
       "\\\\" "://"))
    (global-ligature-mode 1)))
