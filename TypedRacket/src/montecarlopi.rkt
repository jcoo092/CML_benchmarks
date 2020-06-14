#lang typed/racket/base

(require racket/match racket/fixnum racket/flonum)
(require racket/place racket/future)
(require racket/unsafe/ops)


(: distribute-extras (-> Nonnegative-Fixnum Nonnegative-Fixnum FxVector))
(define (distribute-extras total base)
  (define ret-vec (make-fxvector base (fxquotient total base)))
  (define leftovers (fxremainder total base))
  (for ([i (in-range leftovers)])
    (let ([curr-val (fxvector-ref ret-vec i)])
      (fxvector-set! ret-vec i (fx+ 1 curr-val))))
  ret-vec)

(: montecarlopi/place (-> Nonnegative-Fixnum Nonnegative-Fixnum Place-Channel Place))
(define (montecarlopi/place iterations num-threads return-chan)
  (place/context
   c
   (begin
     (define (run-thread-in-place randomiser thread-iterations)
       (define (helper accumulator iteration)
         (match iteration
           [0 accumulator]
           [iter (let ([x (random randomiser)] [y (random randomiser)]
                       [next-iter (fx- iter 1)])
                   (let ([in-circle (fl+ (fl* x x) (fl* y y))])
                     (if (fl< in-circle 1.0)
                         (helper (fx+ accumulator 1) next-iter)
                         (helper accumulator next-iter))))]))
       (place-channel-put return-chan (helper 0 thread-iterations)))
     (map sync (for/list ([i (distribute-extras iterations num-threads)])
                 (thread (λ () (run-thread-in-place (make-pseudo-random-generator) i))))))))

(: experiment (-> Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (experiment iterations num-threads)
  (define num-cores (cast (processor-count) Nonnegative-Fixnum))
  (define threads-per-place-vec (assert (distribute-extras num-threads num-cores) fxvector?))
  (define iters-per-place-vec (assert (distribute-extras iterations num-cores) fxvector?))
  (define-values (rx-ch tx-ch) (place-channel))

  (: collect-from-chan (-> Nonnegative-Fixnum Nonnegative-Fixnum Nonnegative-Fixnum))
  (define (collect-from-chan count sum)
    (if (< count 1)
        sum
        (collect-from-chan (sub1 count)
                           (fx+ sum (cast (place-channel-get rx-ch) Nonnegative-Fixnum)))))
  (for ([ts (in-fxvector threads-per-place-vec)]
        [is (in-fxvector iters-per-place-vec)])
    (montecarlopi/place is ts tx-ch))

  (displayln (fl* 4.0 (fl/ ;
                              (->fl (collect-from-chan num-threads 0)) ;
                              (->fl iterations))))
  (displayln "Monte Carlo Pi completed successfully"))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (define num-threads (string->number (vector-ref cmd-params 1)))
  (experiment iterations num-threads))
