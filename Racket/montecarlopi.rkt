#lang racket/base

(require racket/match)
(require racket/flonum racket/unsafe/ops)
(require racket/place racket/future)

(define (montecarlopi/place iterations num-threads return-chan)
  (place/context
   c  
   (begin
     (define (run-thread-in-place randomiser)
       (define (helper accumulator iteration)
         (match iteration
           [0 accumulator]
           [iter (let ([x (random randomiser)] [y (random randomiser)] [next-iter (unsafe-fx- iter 1)])
                   (let ([in-circle (unsafe-fl+ (unsafe-fl* x x) (unsafe-fl* y y))])
                     (if (unsafe-fl< in-circle 1.0)
                         (helper (unsafe-fx+ accumulator 1) next-iter)
                         (helper accumulator next-iter))))]))
       (place-channel-put return-chan (helper 0 iterations)))
     (map sync (for/list ([i (in-range num-threads)])
                 (thread (λ () (run-thread-in-place (make-pseudo-random-generator)))))))))

(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  (define threads-add (remainder num-threads num-cores))
  (define-values (rx-ch tx-ch) (place-channel))
  (define (collect-from-chan count sum)
    (if (< count 1)
        sum
        (collect-from-chan (unsafe-fx- count 1) (unsafe-fx+ sum (place-channel-get rx-ch)))))
  (for ([i (in-range num-cores)])
    (montecarlopi/place (/ iterations num-threads) (/ (+ num-threads threads-add) num-cores) tx-ch))
  (displayln (unsafe-fl* 4.0 (unsafe-fl/ (->fl (collect-from-chan  (+ num-threads threads-add) 0)) (->fl iterations)))))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (define num-threads (string->number (vector-ref cmd-params 1)))
  (experiment iterations num-threads)
  (displayln "Monte Carlo Pi completed successfully"))
