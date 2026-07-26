;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Global configurations
;; (setq
;;  doom-font (font-spec :family "Fira Code" :size 13 :weight 'semi-light)
;;  doom-variable-pitch-font (font-spec :family "Fira Code" :size 13 :weight 'semi-light)
;;  )

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
;; (setq
;;   load-no-native t
;;   load-prefer-newer t
;;   )

(after! dtrt-indent
  (dtrt-indent-mode -1))

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

(use-package auto-dark
  :ensure t
  :custom
  (auto-dark-themes '((doom-feather-dark) (doom-feather-light)))
  (auto-dark-polling-interval-seconds 5)
  (auto-dark-allow-osascript nil)
  (auto-dark-allow-powershell nil)
  ;; (auto-dark-detection-method nil) ;; dangerous to be set manually
  :hook
  (auto-dark-dark-mode
   . (lambda ()
       ;; something to execute when dark mode is detected
       ))
  (auto-dark-light-mode
   . (lambda ()
       ;; something to execute when light mode is detected
       ))
  :init
  (setq! custom-safe-themes t)
  (auto-dark-mode t))

(use-package! treesitter-context
  :hook (doom-first-file-read . treesitter-context-mode)
  :config
  (setq treesitter-context-idle-time 0.5))

(after! persp-mode
  (setq doom-modeline-persp-name t)    ; Displays current workspace name
  (setq doom-modeline-display-icon t)  ; Displays workspace icon if supported
  )


;; Package configurations
(after! lsp
  (map!
   :leader
   :prefix "c"
   :desc "Eglot show call hierarchy" "h i" #'eglot-show-call-hierarchy
   )
  (setq eglot-autoshutdown t)
  ;; (add-to-list 'eglot-ignored-server-capabilities :documentHighlightProvider)
  ;; (add-to-list 'eglot-ignored-server-capabilities :semanticTokensProvider)
  )

(after! diff-hl
  (setq diff-hl-update-async nil
        diff-hl-flydiff-delay 1.0))

(after! smartparens
  (setq sp-highlight-pair-overlay nil)
  )


;; Default parameter configurations
(setq-default
 ;; Editor configurations
 display-line-numbers-type 'relative
 display-line-numbers-width 6
 tab-width 4
 evil-shift-width 4
 global-auto-revert-mode 1
 )


;; Dynamic Parameter configurations
(setq

 ;; Editor configurations
 display-line-numbers 'relative
 show-paren-mode -1
 blink-matching-paren nil
 global-emojify-mode -1
 doom-detect-indentation-excluded-modes '(t)

 ;; Project manager configurations
 projectile-indexing-method 'alien
 projectile-auto-discard-cache t

 ;; Git configurations
 magit-git-executable "git"
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

;; =========================================================================
;; 1. PATH CONFIGURATIONS AND LANGUAGE DICTIONARIES
;; =========================================================================
(require 'json)

(defvar vscode-global-settings-path "~/.config/nvim/settings.json"
  "Absolute file path pointing directly to your global VSCode settings profile.")

(defvar vscode-to-emacs-modes
  '(("go"                    . go-mode)
    ("yaml"                  . yaml-mode)
    ("gotmpl"                . go-template-mode)
    ("python"                . python-mode)
    ("javascript"            . js2-mode)
    ("typescript"            . typescript-mode)
    ("markdown"              . markdown-mode)
    ("lua"                   . lua-ts-mode)
    ("make"                  . makefile-mode)
    ("nix"                   . nix-ts-mode)
    ("json"                  . json-ts-mode)
    ("cue"                   . cue-mode)
    ("code-workspace"        . json-ts-mode))
  "Dict structure mapping VSCode bracket language tags cleanly over to Emacs major modes.")

(defvar theme-translation-alist
  '(("Default Dark+"      . doom-feather-dark)
    ("Default Light+"     . doom-feather-light))
  "Alist mapping VSCode theme strings to Doom Emacs theme symbols.")

;; Performance optimizations variables
(defvar global-fallback-font nil)
(defvar vscode-global-cache nil
  "In-memory storage to prevent constantly reading the global settings.json from disk.")
(defvar last-processed-project nil
  "Tracks the current project root to stop identical theme/font updates when jumping tabs.")

(defvar-local vscode-associations-applied nil
  "Tracks whether VSCode file associations have been applied to this buffer.")
(put 'vscode-associations-applied 'permanent-local t)

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
     (setq-local
      tab-width val
      evil-shift-width val
      standard-indent val
      indent-bars-spacing val
      )
     (doom/set-indent-width val)
     ;; (message "Updated tab-width to '%d'" val)
     ;; (message "Updated evil-shift-width to '%d'" val)
     ;; (message "Updated standard-indent to '%d'" val)
     (let ((is-valid (and val (not (eq val :nil))))(doom-set-indent val))))

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
                       (t nil)))
     ;; (message "Updated display-line-numbers to '%s'" display-line-numbers)
     )
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

    ;; (message "Current project root '%s'" project-root)
    ;; (message "Current workspace json '%s'" workspace-json)

    ;; Update active tracker
    (when project-root (setq last-processed-project project-root))

    ;; Apply File Associations Stage based on VSCode settings
    (when-let ((file-path buffer-file-name)
               (associations (append (when workspace-settings
                                       (alist-get 'files.associations workspace-settings))
                                     (when global-settings
                                       (alist-get 'files.associations global-settings)))))
      (unless vscode-associations-applied
        (let ((matched-lang nil))
          (catch 'found
            (dolist (pair associations)
              (let* ((pattern (car pair))
                     (lang (cdr pair))
                     (pattern-str (cond ((stringp pattern) pattern)
                                        ((symbolp pattern) (symbol-name pattern))
                                        (t (format "%s" pattern))))
                     (lang-str (downcase (cond ((stringp lang) lang)
                                               ((symbolp lang) (symbol-name lang))
                                               (t (format "%s" lang)))))
                     (regex (wildcard-to-regexp pattern-str)))
                (when (if (string-match-p "/" pattern-str)
                          (string-match-p regex file-path)
                        (string-match-p regex (file-name-nondirectory file-path)))
                  (setq matched-lang lang-str)
                  (setq matched-lang-regex regex)
                  ;; (message "Found mapping for %s in associations for regex '%s'" matched-lang regex)
                  (throw 'found t)))))
          (when matched-lang
            (let ((matched-mode (cdr (assoc matched-lang vscode-to-emacs-modes))))
              (when (and matched-mode (fboundp matched-mode))
                (unless (eq major-mode matched-mode)
                  (setq-local vscode-associations-applied t)
                  ;; (message "Setting major mode to '%s'" matched-mode)
                  (add-to-list 'auto-mode-alist (cons matched-lang-regex matched-mode))
                  )))))))


    ;; ---------------------------------------------------------------------
    ;; RUN STAGE 1 & 2: Apply Flat Profiles (Always isolated at Buffer Level)
    ;; ---------------------------------------------------------------------
    ;; (when global-settings
    ;;   (message "Applying VSCode global settings")
    ;;   (dolist (pair global-settings)
    ;;     (unless (string-match "^\\[.*\\]$" (symbol-name (car pair)))
    ;;       (translate-and-apply-vscode-key (car pair) (cdr pair)))))

    (when workspace-settings
      ;; (message "Applying VSCode workspace settings")
      (dolist (pair workspace-settings)
        (unless (string-match "^\\[.*\\]$" (symbol-name (car pair)))
          (translate-and-apply-vscode-key (car pair) (cdr pair)))))

    ;; ---------------------------------------------------------------------
    ;; RUN STAGE 3: Extract and Apply Nested Language Blocks
    ;; ---------------------------------------------------------------------
    (cl-labels ((process-language-blocks (settings-alist)
                  (dolist (pair settings-alist)
                    (let ((key-str (symbol-name (car pair))))
                      ;; (message "Inspecting key-str '%s'" key-str)
                      (when (string-match "^\\[\\(.*\\)\\]$" key-str)
                        (let* ((vscode-lang (match-string 1 key-str))
                               (matched-mode (cdr (assoc vscode-lang vscode-to-emacs-modes))))
                          ;; (message "Var dump key-str='%s' vscode-lang='%s' matched-mode='%s' current-mode='%s'" key-str vscode-lang matched-mode (derived-mode-all-parents (eval 'major-mode)))
                          (when (eq matched-mode (car (derived-mode-all-parents major-mode)))
                            ;; (message "Applying '%s' language settings" matched-mode)
                            (dolist (nested-pair (cdr pair))
                              (translate-and-apply-vscode-key (car nested-pair) (cdr nested-pair))))))))))

      ;; (when global-settings (process-language-blocks global-settings))
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
      )))

(add-hook 'after-change-major-mode-hook #'apply-layered-vscode-configurations)
(add-hook 'projectile-after-switch-project-hook #'apply-layered-vscode-configurations)


;; --------------------- Agent Shell configuration -------------------
(require 'acp)
(require 'agent-shell)
(use-package agent-shell
  :ensure t
  :config
  ;; ----------------- Global configuration options --------------
  (setopt agent-shell-write-inhibit-minor-modes '(aggresive-indent-mode))

  ;; ----------------- Agent specific configurations ------------------
  ;; ------------------ Claude code -----------------------
  (setq agent-shell-claude-environment
        (agent-shell-make-environment-variables
         "CLAUDE_CODE_USE_BEDROCK" "1"
         "AWS_REGION" "us-east-1"))

  ;; ------------------ Cursor -----------------------
  (setq agent-shell-cursor-authentication
        (agent-shell-cursor-make-authentication :login t))
  )
