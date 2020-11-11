;; elemental --- intuitive defaults


;; Author: Henrik Kjerringvåg
;; Url: https://github.com/hkjels/elemental
;; Version: 0.0.1
;;; Commentary:
;; Elemental changes a lot of default configurations of Emacs to
;; be more intuitive and to improve performance.
;;
;;; License:
;; 
;;
;; -*- no-byte-compile: t; -*-
;; -*- lexical-binding: t; -*-
;;; Code:

;; Dependencies

;; These come bundled with newer versions of Emacs

(require 'ansi-color)
(require 'autorevert)
(require 'compile)
(require 'dired)
(require 'esh-mode)
(require 'files)
(require 'help)
(require 'savehist)
(require 'saveplace)
(require 'uniquify)

;; Lets just agree on UTF-8


(prefer-coding-system 'utf-8-unix)

;; Less nagging

;; I don't need bells and whistles to know that the movement I'm trying
;; to do is invalid. Let's just turn it off.

(setq-default ring-bell-function 'ignore)

;; Reduce clutter in .emacs.d

;; So, [[https://github.com/emacscollective/no-littering][no-littering]] is a package that will put files and directories that
;; usually are littered all over your ~.emacs.d~ into two directories in
;; ~.emacs.d~, ~var~ and ~etc~.

(use-package no-littering
  :config
  (setq-default custom-file (no-littering-expand-etc-file-name "custom.el"))
  (load custom-file :noerror)
  (setq-default make-backup-files t
  	      backup-by-copying t
  	      backup-directory-alist `(("." . ,(no-littering-expand-var-file-name "backup")))
  	      auto-save-file-name-transforms `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)) ))

;; Backup

;; Without configuration, Emacs will store backup's of files you're
;; editing in the same directory as the file in question. Although, not a
;; bad idea in theory, you rarely need these backup's and they make a
;; mess with version-control etc. A better solution, is to keep all
;; backup's in a directory of it's own. This way, you can also delete
;; them all in a swoop if you're confident that they won't save your ass
;; down the line.
;; #+name: backup

(setq-default make-backup-files t
	      backup-by-copying t
	      backup-directory-alist `(("." . ,(no-littering-expand-var-file-name "backup")))
	      auto-save-file-name-transforms `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)) )

;; Improved help

;; Generally; when I ask for help, I would like it as prompt as possible.
;; The setting below allows me to read and browse whatever help I request
;; immediately.

(setq-default help-window-select t)



;; Helpful adds some useful context to the regular old help. It does
;; however not add any bindings on it's own to make it available. Lets
;; fix that!

(use-package helpful
  :commands (helpful-callable helpful-variable helpful-key helpful-at-point)
  :bind (([remap describe-function] . helpful-callable)
	 ([remap describe-variable] . helpful-variable)
	 ([remap describe-key] . helpful-key)
	 :map emacs-lisp-mode-map
         ("C-c C-d" . helpful-at-point)))

;; Garbage collection

;; Garbage Collection can make your Emacs instance crawl to a halt. To
;; gain maximum performance, we do GC for the most part when Emacs is
;; idle. For now, this is left entirely up to ~gcmh~, but I have
;; experienced a hickup every now and then, so this might change moving
;; forward.

(use-package gcmh
  :blackout
  :config (gcmh-mode t))

;; Better safe than sorry

;; Most operating systems have a concept of trash. A temporary storage
;; for stuff to get rid of. Emacs can use this feature, instead of
;; deleting directly, giving you a little safety-net. MacOS also has this
;; feature, but it's not natively implemented in Emacs, so we use a
;; package to handle it.

(setq-default delete-by-moving-to-trash t)

(use-package osx-trash
  :when (eq system-type 'darwin)
  :config
  (osx-trash-setup))



;; If the files you're deleting are under version control, you likely
;; want to use the delete command from the source control system instead.
;; Here we make it so that Emacs will prompt you for what action to take
;; in this situation. Unfortunately, vc-delete has it's own little
;; confirmation prompt, so it requires multiple interactions on the users
;; behalf.

(defvar tangling-p nil
  "If you're in the process of tangling an org-file or not.")
(add-hook 'org-babel-pre-tangle-hook (lambda () (setq tangling? t)))
(add-hook 'org-babel-post-tangle-hook (lambda () (setq tangling? nil)))

(defun elementary-delete-file-advice (file &optional trash)
  "Prompt the user if she wants to delete the FILE from revision-control or not."
  (if (and (vc-backend file)
	   (not tangling-p)
	   (y-or-n-p "Delete from revision system?"))
      (progn (vc-delete-file file) nil)
    t))

(advice-add 'delete-file :before-while #'elementary-delete-file-advice)
(advice-add 'dired-delete-file :before-while (lambda (file &optional recursive trash) (elementary-delete-file-advice file)))

;; Use changes from the file-system

;; In Emacs, this is called ~autorevert~ and is turned off by default. This
;; more often than not will lead to confusion I think, so we want it
;; turned on to reflect the reality.

(setq-default auto-revert-verbose nil
	      global-auto-revert-non-file-buffers t
	      create-lockfiles nil)
(global-auto-revert-mode t)



;; Each of the major operating systems have ways of notifying about
;; file-changes. We can tap into these instead of polling for changes.

(setq-default auto-revert-use-notify t)
(setq-default auto-revert-avoid-polling t)

;; Handle viewing minified files

;; So long remedies performance issues with files that have very long
;; lines. One of the remedies is making the buffer read-only, but these
;; are usually minified files anyways and should not be dealt with by
;; hand.

(use-package so-long
  :config (global-so-long-mode t))

;; Keep more history

;; As long as you haven't made a conscious jump into a position of a
;; file, I think it's a good idea to start at the position you were last
;; time you had it open.

(save-place-mode t)



;; We can persist a bunch of variables to disk, so that we don't have to
;; start with an entirely blank slate on the next session.

(use-package savehist
  :straight nil
  :after (no-littering)
  :config
  (setq-default savefile-dir (no-littering-expand-var-file-name "savefile")
		history-delete-duplicates t
		savehist-save-minibuffer-history t
		savehist-autosave-interval nil
		savehist-additional-variables
		'(kill-ring
		  mark-ring global-mark-ring
		  search-ring regexp-search-ring
		  shell-command-history))
  (savehist-mode t))

;; Ensure that buffer names are unique

;; Having two different buffers with the same name makes it alot harder
;; to distinguish them. Here we set some rules for how Emacs should make
;; their names unique.

(setq-default uniquify-buffer-name-style 'forward
	      uniquify-separator "/")



;; After a buffer is killed, we re-rationalize the buffer names.

(setq-default uniquify-after-kill-buffer-p t)



;; But at all times, we leave all "special" buffers as is.

(setq-default uniquify-ignore-buffers-re "^\\*")

;; Group buffers for better context


(use-package ibuffer-vc
  :commands (ibuffer-vc)
  :hook (ibuffer . (lambda ()
		     (ibuffer-vc-set-filter-groups-by-vc-root)
		     (unless (eq ibuffer-sorting-mode 'alphabetic)
		       (ibuffer-do-sort-by-alphabetic))))
  :bind ([remap list-buffers] . ibuffer))

;; Streamline the Emacs shell experience

;; I believe the names of each of these variables and their value speaks
;; for themselves.

(setq-default eshell-scroll-to-bottom-on-input 'all
	      eshell-kill-on-exit t
	      eshell-destroy-buffer-when-process-dies t
	      eshell-hist-ignoredups t
	      eshell-save-history-on-exit t)



;; However, this one does not. ~nil~ here means that the size of the history
;; kept should be equal to ~$HISTSIZE~.

(setq-default eshell-history-size nil)

;; Ease working with the file system

;; Reuse ~dired~ buffers if the directory is a sub directory of an already
;; open directory. You can still spawn a new buffer of the same directory
;; if you so please.

(setq-default dired-find-subdir t)



;; If you ask to copy or delete a directory, ~dired~ should just obey.

(setq-default dired-recursive-copies 'always
	      dired-recursive-deletes 'top)



;; When you have two ~dired~ buffers open, it's very likely that you want
;; the location of your other ~dired~ buffer to be the target, this makes
;; it so.

(setq-default dired-dwim-target t)



;; Limit search in ~dired~ to the filenames.

(setq-default dired-isearch-filenames t)



;; Show human readable file-sizes.

(setq-default dired-listing-switches "-alh")



;; When you open ~dired~ it will open in your user-directory. That's fine
;; when there's no context to start from. But if it's a file-buffer that
;; you're in when you invoke ~dired~, I think it makes more sense to start
;; at the position of that file.

(defun dired-default-directory ()
  (interactive)
  (dired default-directory))

(add-hook 'after-init-hook
	  (lambda ()
	    (define-key (current-global-map) [remap dired] #'dired-default-directory)))

;; Use only one theme at a time

;; The default behavior of Emacs is that you can compose multiple themes;
;; however, in practice that's never done and will likely just mess
;; things up. With this little advice, we tell Emacs that once a theme is
;; loaded, all prior themes should be disabled.

(defadvice load-theme (before theme-dont-propagate activate)
 (progn (mapc #'disable-theme custom-enabled-themes)
        (run-hooks 'after-load-theme-hook)))

;; Correct appearance of the title-bar on MacOS


(use-package ns-auto-titlebar
  :when (and (eq system-type 'darwin)
	     (or (display-graphic-p) (daemonp)))
  :config (ns-auto-titlebar-mode))

;; Adjust the behavior of the compilation buffer

;; We customize the compilation-mode slightly. The names and values
;; should be self-explanatory.

(setq-default compilation-auto-jump-to-first-error t
	      compilation-scroll-output t)



;; Then we sprinkle on some color for compilers that use ANSI escape codes

(defun colorize-compilation-buffer ()
  (when (eq major-mode 'compilation-mode)
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region (point-min) (point-max)))))

(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

;; A better starting-point for Org-mode

;; This little snippet allows you to toggle a narrowed state. It's not
;; specific to org-mode, but it works with source-blocks or subtree's if
;; there's no region selected.

(defun narrow-or-widen-dwim ()
  "If narrowed, widen. Otherwise, it narrows to region, org-source or
  org subtree."
  (interactive)
  (cond ((buffer-narrowed-p) (widen))
        ((org-src-edit-buffer-p) (org-edit-src-exit))
        ((region-active-p) (narrow-to-region (region-beginning) (region-end)))
        ((equal major-mode 'org-mode)
         (cond ((ignore-errors (org-edit-src-code)) t)
               (t (org-narrow-to-subtree))))
        (t (error "Please select a region to narrow to"))))



;; Org-mode keywords have no company-backend by default, so we need to
;; supply one. I grabbed it from this [[https://emacs.stackexchange.com/questions/21171/company-mode-completion-for-org-keywords#answer-30691][StackExchange]] and changed the
;; candidates to lower-case.

(defun org-keyword-backend (command &optional arg &rest ignored)
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'org-keyword-backend))
    (prefix (and (eq major-mode 'org-mode)
                 (cons (company-grab-line "^#\\+\\(\\w*\\)" 1)
                       t)))
    (candidates (mapcar #'downcase
                        (cl-remove-if-not
                         (lambda (c) (string-prefix-p arg c))
                         (pcomplete-completions))))
    (ignore-case t)
    (duplicates t)))

(use-package org
  :commands (org-mode)
  :after (company)
  :ensure-system-package pygmentize
  :config
  (setq-default org-display-inline-images t)
  (setq-default org-startup-with-inline-images t)
  (setq-default org-display-remote-inline-images t)
  (setq-default org-src-fontify-natively t)
  (setq-default org-fontify-quote-and-verse-blocks t)
  (setq-default org-html-htmlize-output-type 'css)
  (setq-default org-latex-listings 'minted)
  (setq-default org-latex-minted-options '(("fontsize" "\\scriptsize")
  					 ("linenos" "")))
  (setq-default org-latex-pdf-process '("xelatex -shell-escape -interaction nonstopmode %f"
  				      "bibtex %b"
  				      "makeindex %b"
  				      "xelatex -shell-escape -interaction nonstopmode %f"
  				      "xelatex -shell-escape -interaction nonstopmode %f"))
    (setq-default org-pretty-entities t)
    (setq-default org-pretty-entities-include-sub-superscripts nil)
    (setq-default org-use-sub-superscripts nil)
  (setq-default org-adapt-indentation nil)          ;; Disable indentation of content below headlines
  (setq-default org-edit-src-content-indentation 0) ;; Disable indentation of source blocks
  (setq-default org-src-preserve-indentation nil)   ;; Disable indentation for exported source blocks
  (setq-default org-indent-indentation-per-level 0) ;; Keep everything flush-left
  (setq-default org-latex-logfiles-extensions
        (quote ("lof" "lot" "tex" "aux" "idx" "log" "out" "toc" "nav" "snm" "vrb"
  	      "dvi" "fdb_latexmk" "blg" "brf" "fls" "entoc" "ps" "spl" "bbl" "pyg")))
  (setq-default org-use-property-inheritance t)
  (setq-default org-imenu-depth 5)
  (setq-default org-src-window-setup 'current-window) ;; Narrow into source-code using the active window
  (setq-default org-confirm-babel-evaluate nil)       ;; It's OK to evaluate when I say so
  (setq-default org-support-shift-select 'always)     ;; Quick action in various contexts

  (setq-default org-hide-leading-stars t)    ;; Display only a single asterisk for each sub-heading
  (setq-default org-hide-emphasis-markers t) ;; Hide characters that cause visual emphasis



;; Bare minimum of languages to support via Babel.

(org-babel-do-load-languages 'org-babel-load-languages '((calc . t)
							 (emacs-lisp . t)
							 (makefile . t)
							 (shell . t)))
(add-to-list 'org-structure-template-alist '("ca" . "src calc"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("ma" . "src makefile"))
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))



;; When adding a block, you will most likely like to edit that block
;; immediately. This hook narrows into the code-block for ya!

(defun org-insert-structure-template-hook (fn &rest args)
  (progn (previous-line)
	 (if (not (eq "#+begin_src" (thing-at-point 'line)))
	     (progn (org-edit-special)
		    (evil-insert-state))
	   (next-line))))
(advice-add 'org-insert-structure-template :after #'org-insert-structure-template-hook)



;; We can replace all those ugly looking machine readings with our own
;; beautiful symbols for less visual clutter.

(defun org-pretty-symbols-mode ()
  (push '("#+title: "        . "") prettify-symbols-alist)
  (push '("#+subtitle: "     . "") prettify-symbols-alist)
  (push '("#+author: "       . "- ") prettify-symbols-alist)
  (push '(":properties:"     . ":") prettify-symbols-alist)
  (push '("#+begin_src"      . "…") prettify-symbols-alist)
  (push '("#+end_src"        . "⋱") prettify-symbols-alist)
  (push '("#+results:"       . "»") prettify-symbols-alist)
  (push '(":end:"            . "⋱") prettify-symbols-alist)
  (push '(":results:"        . "⋰") prettify-symbols-alist)
  (push '("#+name:"          . "-") prettify-symbols-alist)
  (push '("#+begin_example"  . "~") prettify-symbols-alist)
  (push '("#+end_example"    . "~") prettify-symbols-alist)
  (push '("#+begin_quote"    . "") prettify-symbols-alist)
  (push '("#+end_quote"      . "") prettify-symbols-alist)
  (push '("#+tblfm:"         . "∫") prettify-symbols-alist)
  (push '("[X]"              . (?\[ (Br . Bl) ?✓ (Br . Bl) ?\])) prettify-symbols-alist)
  (push '("\\\\"             . "↩") prettify-symbols-alist)
  (prettify-symbols-mode t))



;; Quickly split a source-block in two. It's mapped to ~C-c |~

(defun org-split-src-block ()
  (interactive)
  (let* ((el (org-element-context))
	 (p (point))
	 (language (org-element-property :language el))
	 (switches (org-element-property :switches el))
	 (parameters (org-element-property :parameters el)))
    (beginning-of-line)
    (insert (format "#+end_src\n\n#+begin_src %s %s %s" language (or switches "") (or parameters "")))))



;; Automatically tangle code-blocks that have a ~:tangle~ attribute upon
;; saving the buffer to disk.

(defun tangle-after-save ()
  (add-hook 'after-save-hook 'org-babel-tangle nil 'local))
(add-to-list 'company-backends #'org-keyword-backend)
:hook
((org-mode . org-pretty-symbols-mode)
 (org-mode . auto-fill-mode)
 (org-mode . variable-pitch-mode)
 (org-mode . tangle-after-save)
 (org-mode . (lambda () (blackout 'buffer-face-mode))))
:bind (:map org-mode-map
	    ("C-c |" . 'org-split-src-block)))

;; Use the file at point

;; When opening files etc, we can start with a populated field if our
;; point is on a filename. This will work with most buffers and feels
;; more like code-jumps than having to browse manually. Browsing manually
;; is off-course the fallback.

(ffap-bindings)

(provide 'elemental)
