;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package:
;;
;;   1. Declare them here in a `package!' statement,
;;   2. Run 'doom sync' in the shell,
;;   3. Restart Emacs.
;;
;; Use 'C-h f package\!' to look up documentation for the `package!' macro.


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
;; (package! some-package)

;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/radian-software/straight.el#the-recipe-format
;; (package! another-package
;;   :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
;; (package! this-package
;;   :recipe (:host github :repo "username/repo"
;;            :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
;; (package! builtin-package :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
;; (package! builtin-package :recipe (:nonrecursive t))
;; (package! builtin-package-2 :recipe (:repo "myfork/package"))

;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see radian-software/straight.el#279)
;; (package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
;; (package! builtin-package :pin "1a2b3c4d5e")


;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
;; (unpin! pinned-package)
;; ...or multiple packages
;; (unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
;; (unpin! t)

;; Every mode: the themes are cheap and only load when chosen.
(package! vs-light-theme)
(package! vs-dark-theme)
(package! catppuccin-theme :recipe (:host github :repo "catppuccin/emacs"))

;; Default and up. `+mode' is defined in init.el.
;; smartparens comes from Doom's core (the compat module), not a module flag.
(package! smartparens :disable (eq +mode 'minimal))
(package! auto-dark :disable (eq +mode 'minimal))
(package! nix-ts-mode :disable (eq +mode 'minimal))
(package! go-template-mode :disable (eq +mode 'minimal))
(package! cue-mode :disable (eq +mode 'minimal))

;; ide only.
(package! shell-maker :disable (not (+mode>= 'ide)))
(package! acp :disable (not (+mode>= 'ide)))
(package! agent-shell :disable (not (+mode>= 'ide)))
(package! eglot-luau :disable (not (+mode>= 'ide)))
(package! treesitter-context
  :recipe (:host github :repo "zbelial/treesitter-context.el")
  :disable (not (+mode>= 'ide)))

;; Not declared: go-ts-mode and yaml-ts-mode are built into Emacs 30, and
;; Doom's modules already provide nix-mode, yaml-mode, go-mode and
;; typescript-mode.
