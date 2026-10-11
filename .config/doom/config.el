;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Each file under lisp/ holds one concern. Comment out a line to disable it.
;; `+mode' (see init.el) decides which ones load.
(load! "lisp/defaults")
(load! "lisp/vscode-bridge")
(when (+mode>= 'default)
  (load! "lisp/ui")
  (load! "lisp/lang")
  (load! "lisp/vcs"))
(when (+mode>= 'ide)
  (load! "lisp/agent-shell"))
