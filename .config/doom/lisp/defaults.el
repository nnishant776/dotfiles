;;; lisp/defaults.el -*- lexical-binding: t; -*-
;;
;; Core editor defaults: things that configure Emacs itself rather than a
;; specific package.

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
;; (setq
;;   load-no-native t
;;   load-prefer-newer t
;;   )

(after! dtrt-indent
  (dtrt-indent-mode -1))

;; Default parameter configurations
(setq-default
 ;; Editor configurations
 display-line-numbers-type 'relative
 display-line-numbers-width 6
 tab-width 4
 evil-shift-width 4
 visible-bell nil
 visible-cursor nil
 )

(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))

;; Dynamic Parameter configurations
(setq
 ;; Editor configurations
 blink-matching-paren nil
 doom-detect-indentation-excluded-modes '(t)
 )

;; Hooks configurations
;; Setting a mode's variable doesn't toggle the mode, so disable these by
;; removing the hooks Doom uses to turn them on.
;; Emacs enables `show-paren-mode' by default, so also turn it off explicitly.
(remove-hook 'doom-first-buffer-hook #'show-paren-mode)
(show-paren-mode -1)
(remove-hook 'doom-first-buffer-hook #'global-emojify-mode)
(remove-hook! '(text-mode-hook conf-mode-hook) #'display-line-numbers-mode)

;; Minimal mode: opening and navigating large log files and big chunks of text.
;; Doom's core already turns off bidi reordering, skips fontification while
;; typing, truncates lines and enables `global-so-long-mode'.
(defvar +minimal-large-file-size (* 10 1024 1024)
  "In minimal mode, files bigger than this many bytes open in `fundamental-mode'.")

(when (eq +mode 'minimal)
  ;; No syntax highlighting.
  (global-font-lock-mode -1)
  ;; No line numbers or current-line highlight. The modeline's line and column
  ;; counter stays.
  (remove-hook 'prog-mode-hook #'display-line-numbers-mode)
  (remove-hook 'doom-first-input-hook #'global-hl-line-mode)
  ;; Don't re-read a changed file on every buffer and window switch; a log
  ;; that's still being written would be reloaded in full each time. Use
  ;; `revert-buffer', or `auto-revert-tail-mode' to follow a growing log.
  (remove-hook 'doom-first-file-hook #'doom-auto-revert-mode)
  ;; No recent files list, key hints or eldoc. (smartparens is disabled in
  ;; packages.el; snippets and completion are ide-only modules.)
  (remove-hook 'doom-first-file-hook #'recentf-mode)
  (remove-hook 'doom-first-input-hook #'which-key-mode)
  (global-eldoc-mode -1)
  ;; Skip the major mode and its hooks for big files. `magic-mode-alist' is
  ;; consulted before `auto-mode-alist'.
  (push (cons (lambda () (> (buffer-size) +minimal-large-file-size))
              #'fundamental-mode)
        magic-mode-alist)
  (setq large-file-warning-threshold (* 512 1024 1024)
        ;; No VCS; also stops Emacs running git for every file it opens.
        vc-handled-backends nil
        ;; Nothing heavy is left to preload while idle.
        doom-incremental-first-idle-timer nil))
