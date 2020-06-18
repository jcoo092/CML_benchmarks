#lang typed/racket/base

(require racket/place racket/future racket/fixnum)

(: distribute-extras (-> Nonnegative-Fixnum Nonnegative-Fixnum (Vectorof Nonnegative-Fixnum)))
(define (distribute-extras total-threads base)
  (: ret-vec (Vectorof Nonnegative-Fixnum))
  (define ret-vec (make-vector base (quotient total-threads base)))
  (define leftovers (remainder total-threads base))
  (for ([i (in-range leftovers)])
    (let ([curr-val (vector-ref ret-vec i)])
      (vector-set! ret-vec i (fx+ 1 curr-val))))
  ret-vec)

(: child (-> Nonnegative-Fixnum Integer Integer Void))
(define (child iteration place-id thread-id)
  #;(printf "I am child thread ~a of place ~a, during iteration ~a\n" thread-id place-id iteration)
  (void))

(: child/place (-> Integer Integer Integer Place))
(define (child/place iterations id num-threads)
  (place/context
   c
   (for ([i (in-range iterations)])
       (let ([threads-list (for/list ([t (in-range num-threads)])
                             (thread (λ () (child i id t))))])
         (for-each thread-wait threads-list)))))

(: experiment (-> Nonnegative-Fixnum Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (experiment iterations num-cores num-threads)
  #;(define num-cores (processor-count))
  #;(define threads-per-place (max 1 (quotient num-threads num-cores)))
  (define threads-per-place (distribute-extras num-threads num-cores))
  (let ([places : (Listof Place) (for/list ([i : Integer (in-range num-cores)]
                                            [j : Integer (in-vector threads-per-place)])
                                   (child/place iterations i j))])
    (for-each place-wait places)))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (cast (string->number (vector-ref cmd-params 0)) Nonnegative-Fixnum))
  (define num-threads (cast (string->number (vector-ref cmd-params 1)) Nonnegative-Fixnum))
  (define num-cores (fxmin num-threads (cast (processor-count) Nonnegative-Fixnum)))
  (experiment iterations num-cores num-threads)
  (displayln "Spawn completed successfully"))
