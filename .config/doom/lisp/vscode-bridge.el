;;; lisp/vscode-bridge.el -*- lexical-binding: t; -*-
;;
;; Bridges VSCode settings into buffer-local Emacs configuration.
;;
;; For every file-visiting editing buffer, settings are resolved in VSCode's
;; precedence order, lowest first:
;;   1. global settings.json
;;   2. the project's *.code-workspace "settings"
;;   3. [lang] blocks from global settings.json
;;   4. [lang] blocks from the workspace
;;   5. `+vscode-mode-overrides' for the launch mode (see init.el)
;; As in VSCode, language-specific settings override non-language ones even
;; from a broader scope. The result is applied as buffer-local state, re-applied
;; on every major-mode change, and refreshed when a settings file is saved.
;; Special buffers (magit, terminals, agent-shell, help, ...) are never touched.

;;
;;; Configuration

(defvar +vscode-global-settings-path "~/.config/nvim/settings.json"
  "Path to the global VSCode settings file.")

(defvar +vscode-language-modes
  '(("go"             go-mode go-ts-mode)
    ("yaml"           yaml-mode yaml-ts-mode)
    ("gotmpl"         go-template-mode)
    ("python"         python-mode python-base-mode)
    ("javascript"     js-mode js-base-mode)
    ("typescript"     typescript-mode typescript-ts-base-mode)
    ("markdown"       markdown-mode markdown-ts-mode)
    ("lua"            lua-mode lua-ts-mode)
    ("make"           makefile-mode)
    ("nix"            nix-mode nix-ts-mode)
    ("json"           json-ts-mode js-json-mode)
    ("cue"            cue-mode)
    ("code-workspace" json-ts-mode js-json-mode))
  "Map VSCode language IDs to Emacs major modes.
A [lang] block applies to buffers whose major mode derives from any of the
modes. `files.associations' switches to the first one, after
`major-mode-remap' (so tree-sitter variants are used when Doom prefers them).")

(defvar +vscode-excluded-modes
  '(special-mode comint-mode term-mode vterm-mode eshell-mode)
  "Major modes (and their derivatives) VSCode settings never apply to.
Covers magit (via `magit-section-mode'), agent-shell and other comint shells,
terminals, help and dired buffers.")

