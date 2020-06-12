#lang racket

(require math/matrix math/array)

(define max-val 256)

(define (rando) (random 2 max-val))

(define (remainder-or-random numerator)
  (define rem (remainder numerator max-val))
  (if (zero? rem)
      (rando)
      rem))

(define (rem-all-by-256 vec)
  (array-map (λ (m) (remainder-or-random m)) vec))

;***************************

; Racket's Math library doesn't seem to make any distinction between vectors and matrices
; Vectors are just matrices where one of the dimensions has size 1
(define (vector iterations size)
  (define initvector1 (build-matrix 1 size (λ (a b) (rando))))
  (define initvector2 (build-matrix 1 size (λ (a b) (rando))))
  (define (process-vectors iteration v1 v2)
    (if (zero? iteration)
        (void)
        (let ([pluses (matrix+ v1 v2)]
              [times (matrix-row (matrix* (matrix-transpose v1) v2) 0)])
          (process-vectors (sub1 iteration) (rem-all-by-256 pluses) (rem-all-by-256 times)))))
  (process-vectors iterations initvector1 initvector2))

;***************************

(define (matrixops iterations size)
  (define initmatrix1 (build-matrix size size (λ (a b) (rando))))
  (define initmatrix2 (build-matrix size size (λ (a b) (rando))))
  (define (process-matrices iteration m1 m2)
    (if (zero? iteration)
        (void)
        (let ([pluses (matrix+ m1 m2)]
              [times (matrix* m1 m2)])
          (process-matrices (sub1 iteration) (rem-all-by-256 times) (rem-all-by-256 pluses)))))
  (process-matrices iterations initmatrix1 initmatrix2))

;***************************

; This test should check both row and column vector multiplication against square matrices

(define (mixed iterations size)
  (define initcolvec (build-matrix size 1 (λ (a b) (rando))))
  (define initrowvec (build-matrix 1 size (λ (a b) (rando))))
  (define initmatrix1 (build-matrix size size (λ (a b) (rando))))
  (define (process-mixed iteration colvec rowvec m)
    (if (zero? iteration)
        (void)
        (let* ([next-iter (sub1 iteration)]
               [next-colvec (rem-all-by-256 (matrix* m colvec))]
               [next-rowvec (rem-all-by-256 (matrix* rowvec m))]
               [next-matrix (rem-all-by-256 (matrix* next-colvec next-rowvec))])
          (process-mixed next-iter next-colvec next-rowvec next-matrix))))
  (process-mixed iterations initcolvec initrowvec initmatrix1))

;***************************

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define experiment-selection (vector-ref cmd-params 0))
  (define iter-num (string->number (vector-ref cmd-params 1)))
  (define size-num (string->number (vector-ref cmd-params 2)))
  (case (string-downcase (string-trim experiment-selection))
    [("vector") (vector iter-num size-num)]
    [("matrix") (matrixops iter-num size-num)]
    [("mixed") (mixed iter-num size-num)])
  (displayln (string-append experiment-selection " completed successfully!")))
