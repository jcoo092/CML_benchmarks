#lang racket

(provide main)
(require racket/random)

(define (sender iterations channels)
 (match iterations
  [0 (displayln "sender completed")]
  [iter (
      (let ([choice-chan (random-ref channels)])
       (channel-put choice-chan 'message)
  (sender (- iter 1) channels)))]
 ))

(define (receiver iterations channels notification-semaphore)
 (match iterations
 [0 ((displayln "receiver completed")
     (semaphore-post notification-semaphore))]
 [iter
  ((let ([ignored-choice (sync (choice-evt (vector->values channels)))])
      (displayln ignored-choice)
      (receiver (- iter 1) channels notification-semaphore)))]))

(define (experiment iterations num-channels)
 (let ([channels
        (vector->immutable-vector
         (make-vector num-channels (make-channel)))]
       [notification-semaphore (make-semaphore)])
  (thread (λ () (receiver iterations channels notification-semaphore)))
  (thread (λ () (sender iterations channels)))
  (semaphore-wait notification-semaphore)
 ))

(define (main iterations num-channels)
  (experiment (string->number iterations) (string->number num-channels))
  (displayln "SelectTime completed successfully"))