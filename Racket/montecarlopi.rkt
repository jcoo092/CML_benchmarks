#lang racket

(provide main)
(require racket/flonum)
(require racket/unsafe/ops)

(define (montecarlopi randomiser iterations return-chan)
  (define (helper accumulator iteration)
    (match iteration
      [0 accumulator]
      [iter (let ([x (random randomiser)] [y (random randomiser)] [next-iter (unsafe-fx- iter 1)])
              (let ([in-circle (unsafe-fl+ (unsafe-fl* x x) (unsafe-fl* y y))])
                (if (unsafe-fl< in-circle 1.0)
                    (helper (unsafe-fx+ accumulator 1) next-iter)
                    (helper accumulator next-iter))))]))
  (channel-put return-chan (helper 0 iterations)))

(define (experiment iterations num-threads)
  (define ch (make-channel))
  (define (collect-from-chan count sum)
    (if (< count 1)
        sum
        (collect-from-chan (unsafe-fx- count 1) (unsafe-fx+ sum (channel-get ch)))))
  (for ([i (in-range num-threads)])
    (thread (λ () (montecarlopi (make-pseudo-random-generator) (/ iterations num-threads) ch))))
  (display (unsafe-fl* 4.0 (unsafe-fl/ (->fl (collect-from-chan num-threads 0)) (->fl iterations))))
  (newline))

(define (main iterations num-threads)
  (experiment (string->number iterations) (string->number num-threads))
  (displayln "Monte Carlo Pi completed successfully"))
