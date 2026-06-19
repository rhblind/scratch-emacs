;;; modules/lang/likec4/config.el -*- lexical-binding: t; -*-
;;
;; LikeC4 architecture-as-code support.
;; Requires: npm i -g likec4

;; --- base mode (fallback when grammar isn't installed) ---

(define-derived-mode likec4-mode prog-mode "LikeC4"
  "Major mode for LikeC4 architecture diagram files."
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "//+ *")
  (setq-local comment-end "")
  (setq-local tab-width 2)
  (setq-local indent-tabs-mode nil)
  (add-hook 'before-save-hook #'lsp-format-buffer nil t))

(add-to-list 'auto-mode-alist '("\\.c4\\'" . likec4-mode))
(add-to-list 'auto-mode-alist '("\\.likec4\\'" . likec4-mode))

;; --- tree-sitter mode ---

(add-to-list 'scratch-treesit-want 'likec4)

(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(likec4 "https://github.com/Lenivvenil/tree-sitter-likec4")))

(with-eval-after-load 'treesit-auto
  (add-to-list 'treesit-auto-recipe-list
               (make-treesit-auto-recipe
                :lang 'likec4
                :ts-mode 'likec4-ts-mode
                :remap 'likec4-mode
                :url "https://github.com/Lenivvenil/tree-sitter-likec4")))

