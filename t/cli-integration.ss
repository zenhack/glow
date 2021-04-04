(export
  answer-questions
  supply-parameters
  set-initial-block
  read-peer-command
  read-environment)
;; Utility module for using Glow's command line interface programmatically,
;; for the purposes of integration testing (for "real" development you
;; should instead use programmatic interfaces directly).

(import :std/misc/list)
(import :std/pregexp)
(import :gerbil/gambit/ports)

(def (remove-terminal-control-seqs str)
  ;; Remove terminal control sequeneces from the input string.
  (def (do-filter chars)
    (if (null? chars)
      chars
      (begin
        (if (is-print? (car chars))
          (cons (car chars) (do-filter (cdr chars)))
          (do-filter
            (cdr (drop-until
                   (lambda (c) (equal? c #\m))
                   chars)))))))
  (list->string (do-filter (string->list str))))

(def (is-print? c)
  ;; Predicate that reports if the character c is in the printable
  ;; ascii range, i.e. non-control ascii characters.
  (def codepoint (char->integer c))
  (and
    (<= (char->integer #\space) codepoint)
    (<= codepoint 127)))

(def (answer-questions q-and-as)
  ;; Read a series of questions from (current-input-port), and feed
  ;; the corresponding answers to (current-output-port).
  ;;
  ;; The questions should be like:
  ;;
  ;;   Choose your role:
  ;;   1) Buyer
  ;;   2) Seller
  ;;   Enter number:
  ;;
  ;; The argument should be an association list mapping questions
  ;; (in the above example "Choose your role:") to textual answers
  ;; (in the above, "Buyer" or "Seller").
  ;;
  ;; An error is rased if any of the questions are presented out
  ;; of sequence or are missing.
  (map
    (lambda (q-and-a)
      (def q (read-question (car q-and-a)))
      (answer-question
        q
        (cadr q-and-a)))
    q-and-as))

(def (read-clean-line)
  ;; Read a line from the input, and strip out any terminal escape sequences.
  (def raw-line (read-line))
  (if (equal? raw-line #!eof)
    #!eof
    (remove-terminal-control-seqs raw-line)))

(def (find-first-line matches?)
  ;; Skip past any lines in the input that don't match the predicate `matches?`,
  ;; and return the first line that does.
  (def line (read-clean-line))
  (cond
    ((equal? line #!eof)
     (error "Unexpected EOF"))
    ((matches? line) line)
    (else
      (find-first-line matches?))))

(defstruct question
  (prompt  ;; The prompt for the question, e.g. "Choose your role:":
   options ;; A hash table mapping the textual answers to the numeric option
           ;; (as a string) that must be entered to choose that answer:
  ))

(def (read-question prompt)
  ;; Look for the provided question prompt in the input, and read in
  ;; a question struct.
  (find-first-line
    (lambda (line)
      (string=? prompt line)))
  (def options
    (read-options))
  (make-question prompt options))

(def (read-options)
  ;; Helper for read-question; reads in the hash table for the
  ;; options slot.
  (def table (make-hash-table))
  (def (read-all)
    (def line (read-clean-line))
    (unless (string-prefix? "Enter " line)
      (match (pregexp-match "^([0-9]+)\\) (.*)$" line)
        ([_ no value]
         (hash-put! table value no))
        (error "expected option like 1) value, but got " line))
      (read-all)))
  (read-all)
  table)

(def (displayln-now . args)
  (apply displayln args)
  (force-output))

(def (answer-question question answer)
  ;; Answer a Question object "question" with the provided answer.
  (def option-num (hash-ref (question-options question) answer))
  (displayln-now option-num))

(def (supply-parameters params)
  (map
    (lambda (kv)
      (def key (car kv))
      (def value (cadr kv))
      (def prompt
        (find-first-line
          (lambda (line)
            (or
              (string-prefix? "Enter " line)
              (string-prefix? "> Enter " line)))))
      (if
        (or
          (string=? prompt (string-append "Enter " key))
          (string=? prompt (string-append "> Enter " key)))
        (displayln-now value)
        (error "expected " key " but got " prompt)))
    params))

(def (set-initial-block)
  ;; Replies to the probpt "Max initial block [...]", using the current
  ;; block number as the selection.
  (def prompt
    (find-first-line
      (lambda (line) (string-prefix? "Max initial block [" line))))
  (def prompt-expr
    (with-input-from-string (string-append "(" prompt ")") read))
  (def num (car (filter number? (flatten prompt-expr))))
  (displayln-now num))

(def (read-peer-command)
  ;; Scans the input for the command to run on the other side.
  (find-first-line
    (lambda (line) (string-prefix? "glow start-interaction --agreement " line))))

(def (read-environment)
  ;; Finds the environment logged at the end of a cli run, parses
  ;; it, and returns it as a hash table.
  (find-first-line
    (lambda (line) (string=? line "Final environment:")))
  (def table (make-hash-table))
  (def (read-all)
    (def line (read-environment-line))
    (match line
      ([key value]
       (hash-put! table key value)
       (read-all))
      (_ (void))))
  (read-all)
  table)

(def (read-environment-line)
  ;; helper for read-environment; reads a single line.
  (def line (read-clean-line))
  (if (equal? line #!eof)
    #!eof
    (with-input-from-string line
      (lambda ()
        (def key (read))
        (read) ; skip over the =>
        [key (read)]))))