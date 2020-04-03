#lang racket

(provide main)
(require racket/vector)

(define (chans size)
    (build-vector size (λ (i) (make-channel))))

(define (ring size notification-semaphore)
  (define channels (chans size))
  (define (vrc idx) (vector-ref channels idx))
  (define vrc0 (vrc 0))
  (define (receive-and-fwd in out)
    (channel-put out (channel-get in)))
  ; Start off the final thread manually, since it needs to wrap around to the end of
  ; the vector for its out channel
  (thread (λ () (receive-and-fwd (vrc (sub1 size)) vrc0)))
  (for ([i (in-range (sub1 size))])
    (thread (λ () (receive-and-fwd (vrc i) (vrc (add1 i))))))
  (channel-put vrc0 'go)
  (channel-get vrc0)
  (semaphore-post notification-semaphore))

(define (kn size notification-semaphore)
 (define channels (chans size))
 (define (receive-and-fwd in out)
    (channel-put out (begin (displayln "hi!") (channel-get in))))
 (for ([i (in-range size)])
  (let ([events (vector-map (λ (c) (channel-put-evt c i)) channels)])
   (vector-set! events i (channel-get (vector-ref channels i)))

   ))
 (displayln "unimplemented")
 )

(define (grid size notification-semaphore)
 (define channels (chans size))
 (define (receive-and-fwd in out)
    (channel-put out (begin (displayln "hi!") (channel-get in))))
 (displayln "unimplemented")
 )

(define (main experiment-selection size)
  ;(experiment (string->number size))
  ;(define notification-semaphore (make-semaphore))
  ;(define size-num (string->number size))
  (let ([notification-semaphore (make-semaphore)]
        [size-num (string->number size)])
  (match (string-downcase (string-trim experiment-selection))
   ["ring" (ring size-num notification-semaphore)]
   ["kn" (kn size-num notification-semaphore)]
   ["grid" (grid size-num notification-semaphore)])
  (semaphore-wait notification-semaphore))
  (displayln (string-append experiment-selection " of Whispers completed successfully")))