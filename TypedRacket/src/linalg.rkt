#lang typed/racket

(require math/matrix math/array)

                                        ;*************************** Common ***************************

(define max-val 256)

(: rando (-> Nonnegative-Fixnum))
(define (rando) (random 2 max-val))

(: remainder-or-random (-> Nonnegative-Fixnum Nonnegative-Fixnum))
(define (remainder-or-random numerator)
  (define rem (remainder numerator max-val))
  (if (zero? rem)
      (rando)
      rem))

(: rem-all-by-256 (-> (Array Nonnegative-Fixnum) (Array Nonnegative-Fixnum)))
(define (rem-all-by-256 vec)
  (array-map (λ (m) (remainder-or-random m)) vec))

                                        ;*************************** Vector ***************************

                                        ; Racket's Math library doesn't seem to make any distinction between vectors and matrices
                                        ; Vectors are just matrices where one of the dimensions has size 1
(: vector (-> Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (vector iterations size)

  (: initvector1 (Matrix Nonnegative-Fixnum))
  (define initvector1 (build-matrix 1 size (λ (a b) (rando))))
  (: initvector2 (Matrix Nonnegative-Fixnum))
  (define initvector2 (build-matrix 1 size (λ (a b) (rando))))

  (: process-vectors (-> Nonnegative-Fixnum (Matrix Nonnegative-Fixnum) (Matrix Nonnegative-Fixnum) Void))
  (define (process-vectors iteration v1 v2)
    (if (zero? iteration)
        (void)
        (let ([pluses (cast (matrix+ v1 v2) (Matrix Nonnegative-Fixnum))]
              [times (cast (matrix-row (matrix* (matrix-transpose v1) v2) 0) (Matrix Nonnegative-Fixnum))])
          (process-vectors (sub1 iteration) (rem-all-by-256 pluses) (rem-all-by-256 times)))))
  (process-vectors iterations initvector1 initvector2))

                                        ;*************************** Matrix ***************************

(: matrixops (-> Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (matrixops iterations size)
  (define initmatrix1 (build-matrix size size (λ (a b) (rando))))
  (define initmatrix2 (build-matrix size size (λ (a b) (rando))))

  (: process-matrices (-> Nonnegative-Fixnum (Matrix Nonnegative-Fixnum) (Matrix Nonnegative-Fixnum) Void))
  (define (process-matrices iteration m1 m2)
    (if (zero? iteration)
        (void)
        (let ([pluses (cast (matrix+ m1 m2) (Matrix Nonnegative-Fixnum))]
              [times (cast (matrix* m1 m2) (Matrix Nonnegative-Fixnum))])
          (process-matrices (sub1 iteration) (rem-all-by-256 times) (rem-all-by-256 pluses)))))
  (process-matrices iterations initmatrix1 initmatrix2))

                                        ;*************************** Mixed ***************************

                                        ; This test should check both row and column vector multiplication against square matrices

(: mixed (-> Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (mixed iterations size)
  (define initcolvec (build-matrix size 1 (λ (a b) (rando))))
  (define initrowvec (build-matrix 1 size (λ (a b) (rando))))
  (define initmatrix1 (build-matrix size size (λ (a b) (rando))))

  (: process-mixed (-> Nonnegative-Fixnum (Matrix Nonnegative-Fixnum) (Matrix Nonnegative-Fixnum) (Matrix Nonnegative-Fixnum) Void))
  (define (process-mixed iteration colvec rowvec m)
    (if (zero? iteration)
        (void)
        (let* ([next-iter (sub1 iteration)]
               [next-colvec (rem-all-by-256 (cast (matrix* m colvec) (Matrix Nonnegative-Fixnum)))]
               [next-rowvec (rem-all-by-256 (cast (matrix* rowvec m) (Matrix Nonnegative-Fixnum)))]
               [next-matrix (rem-all-by-256 (cast (matrix* next-colvec next-rowvec) (Matrix Nonnegative-Fixnum)))])
          (process-mixed next-iter next-colvec next-rowvec next-matrix))))
  (process-mixed iterations initcolvec initrowvec initmatrix1))

                                        ;***************************

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define experiment-selection (vector-ref cmd-params 0))
  (define iter-num (cast (string->number (vector-ref cmd-params 1)) Nonnegative-Fixnum))
  (define size-num (cast (string->number (vector-ref cmd-params 2)) Nonnegative-Fixnum))
  (case (string-downcase (string-trim experiment-selection))
    [("vector") (vector iter-num size-num)]
    [("matrix") (matrixops iter-num size-num)]
    [("mixed") (mixed iter-num size-num)])
  (displayln (string-append experiment-selection " completed successfully!")))
