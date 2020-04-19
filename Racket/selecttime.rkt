#lang racket

(provide main)
(require racket/random)

(define (sender iterations channels)
  (let ([choice-chan (random-ref channels)])
    (match iterations
      [0
       (begin (channel-put choice-chan 'NONE)
              (displayln "Sender completed."))]
      [iter
       (channel-put choice-chan iter)
       (sender (- iter 1) channels)])))

(define (receiver channels notification-semaphore)
  (define (receive-and-process message)
    (match message
      ['NONE (begin
               (semaphore-post notification-semaphore)
               (displayln "Receiver completed"))]
      [Some (begin
              (receive-and-process (apply sync channels)))]))

  (receive-and-process (apply sync channels)))

(define (experiment iterations num-channels)
  (let ([channels
         (build-list num-channels (λ (i) (make-channel)))]
        [notification-semaphore (make-semaphore)])
    (thread (λ () (receiver channels notification-semaphore)))
    (thread (λ () (sender iterations channels)))
    (semaphore-wait notification-semaphore)))

(define (main iterations num-channels)
  (experiment (string->number iterations) (string->number num-channels))
  (displayln "SelectTime completed successfully"))