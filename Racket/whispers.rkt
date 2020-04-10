#lang racket

(provide main)
(require racket/vector)

; TODO:  Change chans function to use a list
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

(define (communicate notification-semaphore ch count comms-events)
  ;(printf "count: ~v, length: ~a, events: ~v\n" count (length comms-events) comms-events)
  (let ([zc (zero? count)] [nc (null? comms-events)])
    (cond
      [(and zc nc) (semaphore-post notification-semaphore)]
      [zc (let ([result (apply sync comms-events)])
            (communicate notification-semaphore ch count (remq result comms-events)))]
      [nc (begin (sync ch)
                 (communicate notification-semaphore ch (sub1 count) comms-events))]
      [else (let* ([evs (list* ch comms-events)]
                   [result
                    ;(wrap-evt ch (λ (e) (begin (displayln (number->string e)) (e))))
                    (apply sync evs)])
              ;(displayln (~v result))
              (if (channel-put-evt? result)
                  (communicate notification-semaphore ch count (remq result comms-events))
                  (communicate notification-semaphore ch (sub1 count) comms-events)))]))
  #| (if (and (zero? count) (null? comms-events))
     (semaphore-post notification-semaphore)
      ((let* ([evs (list* ch comms-events)]
              [result
               ;(wrap-evt ch (λ (e) (begin (displayln (number->string e)) (e))))
               (apply sync evs)])
         ;(displayln (~v result))
         (if (channel-put-evt? result)
             (communicate notification-semaphore ch count (remq result comms-events))
             (communicate notification-semaphore ch (sub1 count) comms-events))))) |#
  (displayln "Finished communicate"))

(define (kn size notification-semaphore)
  (define channels (chans size))
  (define threads
    (for/list ([i (in-range size)])
      (let* ([events (map (λ (c) (channel-put-evt c i)) channels)]
             [events2 (flatten (list* (take events i) (drop events (add1 i))))])
        (printf "~v\n" events2)
        (thread (λ () (communicate notification-semaphore (list-ref channels i) (sub1 size)
                                   events2))))))
  ;(printf "~v\n" threads)
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
  ;(define notification-semaphore (make-semaphore))
  ;(displayln experiment-selection)
  (let* ([size-num (string->number size)]
         [notification-semaphore (make-semaphore size-num)])
    (match (string-downcase (string-trim experiment-selection))
      ["ring" (ring size-num notification-semaphore)]
      ["kn" (kn size-num notification-semaphore)]
      ["grid" (grid size-num notification-semaphore)]))
  (displayln (string-append experiment-selection " of Whispers completed successfully")))