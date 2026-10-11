;;; lisp/vcs.el -*- lexical-binding: t; -*-
;;
;; Git, project management and diff indicators.

(after! diff-hl
  (setq diff-hl-update-async nil
        diff-hl-flydiff-delay 1.0))

(setq
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
 )

(add-hook 'project-find-functions
          (lambda (dir)
            (when-let ((root (locate-dominating-file dir ".git")))
              (cons 'vc root))))
;; Doom's magit module adds these when magit loads; skip the stale-buffer
;; marking on every refresh and frame switch.
(after! magit
  (remove-hook 'magit-post-refresh-hook #'+magit-mark-stale-buffers-h)
  (remove-hook 'doom-switch-frame-hook #'+magit-mark-stale-buffers-h))
