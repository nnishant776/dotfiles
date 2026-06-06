;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Global configurations
;; (setq
;;  doom-theme 'doom-one
;;  doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;  doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13)
;;  )

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; External package dependencies
(use-package! vscode-icon
  :ensure t
  :commands (vscode-icon-for-file)
  :config
  (vscode-icon-setup))

(use-package! kubernetes-helm-mode
  :defer t
  :mode (("templates/.*\\.yaml\\'" . kubernetes-helm-mode)
         ("templates/.*\\.tpl\\'"  . kubernetes-helm-mode)
         ("values\\.yaml\\'"       . yaml-mode)))


;; Package configurations
(after! elgot
  (map! :leader
        :prefix "c"
        :desc "Eglot show call hierarchy" "h i" #'eglot-show-call-hierarchy
        )
  )

(after! diff-hl
  (setq diff-hl-update-async nil
        diff-hl-flydiff-delay 1.0))

(after! smartparens
  (setq sp-highlight-pair-overlay nil)
  )

(after! eglot
  (add-to-list 'eglot-ignored-server-capabilities :documentHighlightProvider)
  (add-to-list 'eglot-ignored-server-capabilities :semanticTokensProvider)
  )


;; Default parameter configurations
(setq-default
 ;; Editor configurations
 display-line-numbers-width 6
 tab-width 4
 evil-shift-width 4
 global-auto-revert-mode 1
 )


;; Dynamic Parameter configurations
(setq

 ;; Editor configurations
 display-line-numbers-type 'relative
 show-paren-mode -1
 blink-matching-paren nil
 global-emojify-mode -1

 ;; Project manager configurations
 projectile-indexing-method 'alien
 projectile-auto-discard-cache t

 ;; Git configurations
 magit-git-executable "/usr/bin/git"
 magit-disabled-section-inserters '(magit-insert-tags-header)
 auto-revert-check-vc-info nil
 magit-log-section-commit-count 20
 magit-refresh-status-buffer nil
 magit-submodule-list-arguments nil

 ;; LSP configurations
 lsp-enable-file-watchers nil

 )


;; Hooks configurations
(add-hook 'project-find-functions
          (lambda (dir)
            (when-let ((root (locate-dominating-file dir ".git")))
              (cons 'vc root))))
(remove-hook 'post-command-hook #'emojify-redisplay-emojis-in-region)
(remove-hook 'text-mode-hook #'emojify-mode)
(remove-hook 'doom-first-buffer-hook #'show-paren-mode)
(remove-hook 'after-save-hook #'magit-after-save-refresh-status)
(remove-hook 'magit-refresh-buffer-hook #'+magit-mark-stale-buffers-h)
