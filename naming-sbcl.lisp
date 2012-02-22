(in-package #:log4cl-impl)

(defun include-block-debug-name? (debug-name)
  "Figures out if we should include the debug-name into the stack of
nested blocks..  Should return the symbol to use.

For now SBCL seems to use:

  SYMBOL => normal defun block
  (LABELS SYMBOL) => inside of labels function
  (FLET SYMBOL)   => inside of flet function
  (LAMBDA (arglist) => inside of anonymous lambda
  (SB-PCL::FAST-METHOD SYMBOL ...) for defmethod
  (SB-PCL::VARARGS-ENTRY (SB-PCL::FAST-METHOD SYMBOL )) for defmethod with &rest parametwer
  (SB-C::HAIRY-ARG-PROCESSOR SYMBOL) => for functions with complex lambda lists

In all of the above cases except LAMBDA we simply return SYMBOL, for
LAMBDA we return the word LAMBDA and NIL for anything else.

Example: As a result of this default logger name for SBCL for the
following form:

   (defmethod foo ()
     (labels ((bar ()
                (funcall (lambda ()
                           (flet ((baz ()
                                    (log-info \"test\")))
                             (baz))))))
       (bar)))

will be: package.foo.bar.baz

"
  (if (symbolp debug-name)
      (when (and (not (member debug-name '(sb-c::.anonymous. 
                                           sb-thread::with-mutex-thunk)))
                 (not (equal 0 (search "CLEANUP-FUN-"
                                       (symbol-name debug-name)))))
        debug-name)
      (case (first debug-name)
        (labels (include-block-debug-name? (second debug-name)))
        (flet (include-block-debug-name? (second debug-name)))
        ;; (lambda 'lambda)
        (SB-PCL::FAST-METHOD (rest debug-name))
        (SB-C::HAIRY-ARG-PROCESSOR (include-block-debug-name? (second debug-name)))
        (SB-C::VARARGS-ENTRY (include-block-debug-name? (second debug-name))))))

(defun sbcl-get-block-name  (env)
  "Return a list naming SBCL lexical environment. For example when
compiling local function FOO inside a global function FOOBAR, will
return \(FOOBAR FOO\)"
  (let* ((names-from-lexenv
           (nreverse
            (loop
              as lambda = (sb-c::lexenv-lambda env)
              then (sb-c::lambda-parent lambda)
              while lambda
              as debug-name = (include-block-debug-name? (sb-c::leaf-debug-name lambda))
              if debug-name collect debug-name)))
         (name (or names-from-lexenv sb-pcl::*method-name*)))
    (when (and (consp (car name))
               (equal (length name) 1))
      (setq name (car name)))
    (loop for elem in name
          if (consp elem)
          ;; flatten method specializers and remove T ones
          append (remove t elem)
          else collect elem)))


(defmethod enclosing-scope-block-name (package env)
  "Return the enclosing block name suitable for naming a logger"
  (declare (ignore package))
  (sbcl-get-block-name env))
