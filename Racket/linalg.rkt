#lang racket

(provide main)
(require math/matrix math/array)

(define (remainder-or-random numerator denominator)
 (define rem (remainder numerator denominator))
 (if (zero? rem)
  (random 2 256)
  rem))

(define (div-all-by-min-int vec)
 (let* ([min-in-arr (array-all-min vec)]
        [min-val (if (zero? min-in-arr) (random 2 256) min-in-arr)])
  ;(printf "ex-vec is: ~v\n" ex-vec)
  (printf "min is: ~a\n" min-val)
  (array-map (λ (m) (remainder-or-random m min-val)) vec)))

;***************************

; Racket's Math library doesn't seem to make any distinction between vectors and matrices
; Vectors are just 1D matrices
(define (vector iterations size)
 (define initvector1 (build-matrix 1 size (λ (a b) (random 2 256))))
 (define initvector2 (build-matrix 1 size (λ (a b) (random 2 256))))
 (define (process-vectors iteration v1 v2)
  (printf "v1: ~v\n" v1)
  (printf "v2: ~v\n" v2)
  (if (zero? iteration)
   (void)
   (let ([pluses (matrix+ v1 v2)]
         [times (matrix-row (matrix* (matrix-transpose v1) v2) 0)])
    (process-vectors (sub1 iteration) (div-all-by-min-int pluses) (div-all-by-min-int times)))))
  (process-vectors iterations initvector1 initvector2))

;***************************

(define (matrixops iterations size)
 (displayln "unimplemented"))

;***************************

(define (mixed iterations size)
 (displayln "unimplemented"))

;***************************

(define (main experiment-selection iterations size)
    (let ([size-num (string->number size)]
           [iter-num (string->number iterations)])
        (match (string-downcase (string-trim experiment-selection))
        ["vector" (vector iter-num size-num)]
        ["matrix" (matrixops iter-num size-num)]
        ["mixed" (mixed iter-num size-num)]))
  (displayln (string-append experiment-selection " completed successfully")))