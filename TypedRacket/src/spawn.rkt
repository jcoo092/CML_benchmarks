#lang typed/racket/base

(require racket/place racket/future)

(: child (-> Nonnegative-Fixnum Integer Integer Void))
(define (child iteration place-id thread-id)
  #;(printf "I am child thread ~a of place ~a, during iteration ~a\n" thread-id place-id iteration)
  (void))

;(: child/place (-> Integer Integer Nonnegative-Fixnum Place))
#;(define (child/place iteration id num-threads)
  (place/context
   c
   (let ([threads-list (for/list ([i (in-range num-threads)])
                         (thread (λ () (child iteration id i))))])
     (map thread-wait threads-list))))

;(: experiment (-> Nonnegative-Fixnum Nonnegative-Fixnum Void))
#;(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  (define threads-per-place (max 1 (quotient num-threads num-cores)))
  (for ([i : Integer (in-range iterations)])
    (let ([places : (Listof Place) (for/list ([j : Integer (in-range num-cores)])
                    (child/place i j threads-per-place))])
(map place-wait places))))

(: child/place (-> Integer Integer Nonnegative-Fixnum Place))
(define (child/place iterations id num-threads)
  (place/context
   c
   (for ([i (in-range iterations)])
       (let ([threads-list (for/list ([t (in-range num-threads)])
                             (thread (λ () (child i id t))))])
         (for-each thread-wait threads-list)))))

(: experiment (-> Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (experiment iterations num-threads)
  (define num-cores (processor-count))
  (define threads-per-place (max 1 (quotient num-threads num-cores)))
  (let ([places : (Listof Place) (for/list ([j : Integer (in-range num-cores)])
                                   (child/place iterations j threads-per-place))])
    (for-each place-wait places)))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (cast (string->number (vector-ref cmd-params 0)) Nonnegative-Fixnum))
  (define num-threads (cast (string->number (vector-ref cmd-params 1)) Nonnegative-Fixnum))
  (experiment iterations num-threads)
  (displayln "Spawn completed successfully"))
