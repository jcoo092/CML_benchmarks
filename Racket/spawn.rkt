#lang racket

(provide main)

(define (child iteration id)
  (displayln (string-append "I am child "
                            (number->string id)
                            " of iteration "
                            (number->string iteration))))

(define (experiment iterations num-threads)
  (for ([iteration (in-range iterations)])
    (let ([threads-list
           (for/list ([i (in-range num-threads)])
             (thread (λ () (child iteration i))))])
      (for ([i (in-list threads-list)])
        (thread-wait i)))))

(define (main iterations num-threads)
  (experiment (string->number iterations) (string->number num-threads))
  (displayln "Spawn completed successfully"))