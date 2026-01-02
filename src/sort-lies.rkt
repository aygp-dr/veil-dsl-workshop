#lang racket/base

;;; "Sort" Lies: A Visual Comedy of Naming vs. Reality
;;;
;;; Demonstrating why calling something "sort" doesn't make it sort,
;;; and why contracts alone can't save us from our own bad naming.

(require racket/string
         racket/list
         racket/format)

;; -----------------------------------------------------------------------------
;; The Cast of Characters
;; -----------------------------------------------------------------------------

(define UNSORTED-FACE "😰")
(define SORTED-FACE "😊")
(define CHAOS-FACE "🤡")
(define CONFIDENT-FACE "😎")
(define BETRAYED-FACE "😱")
(define SHRUG-FACE "🤷")

;; -----------------------------------------------------------------------------
;; Our "Sort" Functions (All Claim To Sort!)
;; -----------------------------------------------------------------------------

;; Actual sort
(define (honest-sort lst)
  (sort lst <))

;; Chaos "sort" - returns random permutation
(define (chaos-sort lst)
  (shuffle lst))

;; Reverse "sort" - confidently wrong
(define (reverse-sort lst)
  (sort lst >))

;; Identity "sort" - does nothing, claims victory
(define (lazy-sort lst)
  lst)

;; Truncate "sort" - loses data!
(define (lossy-sort lst)
  (take (sort lst <) (max 1 (quotient (length lst) 2))))

;; -----------------------------------------------------------------------------
;; Visualization Helpers
;; -----------------------------------------------------------------------------

