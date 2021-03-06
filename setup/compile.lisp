(in-package :cl-user)

#+sbcl (require :sb-posix)

(defun heroku-getenv (target)
  #+ccl (getenv target)
  #+sbcl (sb-posix:getenv target))

(defun heroku-setenv ()
  #+ccl (ccl:setenv "XDG_CACHE_HOME" (concatenate 'string (heroku-getenv "CACHE_DIR") "/.asdf/"))
  #+sbcl (sb-posix:putenv (format nil "XDG_CACHE_HOME=~A" (concatenate 'string (heroku-getenv "CACHE_DIR") "/.asdf/"))))

(defun env-var-to-path (var)
  (make-pathname :defaults (format nil "~a/" (heroku-getenv var))))

(defvar *build-dir* (env-var-to-path "BUILD_DIR"))
(defvar *cache-dir* (pathname-directory (pathname (concatenate 'string (heroku-getenv "CACHE_DIR") "/"))))
(defvar *buildpack-dir* (pathname-directory (pathname (concatenate 'string (heroku-getenv "BUILDPACK_DIR") "/"))))
(defvar *cl-webserver* (read-from-string (heroku-getenv "CL_WEBSERVER")))
(defparameter *woo-handlers* nil)       ; if use woo to http server, then MUST redefine *woo-handlers*

;;; Tell ASDF to store binaries in the cache dir
(heroku-setenv)

(require :asdf)

(let ((ql-setup (make-pathname :directory (append *cache-dir* '("quicklisp")) :defaults "setup.lisp")))
  (if (probe-file ql-setup)
      (load ql-setup)
      (progn
        (load (make-pathname :directory (append *buildpack-dir* '("lib")) :defaults "quicklisp.lisp"))
        (funcall (symbol-function (find-symbol "INSTALL" (find-package "QUICKLISP-QUICKSTART")))
                 :path (make-pathname :directory (pathname-directory ql-setup))))))

(ecase *cl-webserver*
  (hunchentoot (ql:quickload "hunchentoot"))
  (aserve (progn
            (asdf:clear-system "acl-compat")
	    ;;; Load all .asd files in the repos subdirectory.  The compile script puts
	    ;;; several systems in there, because we are using versions that are
	    ;;; different from those in Quicklisp. (update: Can't just load the files apparently,
	    ;;; have to add dirs to asdf:*central-registry*.  Blah.
            (let* ((asds (directory (make-pathname :directory  (append *cache-dir* '( "repos" :wild-inferiors))
                                                   :name :wild
                                                   :type "asd")))
                   (directories (remove-duplicates (mapcar #'pathname-directory asds) :test #'equal)))
              (dolist (d directories)
                (push (make-pathname :directory d) asdf:*central-registry*)))))
  (woo (ql:quickload :woo)))

;;; App can redefine this to do compiletime tasks
(defun do-when-compile ())

;;; App can redefine this to do runtime initializations
(defun initialize-application ())

;;; This loads the application
(load (merge-pathnames "heroku-setup.lisp" *build-dir*))

;;; Default toplevel, app can redefine.
(defun heroku-toplevel ()
  (initialize-application)
  ;; Start the web server
  (let ((port (parse-integer (heroku-getenv "PORT"))))
    (format t "Listening on port ~A~%" port)
    (ecase *cl-webserver*
      (hunchentoot (funcall (symbol-function (find-symbol "START" (find-package "HUNCHENTOOT")))
		     (funcall 'make-instance (find-symbol "EASY-ACCEPTOR" (find-package "HUNCHENTOOT")) :port port)))
      (aserve (funcall (symbol-function (find-symbol "START" (find-package "NET.ASERVE"))) :port port))
      (woo (funcall (symbol-function (find-symbol "RUN" (find-package "WOO")))
                    (lambda (env)
                      (declare (ignore env))
                      *woo-handlers*))))
    (loop (sleep 60))))

(do-when-compile)

(defun h-save-app (app-file)
  #+ccl (save-application app-file
        :prepend-kernel t
        :toplevel-function #'heroku-toplevel)
  #+sbcl (sb-ext:save-lisp-and-die app-file
        :toplevel #'heroku-toplevel
        :executable t))

(let ((app-file (format nil "~A/lispapp" (heroku-getenv "BUILD_DIR")))) ;must match path specified in bin/release
  (format t "Saving to ~A~%" app-file)
  (h-save-app app-file))
