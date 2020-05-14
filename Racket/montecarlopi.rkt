#lang racket/base

(require racket/match)
(require racket/flonum racket/unsafe/ops)
(require racket/place racket/future)

(define (distribute-extra-iterations total-iterations base)
  (define ret-vec (make-vector base (quotient total-iterations base)))
  (define leftovers (remainder total-iterations base))
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
           [iter (let ([x (random randomiser)] [y (random randomiser)] [next-iter (unsafe-fx- iter 1)])
                   (let ([in-circle (unsafe-fl+ (unsafe-fl* x x) (unsafe-fl* y y))])
                     (if (unsafe-fl< in-circle 1.0)
                         (helper (unsafe-fx+ accumulator 1) next-iter)
                         (helper accumulator next-iter))))]))
       (place-channel-put return-chan (helper 0 thread-iterations)))
     (map sync (for/list ([i (distribute-extra-iterations iterations num-threads)])
                 (thread (λ () (run-thread-in-place (make-pseudo-random-generator) i))))))))

(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  #;(define threads-add (remainder num-threads num-cores))
  (define threads-per-place (max 1 (quotient num-threads num-cores)))
  (define-values (rx-ch tx-ch) (place-channel))
  (define (collect-from-chan count sum)
    (if (< count 1)
        sum
        (collect-from-chan (unsafe-fx- count 1) (unsafe-fx+ sum (place-channel-get rx-ch)))))
  (for ([i (distribute-extra-iterations iterations num-cores)])
    (montecarlopi/place i threads-per-place tx-ch))
  (displayln (unsafe-fl* 4.0 (unsafe-fl/ (->fl (collect-from-chan (* threads-per-place num-cores) 0)) (->fl iterations)))))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (define num-threads (string->number (vector-ref cmd-params 1)))
  (experiment iterations num-threads)
  (displayln "Monte Carlo Pi completed successfully"))
