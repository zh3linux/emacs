;;; yari.el --- Yet Another RI interface for Emacs

;; Copyright (C) 2010  Aleksei Gusev, Jose Pablo Barrantes

;; Author: Aleksei Gusev <aleksei.gusev@gmail.com>
;; Maintainer: Aleksei Gusev <aleksei.gusev@gmail.com>
;; Created: 24 Apr 2010
;; Version: 20130727.1639
;; X-Original-Version: 0.6
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; yari.el provides an Emacs frontend to Ruby's `ri' documentation
;; tool. It offers lookup and completion.
;;
;; This version will load all completion targets the first time it's
;; invoked. This can be a significant startup time, but it will not
;; have to look up anything after that point.
;;
;; This library tries to be compatible with any version of `rdoc' gem.
;; Self-testing covers all versions from 1.0.1 to 2.5.8 (current).
;;
;; The main function you should use as interface to ri is M-x yari
;; (yari-helm is a variant using Helm input framework). I recommend to
;; bind it on some key local when you are ruby-mode. Here is the example:
;;
;; (defun ri-bind-key ()
;;   (local-set-key [f1] 'yari))
;;
;;  or
;;
;; (defun ri-bind-key ()
;;   (local-set-key [f1] 'yari-helm))
;;
;; (add-hook 'ruby-mode-hook 'ri-bind-key)
;;
;; You can use C-u M-x yari to reload all completion targets.

;;; Code:

(eval-when-compile (require 'cl))

(require 'thingatpt)
(require 'ansi-color)

(defgroup yari nil
  "Yet Another Ri Interface."
  :group 'programming)

(defcustom yari-mode-hook nil
  "Hooks to run when invoking yari-mode."
  :group 'yari
  :type 'hook)

(defcustom yari-ri-program-name "ri"
  "This constant defines how yari.el will find ri, e.g. `ri1.9'.")

(defvar yari-anything-source-ri-pages
  '((name . "RI documentation")
    (candidates . (lambda () (yari-ruby-obarray)))
    (action  ("Show with Yari" . yari))
    (candidate-number-limit . 300)
    (requires-pattern . 2)
    "Source for completing RI documentation."))

