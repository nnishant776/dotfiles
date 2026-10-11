;;; lisp/agent-shell.el -*- lexical-binding: t; -*-

(after! agent-shell
  ;; ----------------- Agent specific configurations ------------------
  ;; ------------------ Claude code -----------------------
  ;; (setq agent-shell-claude-environment
  ;;       (agent-shell-make-environment-variables
  ;;        "CLAUDE_CODE_USE_BEDROCK" "1"
  ;;        "AWS_REGION" "us-east-1"))

  ;; ------------------ Cursor -----------------------
  (setq agent-shell-cursor-authentication
        (agent-shell-cursor-make-authentication :login t))

  ;; ------------------ Antigravity ------------------
  (setq agent-shell-antigravity-authentication
        (agent-shell-antigravity-make-authentication :login t)))
