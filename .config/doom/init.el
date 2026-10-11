;;; init.el -*- lexical-binding: t; -*-

;; This file controls what Doom modules are enabled and what order they load
;; in. Remember to run 'doom sync' after modifying it!

;; NOTE Press 'SPC h d h' (or 'C-h d h' for non-vim users) to access Doom's
;;      documentation. There you'll find a link to Doom's Module Index where all
;;      of our modules are listed, including what flags they support.

;; NOTE Move your cursor over a module's name (or its flags) and press 'K' (or
;;      'C-c c k' for non-vim users) to view its documentation. This works on
;;      flags as well (those symbols that start with a plus).
;;
;;      Alternatively, press 'gd' (or 'C-c c d') on a module to browse its
;;      directory (for easy access to its source code).

;; Launch mode, chosen by the Doom profile (see profiles.el):
;;   minimal  DOOMPROFILE=minimal: evil and vertico, for large files and text
;;   default  DOOMPROFILE=default: + UI, VCS, dired, markdown and tree-sitter
;;   ide      no profile: + completion, LSP, terminals, formatting, org, ...
;; This sits outside `doom!', so it runs at sync time and at startup. The
;; `doom' CLI doesn't apply profiles.el's variables, but `--profile NAME' does
;; export $DOOMPROFILE, so fall back to the profile name (minus any "@ref").
(defconst +mode
  (pcase (or (getenv "DOOM_MODE")
             (car (split-string (or (getenv "DOOMPROFILE") "") "@")))
    ("minimal" 'minimal)
    ("default" 'default)
    (_ 'ide))
  "The launch mode: `minimal', `default' or `ide'.")

(defun +mode>= (level)
  "Return non-nil if the launch mode includes LEVEL."
  (>= (cl-position +mode '(minimal default ide))
      (cl-position level '(minimal default ide))))

(doom! :input
       ;;bidi              ; (tfel ot) thgir etirw uoy gnipleh
       ;;chinese
       ;;japanese
       ;;layout            ; auie,ctsrnm is the superior home row

       :completion
       ;;company           ; the ultimate code completion backend
       (:when (+mode>= 'ide) (corfu +orderless))  ; complete with cap(f), cape and a flying feather!
       ;;helm              ; the *other* search engine for love and life
       ;;ido               ; the other *other* search engine...
       ;;ivy               ; a search engine for love and life
       vertico           ; the search engine of the future

       :ui
       ;;deft              ; notational velocity for Emacs
       (:when (+mode>= 'default)
        doom              ; what makes DOOM look the way it does
        nerd-icons)
       ;; doom-dashboard    ; a nifty splash screen for Emacs
       ;;doom-quit         ; DOOM quit-message prompts when you quit Emacs
       ;;(emoji +unicode)  ; 🙂
       (:when (+mode>= 'default) hl-todo) ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       (:when (+mode>= 'ide) indent-guides) ; highlighted indent columns
       ;; ligatures         ; ligatures and symbols to make your code pretty again
       ;;minimap           ; show a map of the code on the side
       (:when (+mode>= 'default) modeline) ; snazzy, Atom-inspired modeline, plus API
       ;;nav-flash         ; blink cursor line after big motions
       ;;neotree           ; a project drawer, like NERDTree for vim
       ;; ophints           ; highlight the region an operation acts on
       (:when (+mode>= 'default) (popup +defaults)) ; tame sudden yet inevitable temporary windows
       (:when (+mode>= 'ide)
        smooth-scroll     ; So smooth you won't believe it's not butter
        tabs)             ; a tab bar for Emacs
       ;; treemacs          ; a project drawer, like neotree but cooler
       (:when (+mode>= 'default)
        unicode           ; extended unicode support for various languages
        (vc-gutter +pretty)) ; vcs diff in the fringe
       ;; vi-tilde-fringe   ; fringe tildes to mark beyond EOB
       ;;window-select     ; visually switch windows
       (:when (+mode>= 'default) workspaces) ; tab emulation, persistence & separate workspaces
       ;;zen               ; distraction-free coding or writing

       :editor
       ;; +everywhere gives magit, dired and friends evil keys.
       (:if (+mode>= 'default) (evil +everywhere) evil) ; come to the dark side, we have cookies
       ;; file-templates    ; auto-snippets for empty files
       (:when (+mode>= 'ide)
        fold              ; (nigh) universal code folding
        (format +onsave)) ; automated prettiness
       ;;god               ; run Emacs commands without modifier keys
       ;;lispy             ; vim for lisp, for people who don't like vim
       ;;multiple-cursors  ; editing in many places at once
       ;;objed             ; text object editing for the innocent
       ;;parinfer          ; turn lisp into python, sort of
       ;;rotate-text       ; cycle region at point between text candidates
       ;; No +guess (dtrt-indent, disabled in lisp/defaults.el) or +trim
       ;; (ws-butler ignores "files.trimTrailingWhitespace").
       (:when (+mode>= 'ide)
        snippets          ; my elves. They type so I don't have to
        whitespace)       ; a butler for your whitespace
       ;;word-wrap         ; soft wrapping with language-aware indent

       :emacs
       (:when (+mode>= 'default) dired) ; making dired pretty [functional]
       ;; electric          ; smarter, keyword-based electric-indent
       ;; eww               ; the internet is gross
       (:when (+mode>= 'default) ibuffer) ; interactive buffer management
       ;; tramp             ; remote files at your arthritic fingertips
       ;; Not in minimal: undo-fu-session writes and re-reads undo history
       ;; files, which is slow on huge files. Evil uses `undo-redo' instead.
       (:when (+mode>= 'default) undo) ; persistent, smarter undo for your inevitable mistakes
       ;; vc                ; version-control and Emacs, sitting in a tree

       :term
       ;;eshell            ; the elisp shell that works everywhere
       ;;shell             ; simple shell REPL for Emacs
       ;;term              ; basic terminal emulator for Emacs
       (:when (+mode>= 'ide) vterm) ; the best terminal emulation in Emacs

       :checkers
       ;; syntax              ; tasing you for every semicolon you forget
       ;;(spell +flyspell) ; tasing you for misspelling mispelling
       ;;grammar           ; tasing grammar mistake every you make

       :tools
       ;;ansible
       ;;biblio            ; Writes a PhD for you (citation needed)
       ;;collab            ; buffers with friends
       ;;debugger          ; FIXME stepping through code, to help you add bugs
       ;;direnv
       ;; docker
       ;;editorconfig      ; let someone else argue about tabs vs spaces
       ;;ein               ; tame Jupyter notebooks with emacs
       ;; (eval +overlay)     ; run code, run (also, repls)
       (:when (+mode>= 'ide) lookup) ; navigate your code and its documentation
       ;;llm               ; when I said you needed friends, I didn't mean...
       (:when (+mode>= 'ide) (lsp +eglot)) ; M-x vscode
       (:when (+mode>= 'default) magit) ; a git porcelain for Emacs
       ;;make              ; run make tasks from Emacs
       ;;pass              ; password manager for nerds
       ;;pdf               ; pdf enhancements
       ;;terraform         ; infrastructure as code
       ;; tmux              ; an API for interacting with tmux
       (:when (+mode>= 'default) tree-sitter) ; syntax and parsing, sitting in a tree...
       ;;upload            ; map local to remote projects via ssh/ftp

       :os
       (:if (featurep :system 'macos) macos)  ; improve compatibility with macOS
       tty               ; improve the terminal Emacs experience

       :lang
       ;; Languages need default; LSP and the heavier ones are ide-only.
       (:when (+mode>= 'default)
       ;;ada               ; In strong typing we (blindly) trust
       ;;agda              ; types of types of types of types...
       ;;beancount         ; mind the GAAP
       (:if (+mode>= 'ide) (cc +lsp +tree-sitter) (cc +tree-sitter))         ; C > C++ == 1
       ;;clojure           ; java with a lisp
       ;;common-lisp       ; if you've seen one lisp, you've seen them all
       ;;coq               ; proofs-as-programs
       ;;crystal           ; ruby at the speed of c
       ;;csharp            ; unity, .NET, and mono shenanigans
       ;;data              ; config/data formats
       ;;(dart +flutter)   ; paint ui and not much else
       ;;dhall
       ;;elixir            ; erlang done right
       ;;elm               ; care for a cup of TEA?
       emacs-lisp        ; drown in parentheses
       ;;erlang            ; an elegant language for a more civilized age
       ;;ess               ; emacs speaks statistics
       ;;factor
       ;;faust             ; dsp, but you get to keep your soul
       ;;fortran           ; in FORTRAN, GOD is REAL (unless declared INTEGER)
       ;;fsharp            ; ML stands for Microsoft's Language
       ;;fstar             ; (dependent) types and (monadic) effects and Z3
       ;;gdscript          ; the language you waited for
       (:if (+mode>= 'ide) (go +lsp +tree-sitter) (go +tree-sitter))         ; the hipster dialect
       ;;(graphql +lsp)    ; Give queries a REST
       ;;(haskell +lsp)    ; a language that's lazier than I am
       ;;hy                ; readability of scheme w/ speed of python
       ;;idris             ; a language you can depend on
       (json +tree-sitter)              ; At least it ain't XML
       ;;janet             ; Fun fact: Janet is me!
       ;;(java +lsp)       ; the poster child for carpal tunnel syndrome
       (:if (+mode>= 'ide) (javascript +lsp +tree-sitter) (javascript +tree-sitter))        ; all(hope(abandon(ye(who(enter(here))))))
       ;;julia             ; a better, faster MATLAB
       ;;kotlin            ; a better, slicker Java(Script)
       ;;latex             ; writing papers in Emacs has never been so fun
       ;;lean              ; for folks with too much to prove
       ;;ledger            ; be audit you can be
       (:if (+mode>= 'ide) (lua +lsp +tree-sitter) (lua +tree-sitter))               ; one-based indices? one-based indices
       (:if (+mode>= 'ide) (markdown +grip) markdown) ; writing docs for people to ignore
       ;;nim               ; python + lisp at the speed of c
       (:if (+mode>= 'ide) (nix +lsp +tree-sitter) (nix +tree-sitter))               ; I hereby declare "nix geht mehr!"
       ;;ocaml             ; an objective camel
       (:when (+mode>= 'ide) org) ; organize your plain life in plain text
       ;;php               ; perl's insecure younger brother
       ;;plantuml          ; diagrams for confusing people more
       ;;graphviz          ; diagrams for confusing yourself even more
       ;;purescript        ; javascript, but functional
       (:if (+mode>= 'ide) (python +lsp +tree-sitter) (python +tree-sitter))            ; beautiful is better than ugly
       ;;qt                ; the 'cutest' gui framework ever
       ;;racket            ; a DSL for DSLs
       ;;raku              ; the artist formerly known as perl6
       ;;rest              ; Emacs as a REST client
       (:when (+mode>= 'ide) rst) ; ReST in peace
       (:when (+mode>= 'ide) (ruby +rails)) ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
       (:when (+mode>= 'ide) (rust +lsp)) ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       ;;scala             ; java, but good
       ;;(scheme +guile)   ; a fully conniving family of lisps
       sh                ; she sells {ba,z,fi}sh shells on the C xor
       ;;sml
       ;;solidity          ; do you need a blockchain? No.
       ;;swift             ; who asked for emoji variables?
       ;;terra             ; Earth and Moon in alignment for performance.
       ;;web               ; the tubes
       (:if (+mode>= 'ide) yaml (yaml +tree-sitter)) ; JSON, but readable
       (:if (+mode>= 'ide) (zig +lsp +tree-sitter) (zig +tree-sitter)))               ; C, but simpler

       :email
       ;;(mu4e +org +gmail)
       ;;notmuch
       ;;(wanderlust +gmail)

       :app
       ;;calendar
       ;;emms
       ;;everywhere        ; *leave* Emacs!? You must be joking
       ;;irc               ; how neckbeards socialize
       ;;(rss +org)        ; emacs as an RSS reader
       ;; emacs-application-framework

       :config
       ;;literate
       (:if (+mode>= 'default) (default +bindings +smartparens) (default +bindings)))