;;;###autoload
(defun yari-anything (&optional rehash)
  (interactive (list current-prefix-arg))
  (when current-prefix-arg (yari-ruby-obarray rehash))
  (anything 'yari-anything-source-ri-pages (yari-symbol-at-point)))

(defvar yari-helm-ri-pages
  `((name . "RI documentation")
    (init . (lambda ()
              (helm-init-candidates-in-buffer
               'local
               (yari-ruby-obarray nil t))))
    (candidates-in-buffer)
    (candidate-number-limit . 300)
    (action . yari))
  "Source for completing RI documentation.")

;;;###autoload
(defun yari-helm ()
  (interactive)
  (helm :sources '(yari-helm-ri-pages)
        :buffer "*yari-helm*"
        :prompt "yari: "
        :input (yari-symbol-at-point)))

;;;###autoload
(defun yari (&optional ri-topic rehash)
  "Look up Ruby documentation."
  (interactive (list nil current-prefix-arg))
  (let ((completing-read-func (if (null ido-mode)
                                  'completing-read
				'ido-completing-read)))
    (setq ri-topic (or ri-topic
                       (funcall completing-read-func
				"yari: "
				(yari-ruby-obarray rehash)
				nil
				t
				(yari-symbol-at-point)))))
  (let ((yari-buffer-name (format "*yari %s*" ri-topic)))
    (unless (get-buffer yari-buffer-name)
      (let ((yari-buffer (get-buffer-create yari-buffer-name))
            (ri-content (yari-ri-lookup ri-topic)))
        (with-current-buffer yari-buffer
          (erase-buffer)
          (insert ri-content)
          (ansi-color-apply-on-region (point-min) (point-max))
          (goto-char (point-min))
          (yari-mode))))
    (display-buffer yari-buffer-name)))

(defun yari-symbol-at-point ()
  ;; TODO: make this smart about class/module at point
  (let ((yari-symbol (symbol-at-point)))
    (if yari-symbol
        (symbol-name yari-symbol)
      "")))

(defvar yari-mode-map
  (let ((map (make-keymap)))
    (suppress-keymap map t)
    (define-key map (kbd "q")    'quit-window)
    (define-key map (kbd "SPC")  'scroll-up)
    (define-key map (kbd "\C-?") 'scroll-down)
    map))

(defun yari-mode ()
  "Mode for viewing Ruby documentation."
  (buffer-disable-undo)
  (kill-all-local-variables)
  (use-local-map yari-mode-map)
  (setq mode-name "yari")
  (setq major-mode 'yari-mode)
  (setq buffer-read-only t)
  (run-hooks 'yari-mode-hook))

(defmacro when-ert-loaded (&rest body)
  `(dont-compile
     (when (featurep 'ert)
       ,@body)))

(when-ert-loaded
 (defmacro yari-with-ruby-obarray-cache-mock (cache-mock &rest body)
   (declare (indent 1))
   `(unwind-protect
	(let* ((,cache-mock '("NotExistClassInRuby" "NotExistClassInRuby#mmmmm"))
               (yari-ruby-obarray-cache ,cache-mock))
          ,@body))))


(defun yari-ri-lookup (name)
  "Return content from ri for NAME."
  (assert (member name (yari-ruby-obarray)) nil
          (format "%s is unknown symbol to RI." name))
  (shell-command-to-string
   (format (concat yari-ri-program-name " -T -f ansi %s")
           (shell-quote-argument name))))

(when-ert-loaded
 (ert-deftest yari-test-ri-lookup-should-generate-error ()
   (should-error
    (yari-ri-lookup "AbSoLuTttelyImposibleThisexists#bbb?")))

 (ert-deftest yari-test-ri-lookup-should-have-content ()
   (should (string-match "RDoc" (yari-ri-lookup "RDoc"))))

 (ert-deftest yari-test-ri-lookup ()
   (should (yari-ri-lookup "RDoc"))))


(defvar yari-ruby-obarray-cache nil
  "Variable to store all possible completions of RI pages.")

(defun yari-ruby-obarray (&optional rehash do-not-split)
  "Build collection of classes and methods for completions."
  (let ((output (yari-ruby-methods-from-ri rehash)))
    (if do-not-split
        output
      (split-string output))))

(when-ert-loaded
 (ert-deftest yari-test-ruby-obarray-should-rehash ()
   (yari-with-ruby-obarray-cache-mock
    cache-mock
    (yari-ruby-obarray t)
    (should-not (equal yari-ruby-obarray-cache cache-mock))))



 (ert-deftest yari-test-ruby-obarray-should-set-cache ()
   (let ((yari-ruby-obarray-cache))
     (yari-ruby-obarray)
     (should yari-ruby-obarray-cache)))

 (ert-deftest yari-test-ruby-obarray-for-class-first-level ()
   (should (member "RDoc" (yari-ruby-obarray))))

 (ert-deftest yari-test-ruby-obarray-for-class-deep-level ()
   (should (member "RDoc::TopLevel" (yari-ruby-obarray))))

 (ert-deftest yari-test-ruby-obarray-for-class-method ()
   (should (member "RDoc::TopLevel::new" (yari-ruby-obarray))))

 (ert-deftest yari-test-ruby-obarray-for-object-method ()
   (should (member "RDoc::TopLevel#full_name" (yari-ruby-obarray)))))

(defun yari-ruby-methods-from-ri (rehash)
  "Return string with all ruby methods known to ri command."
  (if (or rehash (null yari-ruby-obarray-cache))
    (setq yari-ruby-obarray-cache
          (yari-eval-ruby-code
            (cond
             ((yari-ri-version-at-least "2.5")
               "require 'rdoc/ri/driver';       \
                driver  = RDoc::RI::Driver.new; \
                puts driver.list_known_classes; \
                puts driver.list_methods_matching('.')")
              ((yari-ri-version-at-least "2.2.0")
               "require 'rdoc/ri/reader'; \
                require 'rdoc/ri/cache';  \
                require 'rdoc/ri/paths';  \
                all_paths = RDoc::RI::Paths.path(true,true,true,true); \
                cache  = RDoc::RI::Cache.new(all_paths); \
                reader = RDoc::RI::Reader.new(cache);    \
                puts reader.all_names")
              ((yari-ri-version-at-least "2.0.0")
               "require 'rdoc/ri/driver';            \
                driver  = RDoc::RI::Driver.new;      \
                puts driver.class_cache.keys;        \
                methods = driver.select_methods(//); \
                puts methods.map{|m| m['full_name']}")
              ((yari-ri-version-at-least "1.0.0")
               "require 'rdoc/ri/ri_reader'; \
                require 'rdoc/ri/ri_cache';  \
                require 'rdoc/ri/ri_paths'; \
                all_paths = RI::Paths.path(true,true,true,true); \
                cache = RI::RiCache.new(all_paths); \
                reader = RI::RiReader.new(cache);    \
                puts reader.all_names;")
              (t
               (error "Unknown Ri version.")))))
     yari-ruby-obarray-cache))

(when-ert-loaded
 (ert-deftest yari-test-ruby-obarray-should-use-cache ()
   (yari-with-ruby-obarray-cache-mock
       cache-mock
     (yari-ruby-methods-from-ri nil)
     (should (equal yari-ruby-obarray-cache cache-mock)))))

(defun yari-eval-ruby-code (ruby-code)
  "Return stdout from ruby -rrubyges -eRUBY-CODE."
  (shell-command-to-string (format "ruby -rrubygems -e\"%s\"" ruby-code)))

(when-ert-loaded
 (ert-deftest yari-test-ruby-obarray-filter-standard-warning ()
   (should-not (member ". not found, maybe you meant:"
                           (yari-ruby-obarray))))

 (ert-deftest yari-test-ruby-obarray-filter-updating-class-cache ()
   (should-not (let ((case-fold-search nil)
                         (bad-thing-found-p))
                     (mapc '(lambda (line)
                              (when (string-match "Updating class cache" line)
				(setq bad-thing-found-p t)))
                           (yari-ruby-obarray))
                     bad-thing-found-p)))

 (ert-deftest yari-test-ruby-obarray-filter-empty-string ()
   (should-not (member "" (yari-ruby-obarray))))

 (ert-deftest yari-test-ruby-obarray-filter-standard-ruler ()
   (should-not (member "----------------------------------------------"
                           (yari-ruby-obarray)))))

(defun yari-ri-version-at-least (minimum)
  "Detect if RI version at least MINIMUM."
  (let ((ri-version (yari-get-ri-version)))
    (or (string< minimum ri-version) (string= minimum ri-version))))

(defun yari-get-ri-version (&optional version)
  "Return list of version parts or RI."
  (let* ((raw-version-output
          (or version (shell-command-to-string
                       (concat yari-ri-program-name " --version"))))
         (raw-version (cadr (split-string raw-version-output))))
    (string-match "v?\\(.*\\)" raw-version)
    (match-string 1 raw-version)))

(when-ert-loaded
 (ert-deftest yari-test-get-ri-version-for-1.0.0 ()
   (should (equal "1.0.1" (yari-get-ri-version "ri v1.0.1 - 20041108"))))
 (ert-deftest yari-test-get-ri-version-for-2.5.6 ()
   (should (equal "2.5.6" (yari-get-ri-version "ri 2.5.6")))))

(provide 'yari)
;;; yari.el ends here
