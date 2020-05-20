#lang racket/base

#;(provide main)
(require racket/match racket/list racket/string racket/function)
(require racket/place racket/future)

(define (chans-list size)
  (build-list size (λ (i) (make-channel))))

(define (chans-vector size)
  (build-vector size (λ (i) (make-channel))))

(define (distribute-extra-threads total-threads base)
  (define ret-vec (make-vector base (quotient total-threads base)))
  (define leftovers (remainder total-threads base))
  (for ([i (in-range leftovers)])
    (let ([curr-val (vector-ref ret-vec i)])
      (vector-set! ret-vec i (add1 curr-val))))
  ret-vec)

; My function to collect a bunch of the ends from place channel creation into two separate lists.
#;
(define (create-place-chans length)
  (define (helper iteration rxes txes)
    (match iteration
      [0 (values rxes txes)]
      [iter
       (let-values ([(rx tx) (place-channel)])
         (helper (sub1 iteration) (list* rx rxes) (list* tx txes)))]))
  (helper length null null))

; Alternatives suggested by @sorawee in the Racket slack.  Thanks!
#;
(define (create-place-chans length)
  (let loop ([iteration length] [rxes null] [txes null])
    (match iteration
      [0 (values rxes txes)]
      [_ (define-values (rx tx) (place-channel))
         (loop (sub1 iteration) (cons rx rxes) (cons tx txes))])))

(define (create-place-chans length)
  (for/fold ([rxes null] [txes null] #:result (values rxes txes)) 
      ([iteration (in-range length)])
    (define-values (rx tx) (place-channel))
    (values (cons rx rxes) (cons tx txes))))

; This assumes that the permutation size is smaller than the length of the list.
(define (permute-list l permutation-size)
  (define new-back (take l permutation-size))
  (define new-front (drop l permutation-size))
  (flatten (list new-front new-back)))

;***************************

#;
(define (ring size notification-semaphore)
  (define channels (chans-vector size))
  #;(define (vrc idx) (vector-ref channels idx))
  (define (vrc) (curry vector-ref channels))
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

(define (run-thread in out)
  (channel-put out (channel-get in))
  #;(displayln "Thread just forwarded its message!")
  (run-thread in out))

(define (run-place rx tx start-chan end-chan)    
  (let ([message (place-channel-get rx)])
    #;(printf "This place just got a message! Message was ~a\n" message)
    (match message
      [0 (begin
           (place-channel-put tx message)
           (void))]
      [m
       (begin
         (channel-put start-chan m)
         (let ([message-again (channel-get end-chan)])
           (place-channel-put tx message-again)
           (run-place rx tx start-chan end-chan)))])))

(define (start-place num-threads rx tx)
  (place/context
   c
   (let ([ch-vec (chans-vector num-threads)]
         [end-chan (make-channel)])
     (for ([i (in-range (sub1 num-threads))])
       (thread (λ () (run-thread (vector-ref ch-vec i) (vector-ref ch-vec (add1 i)))))
       ;(displayln "Started a thread!")
       )
     (thread (λ () (run-thread (vector-ref ch-vec (sub1 num-threads)) end-chan)))
     ;(displayln "Started the last thread!")
     ;(displayln "Started place!")
     (run-place rx tx (vector-ref ch-vec 0) end-chan))))

(define (interpose rx tx)
  #;(displayln "Started interpose!")
  (match (place-channel-get rx)
    [0 (displayln "Job's done!")]
    [i (begin
         #;(displayln "Matched!")
         (place-channel-put tx (sub1 i))
         #;(displayln "Interposed!")
         (interpose rx tx))]))

(define (ring/place iterations size num-places)
  (define threads-per-place (vector->list (distribute-extra-threads size num-places)))
  (define-values (rxes txes) (create-place-chans (add1 num-places)))
  (define perm-txes (permute-list txes 1))
  (let ([places (map (λ (n r t) (start-place n r t)) threads-per-place (drop rxes 1) (drop perm-txes 1))])
    (place-channel-put (second txes) iterations)
    (interpose (first rxes) (first perm-txes))
    (for-each place-wait places)))

;***************************

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
                  (begin (printf "~a\n" result) (communicate ch (sub1 count) comms-events))))])))

(define (kn size)
  (define channels (chans-list size))
  (define threads
    (for/list ([i (in-range size)])
      (let* ([events (map (λ (c) (channel-put-evt c i)) channels)]
             [events2 (flatten (list* (take events i) (drop events (add1 i))))])
        (thread (λ () (communicate (list-ref channels i) (sub1 size)
                                   events2))))))
  (displayln "started kn")
  (for-each thread-wait threads))

;***************************

(define (compute-neighbour-indices width idx)
  (let-values ([(y x) (quotient/remainder idx width)])
    (filter-not (λ (a) (eq? a (void)))
                (list
                 (when (positive? y) (- idx width))
                 (when (positive? x) (sub1 idx))
                 (when (< x (sub1 width)) (add1 idx))
                 (when (< y (sub1 width)) (+ idx width))))))

(define (grid width height)
  (define size (* width height))
  (define channels (chans-vector size))
  (define (vrc idx) (vector-ref channels idx))
  (define threads
    (for/list ([i (in-range size)])
      (let* ([in-chan (vrc i)]
             [neighs (compute-neighbour-indices width i)]
             [out-chans (map vrc neighs)]
             [out-evts (map (λ (c) (channel-put-evt c i)) out-chans)])
        (thread (λ () (communicate in-chan (length out-evts) out-evts))))))
  (displayln "started grid")
  (for-each thread-wait threads))

;***************************

; TODO:  Change program to work with multiple iterations of communication
#;(define (main experiment-selection iterations size [width "50"] [height "50"])
  (let* ([size-num (string->number size)]
         [notification-semaphore (make-semaphore size-num)])
    (match (string-downcase (string-trim experiment-selection))
      ["ring" (ring size-num notification-semaphore)]
      ["kn" (kn size-num)]
      ["grid" (grid (string->number width) (string->number height))]))
(displayln (string-append experiment-selection " of Whispers completed successfully")))

(define (get-numerical-param-from-vec-or-default default vec param-pos)
  (if (< param-pos (vector-length vec))
      (string->number (vector-ref vec param-pos))
      default))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (let* ([experiment-selection (string-trim (vector-ref cmd-params 0))]
         [iterations (string->number (vector-ref cmd-params 1))]
         [size-num (string->number (vector-ref cmd-params 2))]
         [notification-semaphore (make-semaphore size-num)]
         [num-places (processor-count)])
    (match (string-downcase experiment-selection)
      ["ring" (ring/place iterations size-num num-places)]
      ["kn" (kn iterations size-num num-places)]
      ["grid" (begin
                (define (gnp) (curry get-numerical-param-from-vec-or-default 50 cmd-params))
                (grid iterations (gnp 3) (gnp 4) num-places))])
    (displayln (string-append experiment-selection " of Whispers completed successfully"))))
