#lang racket/base

;;; Chaos Comparator: Why Contracts Matter
;;;
;;; This demonstrates what happens when a comparator violates its contract
;;; by returning random values instead of consistent comparison results.
;;;
;;; A valid comparator must satisfy:
;;; 1. Reflexivity: compare(x, x) = 0
;;; 2. Anti-symmetry: compare(x, y) = -compare(y, x)
;;; 3. Transitivity: if compare(x, y) < 0 and compare(y, z) < 0, then compare(x, z) < 0

(require racket/contract
         racket/list
         racket/format)

;; -----------------------------------------------------------------------------
;; Contract Definitions
;; -----------------------------------------------------------------------------

;; A comparison result is -1, 0, or 1
(define comparison-result/c
  (or/c -1 0 1))

;; A valid comparator function contract
;; This is a weak contract - just checks return type
(define comparator/c
  (-> any/c any/c comparison-result/c))

;; A stronger contract that checks reflexivity
(define (make-reflexive-comparator/c cmp)
  (and/c
   comparator/c
   (λ (f)
     ;; Test reflexivity on a sample
     (for/and ([x (in-list '(0 1 2 3 "a" "b"))])
       (= (f x x) 0)))))

;; -----------------------------------------------------------------------------
;; Comparator Implementations
;; -----------------------------------------------------------------------------

;; Correct numeric comparator
(define (correct-compare a b)
  (cond
    [(< a b) -1]
    [(> a b)  1]
    [else     0]))

;; CHAOS COMPARATOR: Returns random results!
;; Maps random(3) -> {-1, 0, 1}
(define (chaos-compare a b)
  (vector-ref #(-1 0 1) (random 3)))

;; Slightly less chaotic: correct for equal, random otherwise
(define (semi-chaos-compare a b)
  (if (equal? a b)
      0
      (vector-ref #(-1 1) (random 2))))

;; -----------------------------------------------------------------------------
;; Sorting with Comparators
;; -----------------------------------------------------------------------------

;; Insertion sort using a comparator
(define (insertion-sort lst cmp)
  (define (insert x sorted)
    (cond
      [(null? sorted) (list x)]
      [(<= (cmp x (car sorted)) 0)
       (cons x sorted)]
      [else
       (cons (car sorted) (insert x (cdr sorted)))]))
  (foldl insert '() lst))

;; Check if a list is sorted according to a comparator
(define (sorted? lst cmp)
  (or (null? lst)
      (null? (cdr lst))
      (and (<= (cmp (car lst) (cadr lst)) 0)
           (sorted? (cdr lst) cmp))))

;; -----------------------------------------------------------------------------
;; Contracted Sorting
;; -----------------------------------------------------------------------------

;; Sorting with contracts: input list, output must be sorted and same length
(define/contract (safe-sort lst cmp)
  (->i ([l (listof number?)]
        [c comparator/c])
       [result (l c)
               (and/c (listof number?)
                      (λ (r) (= (length r) (length l))))])
  (insertion-sort lst cmp))

;; Even stricter: output must actually be sorted
(define/contract (strict-sort lst cmp)
  (->i ([l (listof number?)]
        [c comparator/c])
       [result (l c)
               (and/c (listof number?)
                      (λ (r) (= (length r) (length l)))
                      (λ (r) (sorted? r correct-compare)))])  ; Check with CORRECT comparator!
  (insertion-sort lst cmp))

;; -----------------------------------------------------------------------------
;; Sum Preservation Check
;; -----------------------------------------------------------------------------

(define (sum lst)
  (apply + lst))

(define/contract (sort-preserves-sum lst cmp)
  (-> (listof number?) comparator/c boolean?)
  (= (sum lst) (sum (insertion-sort lst cmp))))

;; -----------------------------------------------------------------------------
;; Demonstrations
;; -----------------------------------------------------------------------------

(define example-list '(1 3 5 7 6 4 2 0))

(define (demo-header title)
  (printf "\n~a\n~a\n" title (make-string (string-length title) #\=)))

(define (run-demos)
  (demo-header "Chaos Comparator Demo")
  (printf "Example list: ~a\n" example-list)
  (printf "Sum: ~a\n\n" (sum example-list))

  ;; Correct sorting
  (demo-header "1. Correct Comparator")
  (let ([sorted (insertion-sort example-list correct-compare)])
    (printf "Sorted: ~a\n" sorted)
    (printf "Is sorted? ~a\n" (sorted? sorted correct-compare))
    (printf "Sum preserved? ~a (sum=~a)\n"
            (= (sum example-list) (sum sorted))
            (sum sorted)))

  ;; Chaos sorting - run multiple times to see variation
  (demo-header "2. Chaos Comparator (random results!)")
  (printf "Running 5 'sorts' with chaos comparator:\n")
  (for ([i (in-range 5)])
    (let ([result (insertion-sort example-list chaos-compare)])
      (printf "  Run ~a: ~a (sorted? ~a, sum=~a)\n"
              (add1 i)
              result
              (sorted? result correct-compare)
              (sum result))))

  ;; Semi-chaos
  (demo-header "3. Semi-Chaos Comparator (reflexive but not transitive)")
  (for ([i (in-range 3)])
    (let ([result (insertion-sort example-list semi-chaos-compare)])
      (printf "  Run ~a: ~a (sorted? ~a)\n"
              (add1 i)
              result
              (sorted? result correct-compare))))

  ;; Contract violation detection
  (demo-header "4. Contract Detection")
  (printf "Testing if strict-sort catches bad comparator...\n")
  (with-handlers ([exn:fail:contract?
                   (λ (e)
                     (printf "CONTRACT VIOLATION CAUGHT!\n")
                     (printf "  ~a\n" (exn-message e)))])
    ;; This should fail because chaos-compare produces unsorted output
    (let ([result (strict-sort example-list chaos-compare)])
      (printf "  Unexpectedly succeeded: ~a\n" result)))

  ;; Sum is always preserved (even with chaos!)
  (demo-header "5. Sum Preservation (Chaos Can't Break This!)")
  (printf "With correct comparator: sum preserved? ~a\n"
          (sort-preserves-sum example-list correct-compare))
  (printf "With chaos comparator: sum preserved? ~a\n"
          (sort-preserves-sum example-list chaos-compare))
  (printf "\nWhy? Because chaos only reorders - it can't create or destroy elements!\n")

  ;; The key insight
  (demo-header "Key Insight")
  (printf "A comparator contract should enforce:\n")
  (printf "  1. Reflexivity:     cmp(x, x) = 0\n")
  (printf "  2. Anti-symmetry:   cmp(x, y) = -cmp(y, x)\n")
  (printf "  3. Transitivity:    cmp(x,y)<0 & cmp(y,z)<0 => cmp(x,z)<0\n")
  (printf "\nChaos comparator violates ALL of these!\n")
  (printf "Result: 'sorted' output that isn't actually sorted.\n")
  (printf "\nThis is why Veil-style verification matters:\n")
  (printf "  - Contracts catch violations at runtime\n")
  (printf "  - Formal verification proves correctness statically\n"))

;; Run when executed
(module+ main
  (run-demos))