(define-derived-mode likec4-ts-mode likec4-mode "LikeC4[ts]"
  "Tree-sitter powered major mode for LikeC4 files."
  (when (treesit-ready-p 'likec4)
    (treesit-parser-create 'likec4)
    (setq-local treesit-simple-indent-rules
                `((likec4
                   ((parent-is "source_file") column-0 0)
                   ((node-is "}") parent-bol 0)
                   ((parent-is ,(regexp-opt
                                 '("specification_block" "model_block" "views_block"
                                   "deployment_block" "global_block" "likec4lib_block"
                                   "element_body" "element_kind_declaration"
                                   "deployment_node_kind_declaration"
                                   "relationship_kind_declaration" "tag_declaration"
                                   "view_declaration" "dynamic_view_declaration"
                                   "style_block" "global_style" "global_style_group"
                                   "predicate_group" "dynamic_predicate_group"
                                   "parallel_block" "metadata_block" "view_group"
                                   "view_style_rule" "view_rank"
                                   "with_clause" "extend_element" "extend_relation"
                                   "element_declaration" "deployment_node"
                                   "relation" "deployment_relation" "import_statement")))
                    parent-bol 2)
                   (no-node parent-bol 0))))

    (setq-local treesit-font-lock-settings
                (treesit-font-lock-rules
                 :language 'likec4
                 :feature 'comment
                 '((comment) @font-lock-comment-face)

                 :language 'likec4
                 :feature 'string
                 '((string) @font-lock-string-face)

                 :language 'likec4
                 :feature 'keyword
                 '(["specification" "model" "views" "deployment" "global"
                    "likec4lib" "import" "from" "extend" "view" "dynamic"
                    "element" "tag" "relationship" "color" "deploymentNode"
                    "style" "styleGroup" "group" "rank"
                    "include" "exclude" "where" "with" "of" "extends"
                    "autoLayout" "instanceOf" "navigateTo"
                    "predicateGroup" "dynamicPredicateGroup"
                    "parallel" "par" "metadata" "variant"
                    "icons" "link" "icon" "none"]
                   @font-lock-keyword-face)

                 :language 'likec4
                 :feature 'operator
                 '(["=" "->" "<-" "<->" ".*" ".**" "._"
                    "is" "not" "and" "or"
                    "==" "!=" "!==" "element.kind" "element.tag"]
                   @font-lock-operator-face
                   (arrow_typed "-[" @font-lock-operator-face)
                   (arrow_typed "]->" @font-lock-operator-face))

                 :language 'likec4
                 :feature 'type
                 '((element_declaration kind: (identifier) @font-lock-type-face)
                   (element_kind_declaration name: (identifier) @font-lock-type-face)
                   (deployment_node_kind_declaration name: (identifier) @font-lock-type-face)
                   (relationship_kind_declaration name: (identifier) @font-lock-type-face)
                   (deployment_node kind: (identifier) @font-lock-type-face))

                 :language 'likec4
                 :feature 'definition
                 '((element_declaration name: (identifier) @font-lock-function-name-face)
                   (view_declaration name: (identifier) @font-lock-function-name-face)
                   (dynamic_view_declaration name: (identifier) @font-lock-function-name-face)
                   (deployment_node name: (identifier) @font-lock-function-name-face)
                   (tag_declaration name: (identifier) @font-lock-function-name-face)
                   (color_declaration name: (identifier) @font-lock-function-name-face)
                   (predicate_group name: (identifier) @font-lock-function-name-face)
                   (dynamic_predicate_group name: (identifier) @font-lock-function-name-face)
                   (global_style name: (identifier) @font-lock-function-name-face)
                   (global_style_group name: (identifier) @font-lock-function-name-face))

                 :language 'likec4
                 :feature 'property
                 '(["title" "description" "technology" "notation" "notes"
                    "summary" "shape" "border" "opacity" "iconColor"
                    "iconSize" "iconPosition" "multiple" "size" "padding"
                    "textSize" "line" "head" "tail"]
                   @font-lock-property-name-face)

                 :language 'likec4
                 :feature 'constant
                 '((boolean) @font-lock-constant-face
                   (wildcard) @font-lock-constant-face
                   (tag_ref "#" @font-lock-preprocessor-face
                            (identifier) @font-lock-constant-face)
                   (hex_color "#" @font-lock-preprocessor-face
                              (hex_digits) @font-lock-constant-face)
                   ["TopBottom" "LeftRight" "BottomTop" "RightLeft"
                    "same" "min" "max" "source" "sink"
                    "this" "it"]
                   @font-lock-constant-face)

                 :language 'likec4
                 :feature 'number
                 '((number) @font-lock-number-face
                   (float) @font-lock-number-face
                   (percentage) @font-lock-number-face)

                 :language 'likec4
                 :feature 'misc
                 '((lib_icon) @font-lock-constant-face
                   (uri_with_schema) @font-lock-string-face
                   (uri_relative) @font-lock-string-face
                   (uri_alias) @font-lock-string-face)))

    (setq-local treesit-font-lock-feature-list
                '((comment string)
                  (keyword type definition)
                  (property constant number operator)
                  (misc)))

    (treesit-major-mode-setup)))

;; --- LSP ---

(when (modulep! :tools lsp)
  (add-to-list 'scratch-lsp-auto-modes 'likec4-mode)
  (add-to-list 'scratch-lsp-auto-modes 'likec4-ts-mode)

  (with-eval-after-load 'lsp-mode
    (add-to-list 'lsp--formatting-indent-alist '(likec4-mode . tab-width))
    (add-to-list 'lsp--formatting-indent-alist '(likec4-ts-mode . tab-width))
    (add-to-list 'lsp-language-id-configuration '(likec4-mode . "likec4"))
    (add-to-list 'lsp-language-id-configuration '(likec4-ts-mode . "likec4"))

    (lsp-register-client
     (make-lsp-client
      :new-connection (lsp-stdio-connection '("likec4" "lsp" "--stdio"))
      :major-modes '(likec4-mode likec4-ts-mode)
      :server-id 'likec4-lsp))))

;; --- commands ---

(defun scratch-likec4--project-dir ()
  "Return the project directory for likec4 commands."
  (or (and buffer-file-name (file-name-directory buffer-file-name))
      default-directory))

(defvar scratch-likec4--preview-process nil)

(defun scratch/likec4-preview ()
  "Toggle the likec4 dev server.
Starts `likec4 dev' and opens the preview in the default browser.
Vite HMR keeps it in sync as you edit. Call again to stop."
  (interactive)
  (unless (derived-mode-p 'likec4-mode)
    (user-error "Not a likec4 buffer"))
  (if (and scratch-likec4--preview-process
           (process-live-p scratch-likec4--preview-process))
      (progn
        (delete-process scratch-likec4--preview-process)
        (setq scratch-likec4--preview-process nil)
        (message "LikeC4 preview stopped."))
    (when (and scratch-likec4--preview-process
               (not (process-live-p scratch-likec4--preview-process)))
      (setq scratch-likec4--preview-process nil))
    (let ((dir (scratch-likec4--project-dir)))
      (setq scratch-likec4--preview-process
            (start-process "likec4-dev" "*likec4-dev*"
                           "likec4" "dev" "--open" dir))
      (set-process-query-on-exit-flag scratch-likec4--preview-process nil)
      (message "LikeC4 dev server starting..."))))

(defun scratch/likec4-validate ()
  "Validate syntax, semantics and layout drifts."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 validate .")))

(defun scratch/likec4-format ()
  "Format all LikeC4 source files in the project."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 format .")))

(defun scratch/likec4-build ()
  "Build a static website from the LikeC4 project."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 build .")))

(defun scratch/likec4-export-png ()
  "Export all views as PNG images."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 export png .")))

(defun scratch/likec4-export-json ()
  "Export model to JSON."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 export json --pretty .")))

(defun scratch/likec4-export-drawio ()
  "Export views to DrawIO format."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 export drawio .")))

(defun scratch/likec4-gen-mermaid ()
  "Generate Mermaid diagram files."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 gen mermaid .")))

(defun scratch/likec4-gen-plantuml ()
  "Generate PlantUML diagram files."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 gen plantuml .")))

(defun scratch/likec4-gen-d2 ()
  "Generate D2 diagram files."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 gen d2 .")))

(defun scratch/likec4-gen-dot ()
  "Generate Graphviz dot files."
  (interactive)
  (let ((default-directory (scratch-likec4--project-dir)))
    (compile "likec4 gen dot .")))

;; --- leader bindings ---

(when (modulep! :editor leader)
  (defmacro scratch-likec4--def-localleader (mode-map)
    `(map! :map ,mode-map :localleader
       :desc "build website" "b" #'scratch/likec4-build
       :desc "format project" "f" #'scratch/likec4-format
       :desc "preview"       "p" #'scratch/likec4-preview
       :desc "validate"      "v" #'scratch/likec4-validate
       (:prefix ("e" . "export")
        :desc "PNG"    "p" #'scratch/likec4-export-png
        :desc "JSON"   "j" #'scratch/likec4-export-json
        :desc "DrawIO" "d" #'scratch/likec4-export-drawio)
       (:prefix ("g" . "generate")
        :desc "D2"       "d" #'scratch/likec4-gen-d2
        :desc "Graphviz" "g" #'scratch/likec4-gen-dot
        :desc "Mermaid"  "m" #'scratch/likec4-gen-mermaid
        :desc "PlantUML" "p" #'scratch/likec4-gen-plantuml)))

  (scratch-likec4--def-localleader likec4-mode-map)
  (scratch-likec4--def-localleader likec4-ts-mode-map))
