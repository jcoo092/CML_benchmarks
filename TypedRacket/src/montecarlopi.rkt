#lang typed/racket/base

(require racket/fixnum racket/flonum)
(require racket/place racket/future)


(: distribute-extras (-> Nonnegative-Fixnum Nonnegative-Fixnum (Vectorof Nonnegative-Fixnum)))
(define (distribute-extras total base)
  (: ret-vec (Vectorof Nonnegative-Fixnum))
  (define ret-vec (make-vector base (quotient total base)))
  (define leftovers (remainder total base))
  (for ([i (in-range leftovers)])
    (let ([curr-val (vector-ref ret-vec i)])
      (vector-set! ret-vec i (fx+ 1 curr-val))))
  ret-vec)

(: montecarlopi/place (-> Nonnegative-Fixnum Nonnegative-Fixnum Place-Channel Place))
(define (montecarlopi/place iterations num-threads return-chan)
  (place/context
   c
   (begin
     (define (run-thread-in-place randomiser thread-iterations)
       (define (helper accumulator iteration)
	 (if (zero? iteration)
	     accumulator
	     (let ([x (random randomiser)] [y (random randomiser)]
                       [next-iter (fx- iteration 1)])
                   (let ([in-circle (fl+ (fl* x x) (fl* y y))])
                     (if (fl< in-circle 1.0)
                         (helper (fx+ accumulator 1) next-iter)
                         (helper accumulator next-iter))))))
       (place-channel-put return-chan (helper 0 thread-iterations)))
     (for-each sync (for/list ([i (distribute-extras iterations num-threads)])
                 (thread (λ () (run-thread-in-place (make-pseudo-random-generator) i))))))))

(: experiment (-> Nonnegative-Fixnum Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (experiment iterations num-cores num-threads)
  (define threads-per-place-vec (distribute-extras num-threads num-cores))
  (define iters-per-place-vec (assert (distribute-extras iterations num-cores) vector?))
  (define-values (rx-ch tx-ch) (place-channel))

  (: collect-from-chan (-> Nonnegative-Fixnum Nonnegative-Fixnum Nonnegative-Fixnum))
  (define (collect-from-chan count sum)
    (if (< count 1)
        sum
        (collect-from-chan (sub1 count)
                           (fx+ sum (cast (place-channel-get rx-ch) Nonnegative-Fixnum)))))
  (for ([ts (in-vector threads-per-place-vec)]
        [is (in-vector iters-per-place-vec)])
    (montecarlopi/place is ts tx-ch))

  (displayln (fl* 4.0 (fl/ ;
                              (->fl (collect-from-chan num-threads 0)) ;
                              (->fl iterations))))
  (displayln "Monte Carlo Pi completed successfully"))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (cast (string->number (vector-ref cmd-params 0)) Nonnegative-Fixnum))
  (define num-threads (cast (string->number (vector-ref cmd-params 1)) Nonnegative-Fixnum))
  (define num-cores (min num-threads (cast (processor-count) Nonnegative-Fixnum)))
  (experiment iterations num-cores num-threads))
