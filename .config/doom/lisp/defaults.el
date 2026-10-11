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
