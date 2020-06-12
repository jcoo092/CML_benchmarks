#lang racket/base

(require racket/match)
(require racket/flonum racket/unsafe/ops)
(require racket/place racket/future)

(define (distribute-extras total base)
  (define ret-vec (make-vector base (quotient total base)))
  (define leftovers (remainder total base))
  (for ([i (in-range leftovers)])
    (let ([curr-val (vector-ref ret-vec i)])
      (vector-set! ret-vec i (add1 curr-val))))
  ret-vec)

(define (montecarlopi/place iterations num-threads return-chan)
  (place/context
   c
   (begin
     (define (run-thread-in-place randomiser thread-iterations)
       (define (helper accumulator iteration)
         (match iteration
           [0 accumulator]
           [iter (let ([x (random randomiser)] [y (random randomiser)]
                       [next-iter (unsafe-fx- iter 1)])
                   (let ([in-circle (unsafe-fl+ (unsafe-fl* x x) (unsafe-fl* y y))])
                     (if (unsafe-fl< in-circle 1.0)
                         (helper (unsafe-fx+ accumulator 1) next-iter)
                         (helper accumulator next-iter))))]))
       (place-channel-put return-chan (helper 0 thread-iterations)))
     (map sync (for/list ([i (distribute-extras iterations num-threads)])
                 (thread (λ () (run-thread-in-place (make-pseudo-random-generator) i))))))))

(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  (define threads-per-place-vec (distribute-extras num-threads num-cores))
  (define iters-per-place-vec (distribute-extras iterations num-cores))
  (define-values (rx-ch tx-ch) (place-channel))
  (define (collect-from-chan count sum)
    (if (< count 1)
        sum
        (collect-from-chan (sub1 count)
                           (unsafe-fx+ sum (place-channel-get rx-ch)))))
  (for ([ts (in-vector threads-per-place-vec)]
        [is (in-vector iters-per-place-vec)])
    (montecarlopi/place is ts tx-ch))

  (displayln (unsafe-fl* 4.0 (unsafe-fl/ ;
                              (->fl (collect-from-chan num-threads 0)) ;
                              (->fl iterations))))
  (displayln "Monte Carlo Pi completed successfully"))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (define num-threads (string->number (vector-ref cmd-params 1)))
  (experiment iterations num-threads))