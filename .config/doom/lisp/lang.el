;;; lisp/lang.el -*- lexical-binding: t; -*-
;;
;; Language tooling: tree-sitter, eglot and smartparens.

;; Build missing grammars automatically the first time a language is opened,
;; instead of prompting.
(setq treesit-auto-install-grammar 'always)

(defun +tree-sitter/install-missing-grammars ()
  "Install grammars for every tree-sitter mode enabled in init.el."
  (interactive)
  (require 'treesit)
  (let (langs)
    ;; `set-tree-sitter!' records each mode's grammars in its `+tree-sitter'
    ;; symbol property.
    (mapatoms (lambda (sym)
                (dolist (lang (cdr (get sym '+tree-sitter)))
                  (unless (or (memq lang langs) (treesit-language-available-p lang))
                    (push lang langs)))))
    (if (null langs)
        (message "All tree-sitter grammars are installed")
      (dolist (lang langs)
        (treesit-install-language-grammar lang))
      (message "Installed grammars: %s" (mapconcat #'symbol-name langs ", ")))))

(use-package! treesitter-context
  ;; Buffer-local mode; it turns itself back off in unsupported major modes.
  :hook ((prog-mode yaml-ts-mode) . treesitter-context-mode)
  :config
  (setq treesitter-context-idle-time 0.5))

(after! eglot
  (map!
   :leader
   :prefix "c"
   :desc "Eglot show call hierarchy" "h i" #'eglot-show-call-hierarchy
   )
  (setq eglot-autoshutdown t)
  (add-to-list 'eglot-ignored-server-capabilities :documentHighlightProvider)
  (add-to-list 'eglot-ignored-server-capabilities :semanticTokensProvider)
  (add-to-list 'eglot-ignored-server-capabilities :hoverProvider)
  )

(after! smartparens
  (setq sp-highlight-pair-overlay nil)
  )
