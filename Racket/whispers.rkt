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
  (if (and (zero? count) (null? comms-events))
      (begin (displayln "Finished communicate") (semaphore-post notification-semaphore))
      ((let* ([evs (flatten (list* ch comms-events))]
              [result
;                      (wrap-evt ch (λ (e) (begin (displayln (number->string e)) (e))))
                      (apply sync evs)])
         ;(displayln (~v result))
         (if (channel-put-evt? result)
             ((printf "is result in comms-events? ~v\n" (ormap (curry eq? result) comms-events))
              (communicate notification-semaphore ch count (remq result comms-events)))
             (communicate notification-semaphore ch (sub1 count) comms-events))))))

(define (kn size notification-semaphore)
  #| (define (communicate ch count comms-events)
   (displayln (number->string count))
    (if (and (zero? count) (null? comms-events))
        (begin (displayln "Finished communicate") (semaphore-post notification-semaphore))
        ((let ([result (sync
                        (wrap-evt ch (λ (e) (begin (displayln (number->string e)) (e))))
                        (apply comms-events))])
          (if (channel-put-evt? result)
            (communicate count (remq result comms-events))
            (communicate (sub1 count) comms-events)))))) |#
  (define channels (chans size))
  #| (define (receive-and-fwd in out)
    (channel-put out (channel-get in))) |#
  (for ([i (in-range size)])
    (let* ([events (map (λ (c) (channel-put-evt c i)) channels)]
           [events2 (list* (take events i) (drop events (add1 i)))])
      ;(list-set events i (channel-get (list-ref channels i))) ; Need to change this to drop the relevant event
      (thread (λ () (communicate notification-semaphore (list-ref channels i) (sub1 size)
                                 events2)))))
  (displayln "started kn"))

; TODO:  Implement grid (which will probably largely be a copy of kn)
(define (grid size notification-semaphore)
  (define channels (chans size))
  (define (receive-and-fwd in out)
    (channel-put out (begin (displayln "hi!") (channel-get in))))
  (displayln "unimplemented")
  )

; TODO:  Modify main (or experiment) to work with semaphores with a size > 1
; TODO:  Change program to work with multiple iterations of communication
(define (main experiment-selection iterations size)
  ;(experiment (string->number size))
  ;(define notification-semaphore (make-semaphore))
  ;(define size-num (string->number size))
  ;(displayln experiment-selection)
  (let* ([size-num (string->number size)]
         [notification-semaphore (make-semaphore size-num)])
    (match (string-downcase (string-trim experiment-selection))
      ["ring" (ring size-num notification-semaphore)]
      ["kn" (kn size-num notification-semaphore)]
      ["grid" (grid size-num notification-semaphore)])
    (semaphore-wait notification-semaphore))
  (displayln (string-append experiment-selection " of Whispers completed successfully")))