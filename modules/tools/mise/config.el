;;; modules/tools/mise/config.el -*- lexical-binding: t; -*-
;;
;; [[https://github.com/eki3z/mise.el][mise.el]]: per-buffer integration with the `mise' CLI (the Rust
;; rewrite of `asdf'). Reads `mise.toml' / `.tool-versions' and
;; applies the project's pinned tool versions to the buffer's local
;; `process-environment' / `exec-path', so subprocesses (LSP, compile,
;; vterm) get the right `node' / `python' / `dexter' / etc. for each
;; project.
;;
;; Pairs with `:tools direnv': both run as buffer-local env layers and
;; don't overlap (mise reads its own config; direnv reads `.envrc').

(use-package mise
  :defer t
  :hook (after-init . global-mise-mode)
  :config
  (defun scratch-mise--auto-trust-worktree-a (orig-fn)
    "Auto-trust mise configs in git worktrees when the main worktree is trusted.
Wraps `mise--ensure' so buffers inside a worktree skip the interactive
trust prompt if the parent repository already has a trusted config."
    (when (and (file-exists-p default-directory)
               (executable-find mise-executable))
      (let ((exec-path (default-value 'exec-path))
            (process-environment (default-value 'process-environment)))
        (let ((git-common (ignore-errors
                            (string-trim
                             (with-output-to-string
                               (call-process "git" nil standard-output nil
                                             "rev-parse" "--git-common-dir")))))
              (git-dir (ignore-errors
                         (string-trim
                          (with-output-to-string
                            (call-process "git" nil standard-output nil
                                          "rev-parse" "--git-dir"))))))
          (when (and git-common git-dir
                     (not (string= (expand-file-name git-common)
                                   (expand-file-name git-dir))))
            (let ((trust-show (with-output-to-string
                                (mise--call standard-output "trust" "--show"))))
              (when (and (string-match-p "trusted$" trust-show)
                         (string-match-p "untrusted$" trust-show))
                (mise--call nil "trust" "--all")))))))
    (funcall orig-fn))
  (advice-add 'mise--ensure :around #'scratch-mise--auto-trust-worktree-a))
