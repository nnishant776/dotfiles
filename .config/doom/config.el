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
;; (setq
;;   load-no-native t
;;   load-prefer-newer t
;;   )


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

(require 'json)

;; =========================================================================
;; 1. PATH CONFIGURATIONS AND LANGUAGE DICTIONARIES
;; =========================================================================
(defvar vscode-global-settings-path "~/.config/Code/User/settings.json"
  "Absolute file path pointing directly to your global VSCode settings profile.")

(defvar vscode-to-emacs-modes
  '(("go"         . go-mode)
    ("yaml"       . yaml-mode)
    ("gotmpl"     . go-template-mode)
    ("python"     . python-mode)
    ("javascript" . js2-mode)
    ("typescript" . typescript-mode)
    ("markdown"   . markdown-mode)
    ("lua"        . lua-mode)
    ("make"       . makefile-mode))
  "Dict structure mapping VSCode bracket language tags cleanly over to Emacs major modes.")

(defvar theme-translation-alist
  '(("Visual Studio Dark" . doom-vibrant)
    ("Default Light+"     . doom-one-light))
  "Alist mapping VSCode theme strings to Doom Emacs theme symbols.")

;; Performance optimizations variables
(defvar global-fallback-font nil)
(defvar vscode-global-cache nil
  "In-memory storage to prevent constantly reading the global settings.json from disk.")
(defvar last-processed-project nil
  "Tracks the current project root to stop identical theme/font updates when jumping tabs.")

