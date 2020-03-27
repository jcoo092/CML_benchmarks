#lang racket

(provide main)
(require racket/flonum)

(define (montecarlopi randomiser iterations return-chan)
  (define (helper accumulator iteration)
    (match iteration
      [0 accumulator]
      [iter (let ([x (random randomiser)] [y (random randomiser)] [next-iter (- iter 1)])
              (let ([in-circle (fl+ (fl* x x) (fl* y y))])
                (if (fl< in-circle 1.0)
                    (helper (+ accumulator 1) next-iter)
                    (helper accumulator next-iter))))]))
  (channel-put return-chan (helper 0 iterations)))

(define (experiment iterations num-threads)
  (define ch (make-channel))
  (define (collect-from-chan count sum)
    (if (< count 1)
        sum
        (collect-from-chan (- count 1) (+ sum (channel-get ch)))))
  (for ([i (in-range num-threads)])
    (thread (λ () (montecarlopi (make-pseudo-random-generator) (/ iterations num-threads) ch))))
  (display (fl* 4.0 (fl/ (->fl (collect-from-chan num-threads 0)) (->fl iterations))))
  (newline))

(define (main iterations num-threads)
  (experiment (string->number iterations) (string->number num-threads)))