(define (list->bar lst max-val)
  (for/list ([x lst])
    (make-string (inexact->exact (floor (* 20 (/ x max-val)))) #\█)))

(define (print-bars label lst face)
  (printf "\n~a ~a\n" face label)
  (printf "~a\n" (make-string 50 #\─))
  (define max-val (apply max (cons 1 lst)))
  (for ([x lst]
        [bar (list->bar lst max-val)]
        [i (in-naturals)])
    (printf "~a │~a ~a\n"
            (~a i #:width 2 #:align 'right)
            bar
            x))
  (printf "\n"))

(define (is-sorted? lst)
  (or (null? lst)
      (null? (cdr lst))
      (and (<= (car lst) (cadr lst))
           (is-sorted? (cdr lst)))))

(define (print-verdict lst original-lst)
  (define sorted? (is-sorted? lst))
  (define same-length? (= (length lst) (length original-lst)))
  (define same-sum? (= (apply + lst) (apply + original-lst)))

  (printf "  Sorted?        ~a ~a\n"
          (if sorted? "✓" "✗")
          (if sorted? "Yes!" "NO!"))
  (printf "  Same length?   ~a ~a\n"
          (if same-length? "✓" "✗")
          (if same-length? "Yes" "NO - DATA LOST!"))
  (printf "  Sum preserved? ~a ~a\n"
          (if same-sum? "✓" "✗")
          (if same-sum? "Yes" "NO - CORRUPTION!")))

;; -----------------------------------------------------------------------------
;; The Comedy Show
;; -----------------------------------------------------------------------------

(define (scene-break title)
  (printf "\n\n")
  (printf "╔~a╗\n" (make-string 60 #\═))
  (printf "║ ~a~a║\n" title (make-string (- 59 (string-length title)) #\space))
  (printf "╚~a╝\n" (make-string 60 #\═)))

(define (run-comedy-show)
  (define example '(3 1 4 1 5 9 2 6 5 3))

  (printf "
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🎭 THE GREAT SORT IMPOSTOR SHOW 🎭                       ║
║                                                              ║
║     \"Just because it's NAMED sort doesn't mean it SORTS\"    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
")

  ;; Act 1: The Innocent Input
  (scene-break "ACT 1: Our Innocent Data")
  (print-bars "The unsuspecting input list" example UNSORTED-FACE)
  (printf "  Sum: ~a (remember this!)\n" (apply + example))

  ;; Act 2: The Honest Sort
  (scene-break "ACT 2: The Honest Sort (does what it says)")
  (define honest-result (honest-sort example))
  (print-bars "Result of honest-sort" honest-result SORTED-FACE)
  (print-verdict honest-result example)
  (printf "\n  ~a \"I sorted it. You're welcome.\"\n" CONFIDENT-FACE)

  ;; Act 3: The Chaos Sort
  (scene-break "ACT 3: The Chaos Sort (certified clown)")
  (printf "\n  ~a \"I'm totally a sort function. Trust me.\"\n\n" CHAOS-FACE)
  (for ([i (in-range 3)])
    (define chaos-result (chaos-sort example))
    (printf "  Attempt ~a: ~a ~a\n"
            (add1 i)
            chaos-result
            (if (is-sorted? chaos-result) "✓ (got lucky!)" "✗")))
  (printf "\n  ~a \"Wait... it's different every time?!\"\n" BETRAYED-FACE)

  ;; Act 4: The Confident Wrong Sort
  (scene-break "ACT 4: The Reverse Sort (confidently wrong)")
  (define reverse-result (reverse-sort example))
  (print-bars "Result of reverse-sort" reverse-result CONFIDENT-FACE)
  (print-verdict reverse-result example)
  (printf "\n  ~a \"I sorted it... just, you know, backwards.\"\n" SHRUG-FACE)

  ;; Act 5: The Lazy Sort
  (scene-break "ACT 5: The Lazy Sort (minimum viable effort)")
  (define lazy-result (lazy-sort example))
  (print-bars "Result of lazy-sort" lazy-result SHRUG-FACE)
  (print-verdict lazy-result example)
  (printf "\n  ~a \"It was already sorted in my heart.\"\n" SHRUG-FACE)

  ;; Act 6: The Lossy Sort
  (scene-break "ACT 6: The Lossy Sort (the real villain)")
  (define lossy-result (lossy-sort example))
  (print-bars "Result of lossy-sort" lossy-result BETRAYED-FACE)
  (print-verdict lossy-result example)
  (printf "\n  ~a \"WHERE IS MY DATA?!\"\n" BETRAYED-FACE)

  ;; The Moral
  (scene-break "THE MORAL")
  (printf "
  ┌─────────────────────────────────────────────────────────┐
  │                                                         │
  │  ALL of these functions could be named 'sort'           │
  │  ALL of them would pass a simple type check:            │
  │                                                         │
  │     sort : List[Int] -> List[Int]  ✓                    │
  │                                                         │
  │  But only ONE actually sorts!                           │
  │                                                         │
  │  Runtime contracts catch SOME lies:                     │
  │    • Output not sorted? → Contract violation            │
  │    • But only if we CHECK with correct comparator!      │
  │                                                         │
  │  The problem:                                           │
  │    • chaos-sort checks itself with chaos-compare        │
  │    • \"Am I sorted?\" \"Randomly... yes?\" \"Cool!\"          │
  │                                                         │
  │  ~a FORMAL VERIFICATION (Veil/Lean):                    │
  │    • Proves properties BEFORE runtime                   │
  │    • Can't lie to the theorem prover                    │
  │    • Math doesn't care what you NAME your function      │
  │                                                         │
  └─────────────────────────────────────────────────────────┘
" SORTED-FACE)

  ;; The Punchline
  (printf "
  ╭─────────────────────────────────────────────────────────╮
  │                                                         │
  │  ~a: \"I am sort.\"                                       │
  │                                                         │
  │  ~a: \"Prove it.\"                                        │
  │                                                         │
  │  ~a: \"I... can't.\"                                      │
  │                                                         │
  │  ~a: \"Then you're just a function that returns a list.\" │
  │                                                         │
  ╰─────────────────────────────────────────────────────────╯
" CHAOS-FACE SORTED-FACE CHAOS-FACE SORTED-FACE)

  (printf "\n~a THE END ~a\n\n" "🎬" "🎬"))

;; Run it!
(module+ main
  (run-comedy-show))
