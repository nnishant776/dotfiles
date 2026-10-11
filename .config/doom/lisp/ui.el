;;; lisp/ui.el -*- lexical-binding: t; -*-
;;
;; Themes and modeline.

;; (setq
;;  doom-font (font-spec :family "Fira Code" :size 13 :weight 'semi-light)
;;  doom-variable-pitch-font (font-spec :family "Fira Code" :size 13 :weight 'semi-light)
;;  )

(use-package! auto-dark
  :custom
  (auto-dark-themes '((doom-feather-dark) (doom-feather-light)))
  (auto-dark-polling-interval-seconds 5)
  (auto-dark-allow-osascript nil)
  (auto-dark-allow-powershell nil)
  ;; (auto-dark-detection-method nil) ;; dangerous to be set manually
  :init
  (setq! custom-safe-themes t)
  (auto-dark-mode t))

(after! persp-mode
  (setq doom-modeline-persp-name t)    ; Displays current workspace name
  (setq doom-modeline-display-icon t)  ; Displays workspace icon if supported
  )
