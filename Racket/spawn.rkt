#lang racket/base

#;(provide main)
(require racket/place racket/future)

(define (distribute-extra-iterations total-iterations base)
  (define ret-vec (make-vector base (quotient total-iterations base)))
  (define leftovers (remainder total-iterations base))
  (for ([i (in-range leftovers)])
    (let ([curr-val (vector-ref ret-vec i)])
      (vector-set! ret-vec i (add1 curr-val))))
  ret-vec)

(define (child iteration place-id thread-id)
  #;
  (displayln (string-append "I am child thread " ;
  (number->string id)                   ;
  " of iteration "                      ;
  (number->string iteration)))
  #;(printf "I am child thread ~a of place ~a, during iteration ~a\n" thread-id place-id iteration)
  (void)
  )

(define (child/place iteration id num-threads)
  #;
  (displayln (string-append "I am child " ; ;
  (number->string id)                   ; ;
  " of iteration "                      ; ;
  (number->string iteration)))
  (place/context
   c
   (let ([threads-list (for/list ([i (in-range num-threads)])
                         (thread (λ () (child iteration id i))))])
     (map thread-wait threads-list))))

(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  (define threads-per-place (max 1 (quotient num-threads num-cores)))
  (for ([i (in-range iterations)])
    (let ([places (for/list ([j (in-range num-cores)])
                    (child/place i j threads-per-place))])
      (map place-wait places)))
  #;
  (for ([iteration (in-range iterations)]) ;
  (let ([threads-list                   ;
  (for/list ([i (in-range num-threads)]) ;
  (thread (λ () (child iteration i))))]) ;
  (for ([i (in-list threads-list)])     ;
  (thread-wait i))))
  )

#;(define (main iterations num-threads)
  (experiment (string->number iterations) (string->number num-threads))
(displayln "Spawn completed successfully"))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (vector-ref cmd-params 0))
  (define num-threads (vector-ref cmd-params 1))
  (experiment (string->number iterations) (string->number num-threads))
  (displayln "Spawn completed successfully"))
