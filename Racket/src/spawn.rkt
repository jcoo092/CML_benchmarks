#lang racket/base

(require racket/place racket/future)

(define (distribute-extras total base)
  (define ret-vec (make-vector base (quotient total base)))
  (define leftovers (remainder total base))
  (for ([i (in-range leftovers)])
    (let ([curr-val (vector-ref ret-vec i)])
      (vector-set! ret-vec i (add1 curr-val))))
  ret-vec)

(define (child iteration place-id thread-id)
  #;(printf "I am child thread ~a of place ~a, during iteration ~a\n" thread-id place-id iteration)
  (void))

(define (child/place iterations id num-threads)
  (place/context
   c
   (for ([i (in-range iterations)])
       (let ([threads-list (for/list ([t (in-range num-threads)])
                             (thread (λ () (child i id t))))])
         (for-each thread-wait threads-list)))))

(define (experiment iterations num-cores num-threads)
  #;(define num-cores (processor-count))
  (define threads-per-place (distribute-extras num-threads num-cores))
  (let ([places (for/list ([i (in-range num-cores)]
                           [j (in-vector threads-per-place)])
                  (child/place iterations i j))])
    (for-each place-wait places)))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (define num-threads (string->number (vector-ref cmd-params 1)))
  (define num-cores (min num-threads (processor-count)))
  (experiment iterations num-cores num-threads)
  (displayln "Spawn completed successfully"))
