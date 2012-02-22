;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*-

(defpackage :log4cl.system
  (:use :cl :asdf))

(in-package :log4cl.system)

(defsystem :log4cl
  :serial t
  :version "1.0"
  :depends-on (:bordeaux-threads)
  :components ((:file "impl-package")
               (:file "defs")
               (:file "naming")
               #+sbcl (:file "naming-sbcl")
               (:file "appender-base")
               (:file "hierarchy-base")
               (:file "hierarchy")
               (:file "logger")
               (:file "logging-macros")
               (:file "self-logger")
               ;; ;; TODO do this dynamically only if demacs
               ;; ;; package is present
               ;; (:file "demacs-integration")
	       (:file "layout")
	       (:file "simple-layout")
	       (:file "pattern-layout")
               (:file "watcher")
               (:file "appender")
               (:file "configurator")
               (:file "property-parser")
               (:file "property-configurator")
               (:file "package")))

(defsystem :log4cl-test
  :serial t
  :version "1.0"
  :depends-on (:log4cl :stefil)
  :components ((:file "test/logger")
               (:file "test/test-layouts")
               (:file "test/test-appenders")
               (:file "test/test-configurator")
               (:file "test/speed")))

(defmethod perform ((op test-op) (system (eql (find-system :log4cl))))
  (operate 'load-op :log4cl-test)
  (let ((*package* (find-package :log4cl-test)))
    (eval (read-from-string "(stefil:funcall-test-with-feedback-message 'log4cl-test::test)")))
  (values))