(defvar +vscode-mode-overrides
  (when (eq +mode 'minimal)
    '((editor.lineNumbers . "off")
      (editor.renderLineHighlight . "none")
      (editor.matchBrackets . "never")
      (editor.guides.indentation . :false)
      (editor.stickyScroll.enabled . :false)))
  "Settings forced for the launch mode, merged after every other layer.
Minimal mode keeps editing settings (tab width, trimming, ...) but drops the
visual ones.")

;;
;;; State

(defvar +vscode--json-cache (make-hash-table :test #'equal)
  "Parsed settings files, keyed by absolute path: (MTIME . DATA).")

(defvar-local +vscode--settings nil
  "The VSCode settings resolved for this buffer.")

(defvar-local +vscode--indent-guides nil
  "`:on' or `:off' when VSCode settings decide indent guides here, else nil.")

(defvar-local +vscode--occurrences-highlight nil
  "`:on' or `:off' when VSCode settings decide LSP symbol highlighting, else nil.")

(defvar-local +vscode--association-applied nil
  "Non-nil once `files.associations' has picked this buffer's major mode.")
(put '+vscode--association-applied 'permanent-local t)

;;
;;; Helpers

(defun +vscode--truthy (val)
  "Return non-nil if the JSON value VAL is true-ish."
  (not (memq val '(nil :false :null))))

(defun +vscode--read-json (path)
  "Return the JSON object at PATH as an alist, or nil.
The file is only re-parsed when its modification time changes."
  (when-let* ((path (and path (expand-file-name path)))
              (attrs (file-attributes path)))
    (let ((mtime (file-attribute-modification-time attrs))
          (cached (gethash path +vscode--json-cache)))
      (if (and cached (equal mtime (car cached)))
          (cdr cached)
        (let ((data (with-temp-buffer
                      (insert-file-contents path)
                      (condition-case nil
                          (json-parse-buffer :object-type 'alist
                                             :false-object :false
                                             :null-object :null)
                        (json-error nil)))))
          (puthash path (cons mtime data) +vscode--json-cache)
          data)))))

(defun +vscode--workspace-file ()
  "Return the *.code-workspace file at the current project root, if any."
  (when-let ((root (doom-project-root)))
    (car (directory-files root t "\\.code-workspace\\'"))))

(defun +vscode--file-buffer-p ()
  "Return non-nil if the current buffer visits a file VSCode settings may touch."
  (when-let ((file (buffer-file-name (buffer-base-buffer))))
    (not (or (derived-mode-p +vscode-excluded-modes)
             (doom-temp-buffer-p (current-buffer))
             ;; Commit messages and friends; `git-commit-mode' itself is only
             ;; enabled later, from `find-file-hook'.
             (and (boundp 'git-commit-filename-regexp)
                  (string-match-p git-commit-filename-regexp file))))))

(defun +vscode-buffer-eligible-p ()
  "Return non-nil if VSCode editor settings apply to the current buffer."
  (and (+vscode--file-buffer-p)
       (derived-mode-p '(prog-mode text-mode conf-mode))))

;;
;;; Cascade resolution

(defun +vscode--block-languages (key)
  "Return the language IDs of a \"[lang]\" or \"[a][b]\" KEY, else nil."
  (let ((name (symbol-name key)))
    (when (string-match-p "\\`\\(?:\\[[^]]+\\]\\)+\\'" name)
      (split-string name "[][]" t))))

(defun +vscode--language-p (lang)
  "Return non-nil if the current major mode belongs to VSCode language LANG."
  (when-let ((modes (cdr (assoc lang +vscode-language-modes))))
    (derived-mode-p modes)))

(defun +vscode--flat-settings (settings)
  "Return SETTINGS without its [lang] blocks."
  (seq-remove (lambda (pair) (+vscode--block-languages (car pair))) settings))

(defun +vscode--language-settings (settings)
  "Return the contents of the [lang] blocks in SETTINGS matching this buffer."
  (let (result)
    (pcase-dolist (`(,key . ,block) settings)
      (let ((langs (+vscode--block-languages key)))
        (when (and langs (listp block) (seq-some #'+vscode--language-p langs))
          (setq result (append result block)))))
    result))

(defun +vscode--merge (&rest layers)
  "Merge settings LAYERS into one alist; later layers win."
  (let (merged)
    (dolist (layer layers)
      (pcase-dolist (`(,key . ,val) layer)
        (setf (alist-get key merged) val)))
    (nreverse merged)))

(defun +vscode--resolve (global workspace)
  "Resolve GLOBAL and WORKSPACE settings for the current buffer."
  (+vscode--merge (+vscode--flat-settings global)
                  (+vscode--flat-settings workspace)
                  (+vscode--language-settings global)
                  (+vscode--language-settings workspace)
                  +vscode-mode-overrides))

;;
;;; File associations

(defun +vscode--association-mode (associations)
  "Return the major mode ASSOCIATIONS assign to the current buffer's file."
  (let ((file (buffer-file-name (buffer-base-buffer))))
    (seq-some
     (pcase-lambda (`(,pattern . ,lang))
       (let ((pattern (if (symbolp pattern) (symbol-name pattern) pattern)))
         (when (and (stringp lang)
                    (string-match-p (wildcard-to-regexp pattern)
                                    (if (string-search "/" pattern)
                                        file
                                      (file-name-nondirectory file))))
           (cadr (assoc (downcase lang) +vscode-language-modes)))))
     associations)))

(defun +vscode--maybe-apply-association (global workspace)
  "Switch major mode per `files.associations'; return non-nil if it did.
Workspace associations take precedence over global ones."
  (unless +vscode--association-applied
    (when-let* ((mode (+vscode--association-mode
                       (append (alist-get 'files.associations workspace)
                               (alist-get 'files.associations global))))
                (mode (major-mode-remap mode))
                ((fboundp mode))
                ((not (derived-mode-p mode))))
      ;; Set first: the new mode re-runs `after-change-major-mode-hook'.
      (setq +vscode--association-applied t)
      (funcall mode)
      t)))

;;
;;; Applying settings

(defun +vscode--trim-trailing-whitespace-h ()
  "Delete trailing whitespace on every line, leaving final newlines alone."
  (let ((delete-trailing-lines nil))
    (delete-trailing-whitespace)))

(defun +vscode--trim-final-newlines-h ()
  "Delete newlines after the buffer's final newline."
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-max))
      (skip-chars-backward "\n")
      (when (< (1+ (point)) (point-max))
        (delete-region (1+ (point)) (point-max))))))

(defun +vscode--show-paren-enclosing-data ()
  "Like the default `show-paren-data-function', falling back to the
innermost enclosing pair, as VSCode's \"editor.matchBrackets\": \"always\" does."
  (or (funcall (default-value 'show-paren-data-function))
      (when-let* ((open (nth 1 (syntax-ppss)))
                  (close (ignore-errors (scan-lists open 1 0))))
        (list open (1+ open) (1- close) close nil))))

(defun +vscode--sync-occurrences-highlight ()
  "Make eglot's symbol highlighting match `+vscode--occurrences-highlight'.
Runs from `eglot-managed-mode-hook', since eglot usually connects after the
settings are applied."
  (when (and +vscode--occurrences-highlight
             (fboundp 'eglot-managed-p)
             (eglot-managed-p))
    ;; eglot checks this list on every request, so a buffer-local copy of the
    ;; global value is enough.
    (let ((ignored (remq :documentHighlightProvider
                         (default-value 'eglot-ignored-server-capabilities))))
      (setq-local eglot-ignored-server-capabilities
                  (if (eq +vscode--occurrences-highlight :off)
                      (cons :documentHighlightProvider ignored)
                    ignored)))
    (when (eq +vscode--occurrences-highlight :off)
      (dolist (ov (bound-and-true-p eglot--highlights))
        (when (eq (overlay-buffer ov) (current-buffer))
          (delete-overlay ov))))))

(defun +vscode--apply-key (key val)
  "Apply the VSCode setting KEY with value VAL to the current buffer."
  (pcase (symbol-name key)
    ("editor.tabSize"
     (when (natnump val)
       (setq-local tab-width val
                   standard-indent val
                   evil-shift-width val
                   indent-bars-spacing-override val)
       ;; Also sets the major mode's own indent variables.
       (doom-set-indent val)))

    ("editor.insertSpaces"
     (setq-local indent-tabs-mode (not (+vscode--truthy val))))

    ;; Read by `+vscode-inhibit-indent-guides-p'; Doom enables indent-bars
    ;; after this hook runs.
    ("editor.guides.indentation"
     (setq +vscode--indent-guides (if (+vscode--truthy val) :on :off)))

    ;; VSCode's sticky scroll maps to treesitter-context. Off unless set. The
    ;; mode turns itself back off in major modes it doesn't support. The
    ;; package is only installed in ide mode.
    ("editor.stickyScroll.enabled"
     (if (+vscode--truthy val)
         (when (fboundp 'treesitter-context-mode)
           (treesitter-context-mode +1))
       (when (bound-and-true-p treesitter-context-mode)
         (treesitter-context-mode -1))))

    ("files.trimTrailingWhitespace"
     (if (+vscode--truthy val)
         (add-hook 'before-save-hook #'+vscode--trim-trailing-whitespace-h nil t)
       (remove-hook 'before-save-hook #'+vscode--trim-trailing-whitespace-h t)))

    ("files.trimFinalNewlines"
     (if (+vscode--truthy val)
         (add-hook 'before-save-hook #'+vscode--trim-final-newlines-h nil t)
       (remove-hook 'before-save-hook #'+vscode--trim-final-newlines-h t)))

    ("files.insertFinalNewline"
     (setq-local require-final-newline (+vscode--truthy val)))

    ("editor.lineNumbers"
     (pcase val
       ("relative"
        (setq-local display-line-numbers-type 'relative)
        (display-line-numbers-mode +1))
       ((or "on" "interval")
        (setq-local display-line-numbers-type t)
        (display-line-numbers-mode +1))
       (_ (display-line-numbers-mode -1))))

    ;; Doom's `global-hl-line-mode' consults `global-hl-line-modes' in each
    ;; buffer, so a buffer-local nil keeps it off here.
    ("editor.renderLineHighlight"
     (if (and (+vscode--truthy val) (not (equal val "none")))
         (progn
           (kill-local-variable 'global-hl-line-modes)
           (when (bound-and-true-p global-hl-line-mode)
             (hl-line-mode +1)))
       (setq-local global-hl-line-modes nil)
       (hl-line-mode -1)))

    ;; "near" only highlights a bracket next to point; "always" also falls back
    ;; to the enclosing pair.
    ("editor.matchBrackets"
     (if (member val '("always" "near"))
         (progn
           (if (equal val "always")
               (setq-local show-paren-data-function
                           #'+vscode--show-paren-enclosing-data)
             (kill-local-variable 'show-paren-data-function))
           (show-paren-local-mode +1))
       (kill-local-variable 'show-paren-data-function)
       (show-paren-local-mode -1)))

    ;; "singleFile" and "multiFile" both enable eglot's documentHighlight;
    ;; older VSCode versions use a boolean.
    ("editor.occurrencesHighlight"
     (setq +vscode--occurrences-highlight
           (if (and (+vscode--truthy val) (not (equal val "off"))) :on :off))
     (+vscode--sync-occurrences-highlight))

    ("editor.wordWrapColumn"
     (when (natnump val)
       (setq-local fill-column val)))

    ;; Doom's +onsave uses `apheleia-global-mode', which respects
    ;; `apheleia-inhibit'.
    ("editor.formatOnSave"
     (let ((on (+vscode--truthy val)))
       (setq-local apheleia-inhibit (not on))
       (cond ((not on)
              (when (bound-and-true-p apheleia-mode)
                (apheleia-mode -1)))
             ((bound-and-true-p apheleia-global-mode)
              (apheleia-mode-maybe)))))))

(defun +vscode-apply-h ()
  "Resolve VSCode settings for the current buffer and apply them."
  (when (+vscode--file-buffer-p)
    (let* ((global (+vscode--read-json +vscode-global-settings-path))
           (workspace (alist-get 'settings (+vscode--read-json (+vscode--workspace-file)))))
      (unless (+vscode--maybe-apply-association global workspace)
        (when (+vscode-buffer-eligible-p)
          (setq +vscode--settings (+vscode--resolve global workspace))
          (pcase-dolist (`(,key . ,val) +vscode--settings)
            (+vscode--apply-key key val)))))))

(defun +vscode-inhibit-indent-guides-p ()
  "Keep indent guides out of ineligible buffers and where VSCode disables them."
  (or (not (+vscode-buffer-eligible-p))
      (eq +vscode--indent-guides :off)))

(defun +vscode--sync-indent-guides ()
  "Make `indent-bars-mode' match the settings in an already set-up buffer."
  (when (fboundp 'indent-bars-mode)
    (cond ((+vscode-inhibit-indent-guides-p)
           (when (bound-and-true-p indent-bars-mode)
             (indent-bars-mode -1)))
          ((bound-and-true-p indent-bars-mode)
           (indent-bars-reset))
          (t (indent-bars-mode +1)))))

(defun +vscode/reapply ()
  "Re-apply VSCode settings to every eligible buffer.
Settings removed from a file are not undone; use \\[normal-mode] for that."
  (interactive)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (+vscode-buffer-eligible-p)
        (+vscode-apply-h)
        (+vscode--sync-indent-guides)))))

(defun +vscode-settings-saved-h ()
  "Re-apply settings to open buffers after a VSCode settings file is saved."
  (when (and buffer-file-name
             (or (string-suffix-p ".code-workspace" buffer-file-name)
                 (file-equal-p buffer-file-name +vscode-global-settings-path)))
    (+vscode/reapply)))

(add-hook 'after-change-major-mode-hook #'+vscode-apply-h)
(add-hook 'after-save-hook #'+vscode-settings-saved-h)
(add-hook '+indent-guides-inhibit-functions #'+vscode-inhibit-indent-guides-p)
(add-hook 'eglot-managed-mode-hook #'+vscode--sync-occurrences-highlight)
