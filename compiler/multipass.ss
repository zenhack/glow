;;;;; Compiler passes

(export #t)

;; TODO:
;; - In the near future, a strategy will not be a linear list of consecutive passes,
;;   but an arbitrary DAG with meets and joins and multiple final outputs,
;;   especially due to End-Point Projection. We ought to support that.
;; - Also, some passes can be enabled or disabled (which supposes the input layer(s) are a subset
;;   of the output layer(s), so the pass can be pass-through), or parameterized, such that
;;   test vectors will depend on parameters passed to the strategy.
;;   Each individual parameter and/or collection of parameters be a "layer".
;; - In a further future, the "layers" below will be themselves types of the pass functions,
;;   and a "strategy" is a well-typed diagram written by composing these functions,
;;   all in a typed combinator language that still allows enough introspection for debugging,
;;   selection and inspection of the output, plus, hopefully, proof of correctness.
;; - Current "ancillary data" should be made of such "layers" too, using dependent types
;;   to describe how it relates to the "main" data.

(import
  :std/format :std/iter :std/misc/ports :std/misc/string
  :std/srfi/1 :std/srfi/13 :std/sugar
  :clan/utils/base :clan/utils/files
  :glow/compiler/common)

;; A "layer" of language has a name, a reader and a writer.
;; - The name, a symbol, is also the file extension of corresponding source files (e.g. 'glow => ".glow").
;; - The reader, a function from Path to some representation type R (typically, type Stx of syntax objects),
;;   reads the file at given Path into a representation of given type.
;; - The writer, a function from R and optional Port to Unit, writes a representation to the given port.
;; - Some layers don't have a reader and/or a writer (the value #f is used),
;;   so test vectors can't be directly written about them.
;; Note that the writer *may* lose some semantically secondary information, such as source location.
;; The *layers* table maps the name to a list of the reader and writer.
(def *layers* (hash))
(defstruct layer (reader writer comparer) transparent: #t) ;; defaults?
(def (register-layer name reader writer comparer)
  (hash-put! *layers* name (layer reader writer comparer)))
(def (registered-layer name) (hash-get *layers* name))
(defrule (define-layer name reader writer comparer) (register-layer 'name reader writer comparer))

;; A pass has a name, a transformation function, and input and an output.
;; - The name, a symbol, identifies the pass.
;; - The input and the output, each strings, are the names of layers defined as above.
;; - The function takes a representation for the input, plus some optional ancillary data,
;;   and returns one or multiple values; the first of which is a representation for the output,
;;   and the rest is further ancillary data to pass to the next pass.
;; The *passes* table maps the name to a list of the function, input and output layers.
(def *passes* (hash))
(defstruct pass (fun inputs outputs) transparent: #t)
(def (register-pass name fun inputs outputs) (hash-put! *passes* name (pass fun inputs outputs)))
(def (registered-pass name) (hash-get *passes* name))
(defrule (define-pass name inputs outputs) (register-pass 'name name 'inputs 'outputs))

;; A strategy has a name, and a list of passes.
;; - The name, a string, names the strategy
;; - the list of passes, by name (symbol).
;; The *strategy* table maps the name to the list of passes.
(def *strategies* (hash))
(def (register-strategy name passes) (hash-put! *strategies* name passes))
(def (registered-strategy name) (hash-get *strategies* name))
(defrule (define-strategy name pass ...) (register-strategy 'name '(pass ...)))

(def default-strategy (values #f))

;; String Path → LayerRepresentation
(def (read-file/layer layer filename)
  ((layer-reader (registered-layer layer)) filename))

;; LayerRepresentation Port → Unit
(def (write/layer layer representation (port (current-output-port)))
  ((layer-writer (registered-layer layer)) representation port))

;; Picks the longest matching known layer suffix for a given filename.
;; Thus, for "foo.sexp", return ".sexp", but for "foo.alpha.sexp" return ".alpha.sexp".
;; Path -> String
(def (identify-layer filename)
  (def layer #f) (def len -1)
  (for (k (hash-keys *layers*))
    (def ks (format ".~a" k))
    (def kl (string-length ks))
    (when (and (string-suffix? ks filename)
               (< len kl))
      (set! layer k)
      (set! len kl)))
  layer)

;; If the element is in the list,
;; return all the list elements until and including its first occurrence
;; otherwise return #f
;; TODO: move that to clan/utils/list ?
;; A (Listof A) -> (Or (Listof A) '#f)
(def (member/take x lis)
  (def rmember (member x (reverse lis)))
  (and rmember (reverse rmember)))

;; Compute relevant passes to run to go from a program representation in the start-layer
;; along the named strategy until the specified last-pass (or if false, all the subsequent passes).
;; This only works if the passes can infer any ancillary data as optional arguments.
;; At this time in practice, that only works with start-layer being the ".sexp" layer.
;; String Symbol (Or Symbol '#f) -> (Listof Symbol)
(def (relevant-passes start-layer strategy last-pass)
  (def strategy-passes
    (or (registered-strategy strategy) (error 'no-such-strategy strategy)))
  (def passes-from-layer ;; TODO: just always start from the start, or else be ready to synthesize stuff
    (or (find-tail (λ (pass) (member start-layer (pass-inputs (registered-pass pass))))
                   strategy-passes)
        (error 'no-such-layer-in-strategy start-layer strategy)))
  (if last-pass
    (or (member/take last-pass passes-from-layer)
        (error 'no-such-pass-in-strategy last-pass strategy))
    passes-from-layer))

;; Symbol String Representation+AncillaryDataIn -> Representation+AncillaryDataOut
(def (run-pass pass-name basename state)
  (match (registered-pass pass-name)
    ((pass fun inputs outputs)
     (for-each (λ (k) (when (hash-get state k)
                        (error "Can't run pass, output already exists" pass-name k)))
               outputs)
     (def results (values->list (apply fun (map (λ (k) (hash-get state k)) inputs))))
     (for ((layer-name outputs) (value results))
       (hash-put! state layer-name value)
       (def expected-output-file (format "~a.~a" basename layer-name))
       (def layer (registered-layer layer-name))
       (when (file-exists? expected-output-file)
         (unless ((layer-comparer layer) value (read-file/layer layer-name expected-output-file))
           (eprintf "output for pass ~a output ~a doesn't match expectation from ~a:\n"
                    pass-name layer-name expected-output-file)
           (write/layer layer-name value (current-error-port))
           (error 'pass-output-mismatch pass-name basename layer-name))))
     state)))

;; Path layer:  String Representation+AncillaryDataIn -> Representation+AncillaryDataOut
(def (run-passes filename
                 layer: (layer (identify-layer filename))
                 strategy: (strategy default-strategy)
                 pass: (last-pass #f)
                 show?: (show? #t)
                 save?: (save? #f))
  (def passes (relevant-passes layer strategy last-pass))
  (def in (hash (,layer (read-file/layer layer filename))))
  (def basename (string-trim-suffix (format ".~a" layer) filename))
  (def out (for/fold (state in) ((pass passes)) (run-pass pass basename state)))
  (def last-layer (first (pass-outputs (registered-pass (last passes)))))
  (def (write-last port) (write/layer last-layer (hash-ref out last-layer) port))
  (when show? (write-last (current-output-port)))
  (when save? (clobber-file (string-append basename last-layer) write-last))
  out)