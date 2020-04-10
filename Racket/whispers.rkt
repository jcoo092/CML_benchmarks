#lang racket

(provide main)

(define (chans size)
  (build-list size (λ (i) (make-channel))))

; TODO:  Modify ring to work on a list rather than a vector
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

(define (communicate ch count comms-events)
  (let ([zc (zero? count)] [nc (null? comms-events)])
    (cond
      [(and zc nc) (void)]
      [zc (let ([result (apply sync comms-events)])
            (communicate ch count (remq result comms-events)))]
      [nc (begin (sync ch)
                 (communicate ch (sub1 count) comms-events))]
      [else (let* ([evs (list* ch comms-events)]
                   [result (apply sync evs)])
              (if (channel-put-evt? result)
                  (communicate ch count (remq result comms-events))
                  (communicate ch (sub1 count) comms-events)))])))

(define (kn size)
  (define channels (chans size))
  (define threads
    (for/list ([i (in-range size)])
      (let* ([events (map (λ (c) (channel-put-evt c i)) channels)]
             [events2 (flatten (list* (take events i) (drop events (add1 i))))])
        (thread (λ () (communicate (list-ref channels i) (sub1 size)
                                   events2))))))
  (displayln "started kn")
  (for-each thread-wait threads))

; TODO:  Implement grid (which will probably largely be a copy of kn)
(define (grid size notification-semaphore)
  (define channels (chans size))
  (define (receive-and-fwd in out)
    (channel-put out (begin (displayln "hi!") (channel-get in))))
  (displayln "unimplemented"))

; TODO:  Change program to work with multiple iterations of communication
(define (main experiment-selection iterations size)
  (let* ([size-num (string->number size)]
         [notification-semaphore (make-semaphore size-num)])
    (match (string-downcase (string-trim experiment-selection))
      ["ring" (ring size-num notification-semaphore)]
      ["kn" (kn size-num)]
      ["grid" (grid size-num notification-semaphore)]))
  (displayln (string-append experiment-selection " of Whispers completed successfully")))