#lang racket

(provide main)

(define (ring size notification-semaphore)
  (define (receive-and-fwd in out)
    (channel-put out (begin (displayln "hi!") (channel-get in))))
  (define channels
    (build-vector size (λ (i) (make-channel))))
  ; Start off the final thread manually, since it needs to wrap around to the end of
  ; the vector for its out channel
  (thread (λ () (receive-and-fwd (vector-ref channels (sub1 size)) (vector-ref channels 0))))
  (for ([i (in-range (sub1 size))])
    (thread (λ () (receive-and-fwd (vector-ref channels i) (vector-ref channels (add1 i))))))
  (channel-put (vector-ref channels 0) 'go)
  (channel-get (vector-ref channels 0))
  (semaphore-post notification-semaphore))

(define (main experiment-selection size)
  ;(experiment (string->number size))
  (define notification-semaphore (make-semaphore))
  (ring (string->number size) notification-semaphore)
  (semaphore-wait notification-semaphore)
  (displayln (string-append experiment-selection " of Whispers completed successfully")))