;; =========================================================================
;; 2. POLYFILL HELPER: SAFELY READ AND DECODE JSON FILES WITHOUT CRASHING
;; =========================================================================
(defun read-json-file (file-path)
  "Read and parse a JSON file using a universal fallback mechanism."
  (when (and file-path (file-exists-p file-path))
    (with-temp-buffer
      (insert-file-contents file-path)
      (goto-char (point-min))
      (let ((json-object-type 'alist)
            (json-array-type 'vector)
            (json-key-type 'symbol)
            (json-false :false)
            (json-null :null))
        (condition-case nil
            (json-read)
          (error nil))))))

;; =========================================================================
;; 3. THE CENTRAL TRANSLATION ENGINE (KEY-VALUE ALIST MAPPER)
;; =========================================================================
(defun translate-and-apply-vscode-key (key val)
  "Convert native VSCode parameter strings into isolated, buffer-local Emacs configuration actions."
  (pcase (cond ((stringp key) key)
               ((symbolp key) (symbol-name key))
               (t ""))
    ;; Basic Buffer Indentation Configurations
    ("editor.tabSize"
     (setq-local tab-width val))
    ("editor.insertSpaces"
     (let ((is-true (and val (not (eq val :false)) (not (eq val :nil)))))
       (setq-local indent-tabs-mode (not is-true))))

    ;; Indentation Guides Explicit Handling via indent-bars
    ("editor.guides.indentation"
     (let ((is-true (and val (not (eq val :false)) (not (eq val :nil)))))
       (when (fboundp 'indent-bars-mode)
         (if is-true (indent-bars-mode 1) (indent-bars-mode -1)))))

    ;; File-saving Hook Toggles (FIXED: Uses native local variables instead of redundant hooks)
    ("files.trimTrailingWhitespace"
     (let ((is-true (and val (not (eq val :false)) (not (eq val :nil)))))
       (if is-true
           (add-hook 'before-save-hook #'delete-trailing-whitespace nil t)
         (remove-hook 'before-save-hook #'delete-trailing-whitespace t))))
    ("files.trimFinalNewlines"
     (let ((is-true (and val (not (eq val :false)) (not (eq val :nil)))))
       (if is-true
           (add-hook 'before-save-hook #'delete-blank-lines nil t)
         (remove-hook 'before-save-hook #'delete-blank-lines t))))
    ("files.insertFinalNewline"
     (let ((is-true (and val (not (eq val :false)) (not (eq val :nil)))))
       (setq-local require-final-newline is-true)))

    ;; Visual Representation Controls
    ("editor.lineNumbers"
     (setq-local display-line-numbers
                 (cond ((or (equal val "on") (equal val t)) t)
                       ((equal val "relative") 'relative)
                       (t nil))))
    ("editor.renderLineHighlight"
     (let ((is-true (and val (not (eq val :false)) (not (eq val :nil)))))
       (if (and (not (equal val "none")) is-true) (hl-line-mode 1) (hl-line-mode -1))))
    ("editor.wordWrapColumn"
     (setq-local fill-column val))
    ("editor.formatOnSave"
     (let ((is-true (and val (not (eq val :false)) (not (eq val :nil)))))
       (setq-local +format-with-lsp is-true)))))

;; =========================================================================
;; 4. DIRECTORY EXCLUSION PARSER (HELPERS)
;; =========================================================================
(defun extract-clean-vscode-paths (exclude-alist)
  "Parse a VSCode exclude block and return a clean list of directory names to ignore."
  (let (ignored-dirs)
    (dolist (item exclude-alist)
      (when (and (cdr item) (not (eq (cdr item) :false)))
        (let ((path-str (symbol-name (car item))))
          (setq path-str (replace-regexp-in-string "^\\*\\*/" "" path-str))
          (setq path-str (replace-regexp-in-string "/\\*\\*$" "" path-str))
          (push path-str ignored-dirs))))
    ignored-dirs))

;; =========================================================================
;; 5. UNIFIED CASCADE PROCESSOR
;; =========================================================================
(defun apply-layered-vscode-configurations ()
  "Load, combine, and evaluate VSCode configurations in proper hierarchical cascade order."
  (unless global-fallback-font
    (setq global-fallback-font doom-font))

  ;; CACHE LAYER 1: Only parse the global settings file once per Emacs runtime session
  (unless vscode-global-cache
    (setq vscode-global-cache (read-json-file vscode-global-settings-path)))

  (let* ((global-settings vscode-global-cache)
         (project-root (doom-project-root))
         ;; CACHE LAYER 2: Detect if we are loading tabs inside the same active project
         (is-new-project (not (equal project-root last-processed-project)))
         (workspace-file (when project-root
                           (car (directory-files project-root t "\\.code-workspace$"))))
         (workspace-json (read-json-file workspace-file))
         (workspace-settings (when workspace-json
                               (alist-get 'settings workspace-json))))

    ;; Update active tracker
    (when project-root (setq last-processed-project project-root))

    ;; ---------------------------------------------------------------------
    ;; RUN STAGE 1 & 2: Apply Flat Profiles (Always isolated at Buffer Level)
    ;; ---------------------------------------------------------------------
    (when global-settings
      (dolist (pair global-settings)
        (unless (string-match "^\\[.*\\]$" (symbol-name (car pair)))
          (translate-and-apply-vscode-key (car pair) (cdr pair)))))

    (when workspace-settings
      (dolist (pair workspace-settings)
        (unless (string-match "^\\[.*\\]$" (symbol-name (car pair)))
          (translate-and-apply-vscode-key (car pair) (cdr pair)))))

    ;; ---------------------------------------------------------------------
    ;; RUN STAGE 3: Extract and Apply Nested Language Blocks
    ;; ---------------------------------------------------------------------
    (cl-labels ((process-language-blocks (settings-alist)
                  (dolist (pair settings-alist)
                    (let ((key-str (symbol-name (car pair))))
                      (when (string-match "^\\[\\(.*\\)\\]$" key-str)
                        (let* ((vscode-lang (match-string 1 key-str))
                               (matched-mode (cdr (assoc vscode-lang vscode-to-emacs-modes))))
                          (when (and matched-mode (derived-mode-p matched-mode))
                            (dolist (nested-pair (cdr pair))
                              (translate-and-apply-vscode-key (car nested-pair) (cdr nested-pair))))))))))

      (when global-settings (process-language-blocks global-settings))
      (when workspace-settings (process-language-blocks workspace-settings)))

    ;; ---------------------------------------------------------------------
    ;; RUN STAGE 4 & 5: Project UI and Directory Exclusion Checks
    ;; OPTIMIZATION: Only evaluate when crossing into a completely different project root folder
    ;; ---------------------------------------------------------------------
    (when is-new-project
      ;; Handle Directory Exclusions
      (let (raw-global-excludes raw-workspace-excludes combined-ignored)
        (when global-settings
          (setq raw-global-excludes (append (alist-get 'files.watcherExclude global-settings)
                                            (alist-get 'files.exclude global-settings))))
        (when workspace-settings
          (setq raw-workspace-excludes (append (alist-get 'files.watcherExclude workspace-settings)
                                               (alist-get 'files.exclude workspace-settings))))

        (let ((merged-list (append raw-workspace-excludes raw-global-excludes)))
          (setq combined-ignored (delete-dups (extract-clean-vscode-paths merged-list))))

        (when combined-ignored
          (when (boundp 'projectile-project-ignored-directories)
            (setq-local projectile-project-ignored-directories
                        (append combined-ignored projectile-project-ignored-directories)))
          (when (boundp 'lsp-file-watch-ignored-directories)
            (dolist (dir combined-ignored)
              (add-to-list 'lsp-file-watch-ignored-directories (concat "[/\\\\]" (regexp-quote dir) "\\'"))))))

      ;; Handle Global Theme and Font Changes safely
      (let* ((active-source (or workspace-settings global-settings))
             (font-family (alist-get 'editor.fontFamily active-source))
             (font-size (alist-get 'editor.fontSize active-source)))
        (if (and font-family font-size)
            (let ((target-font (font-spec :family font-family :size font-size)))
              (unless (equal target-font doom-font)
                (setq doom-font target-font)
                (set-frame-font doom-font t t)))
          (unless (equal doom-font global-fallback-font)
            (setq doom-font global-fallback-font)
            (set-frame-font doom-font t t))))
      (when-let* ((active-source (or workspace-settings global-settings))
                  (dark-theme-name (alist-get 'workbench.preferredDarkColorTheme active-source))
                  (light-theme-name (alist-get 'workbench.preferredLightColorTheme active-source))
                  (target-vscode-theme (if (equal (frame-parameter nil 'background-mode) 'light) light-theme-name dark-theme-name))
                  (target-emacs-theme (cdr (assoc target-vscode-theme theme-translation-alist))))
        (when (and target-emacs-theme (not (eq target-emacs-theme doom-theme)))
          (setq doom-theme target-emacs-theme)
          (load-theme doom-theme t))))))

(add-hook 'change-major-mode-after-body-hook #'apply-layered-vscode-configurations)
(add-hook 'projectile-after-switch-project-hook #'apply-layered-vscode-configurations)
