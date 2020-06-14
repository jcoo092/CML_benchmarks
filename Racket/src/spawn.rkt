#lang racket/base

(require racket/place racket/future)

(define (child iteration place-id thread-id)
  #;(printf "I am child thread ~a of place ~a, during iteration ~a\n" thread-id place-id iteration)
  (void))

#;(define (child/place iteration id num-threads)
  (place/context
   c
   (let ([threads-list (for/list ([i (in-range num-threads)])
                         (thread (λ () (child iteration id i))))])
     (map thread-wait threads-list))))

#;(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  (define threads-per-place (max 1 (quotient num-threads num-cores)))
  (for ([i (in-range iterations)])
    (let ([places (for/list ([j (in-range num-cores)])
                    (child/place i j threads-per-place))])
      (map place-wait places))))

(define (child/place iterations id num-threads)
  (place/context
   c
   (for ([i (in-range iterations)])
       (let ([threads-list (for/list ([t (in-range num-threads)])
                             (thread (λ () (child i id t))))])
         (map thread-wait threads-list)))))

(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  (define threads-per-place (max 1 (quotient num-threads num-cores)))
  (let ([places (for/list ([j (in-range num-cores)])
                  (child/place iterations j threads-per-place))])
    (map place-wait places)))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (vector-ref cmd-params 0))
  (define num-threads (vector-ref cmd-params 1))
  (experiment (string->number iterations) (string->number num-threads))
  (displayln "Spawn completed successfully"))
