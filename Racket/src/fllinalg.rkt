#lang racket

(provide main)

(require racket/flonum flmatrix/flmatrix)

(define (rando) (* 1.0 (random 2 256)))

(define (remainder-or-random numerator denominator)
  (match (remainder numerator denominator)
    [0.0  (rando)]
    [rem  rem]))

(define (rem-all-by-256! A)
  (flmatrix-map! A (λ (x) (remainder-or-random x 256))))

(define (rem-all-by-256 A)
  (rem-all-by-256! (copy-flmatrix A)))

;***************************

(define (random-column-vector size)
  (for/flmatrix size 1 ([_ size]) (rando)))

(define (random-row-vector size)
  (for/flmatrix 1 size ([_ size]) (rando)))

(define (random-square-matrix size)
  (for/flmatrix size size 
                ([_ (sqr size)])
                (rando)))

; In flmatrix, vectors are represented as column vectors (that a matrix with only one column).
(define (benchmark-vector iterations size)
  (define v1 (random-column-vector size))
  (define v2 (random-column-vector size))
  (for ([_ (in-range iterations)])
    (define v1+v2 (flmatrix+    v1 v2)) ; note: this allocates a new vector
    (define v1.v2 (flcolumn-dot v1 v2)) ; note: not used in return value
    (rem-all-by-256 v1+v2)
    #;(rem-all-by-256 v1.v2)  ; omitted since v1.v2 being the dot product is a single number
    ))

(define (benchmark-matrixops iterations size)
  (define m1 (random-square-matrix size))
  (define m2 (random-square-matrix size))
  (for ([_ (in-range iterations)])
    (define m1+m2 (flmatrix+ m1 m2)) ; note: this allocates a new matrix
    (define m1*m2 (flmatrix* m1 m2)) ; note: this allocates a new matrix
    (rem-all-by-256 m1+m2)           ; note: not used in return value
    (rem-all-by-256 m1*m2)))


(define (benchmark-mixed iterations size)
  (define c (random-column-vector size))
  (define r (random-row-vector size))
  (define A (random-square-matrix size))
  (for ([_ (in-range iterations)])
    (set! c (rem-all-by-256 (flmatrix* A c)))    ; allocates new matrix
    (set! r (rem-all-by-256 (flmatrix* r A)))    ; allocates new matrix
    (set! A (rem-all-by-256 (flmatrix* c r)))))  ; allocates new matrix

(define (benchmark-mixed! iterations size)
  (define c (random-column-vector size))
  (define r (random-row-vector    size))
  (define A (random-square-matrix size))
  (for ([_ (in-range iterations)])
    (rem-all-by-256! (flmatrix*! A c c))    ; c:=Ac reuse cv
    (rem-all-by-256! (flmatrix*! r A r))    ; r:=Ar reuse rv
    (rem-all-by-256! (flmatrix*! c r A))))  ; A:=cr reuse A

;; ;***************************

(define (main experiment-selection iterations size)
  (set! size       (string->number size))
  (set! iterations (string->number iterations))
  (match (string-downcase (string-trim experiment-selection))
    ["vector" (benchmark-vector    iterations size)]
    ["matrix" (benchmark-matrixops iterations size)]
    ["mixed"  (benchmark-mixed     iterations size)]
    ["mixed!" (benchmark-mixed!    iterations size)])
  (displayln (string-append experiment-selection " completed successfully")))


"vector"
(time (main "vector" "1000" "10"))
(time (main "vector" "1000" "100"))
(time (main "vector" "1000" "1000"))

"matrix"
(time (main "matrix" "1000" "10"))
(time (main "matrix" "100"  "100"))
(time (main "matrix" "10"   "1000"))

"mixed"
(time (main "mixed" "1000" "10"))
(time (main "mixed" "100"  "100"))
(time (main "mixed" "10"   "1000"))

"mixed!"
(time (main "mixed!" "1000" "10"))
(time (main "mixed!" "100"  "100"))
(time (main "mixed!" "10"   "1000"))


