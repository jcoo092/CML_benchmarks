#lang racket/base

(require racket/list racket/string racket/function)
(require racket/place racket/future)
#;(require srfi/43)

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

(define (create-place-chans length)
  (for/fold ([rxes null] [txes null] #:result (values rxes txes))
      ([iteration (in-range length)])
    (define-values (rx tx) (place-channel))
    (values (cons rx rxes) (cons tx txes))))

(define (create-place-chans-vector length)
  (define rxes (make-vector length))
  (define txes (make-vector length))
  (for ([i (in-range length)])
    (let-values ([(rx tx) (place-channel)])
      (vector-set! rxes i rx)
      (vector-set! txes i tx)))
  (values rxes txes))

                                        ; This assumes that the permutation size is smaller than the length of the list.
(define (permute-list l permutation-size)
  (define-values (new-back new-front) (split-at l permutation-size))
  (append new-front new-back))

#;
(define (cumulative-sum-vec in-vec)
(define ret-vec (make-vector (vector-length in-vec)))
(vector-set! ret-vec 0 (vector-ref in-vec 0))
(for ([i (in-range 1 (vector-length in-vec))])
(vector-set! ret-vec i
(+ (vector-ref ret-vec (sub1 i)) (vector-ref in-vec i))))
ret-vec)

#;
(define (find-place-for-thread thread-num cumulative-sizes)
(vector-index (curry < thread-num) cumulative-sizes))

#;
(define (communicate ch count comms-events)
(let ([zc (zero? count)] [nc (null? comms-events)])
(cond
[(and zc nc) (void)]
[zc (let ([result (apply sync comms-events)])
(communicate ch count (remq result comms-events)))]
[nc (begin (sync ch)
(communicate ch (sub1 count) comms-events))]
[else (let ([result (apply sync ch comms-events)])
(if (channel-put-evt? result)
(communicate ch count (remq result comms-events))
(begin
(printf "~a~n" result)
(communicate ch (sub1 count) comms-events))))])))

                                        ;***************************
                                        ;********* Ring ************

(define (rcv-and-fwd in-ch out-ch)
  (channel-put out-ch (channel-get in-ch))
  (rcv-and-fwd in-ch out-ch))

(define (run-place rx tx start-chan end-chan)
  (let ([msg (place-channel-get rx)])
    (channel-put start-chan msg)
    (let ([msg-again (channel-get end-chan)])
      (place-channel-put tx msg-again)
      (if (zero? msg-again)
          (void)
          (run-place rx tx start-chan end-chan)))))

(define (start-place num-threads rx tx)
  (place/context
   c
   (let ([ch-vec (chans-vector num-threads)]
         [end-chan (make-channel)])
     (for ([i (in-range (sub1 num-threads))])
       (thread (λ () (rcv-and-fwd (vector-ref ch-vec i) (vector-ref ch-vec (add1 i))))))
     (thread (λ () (rcv-and-fwd (vector-ref ch-vec (sub1 num-threads)) end-chan)))
     (run-place rx tx (vector-ref ch-vec 0) end-chan))))

#;(define (interpose rx tx)
  (match (place-channel-get rx)
    [0 (void)]
    [i (begin
         (place-channel-put tx (sub1 i))
(interpose rx tx))]))

(define (interpose rx tx)
  (let ([i (place-channel-get rx)])
    (case i
      [(0) (void)]
      [else (begin
              (place-channel-put tx (sub1 i))
              (interpose rx tx))])))

(define (ring/place iterations size num-places)
  (define threads-per-place (vector->list (distribute-extra-threads size num-places)))
  (define-values (rxes txes) (create-place-chans (add1 num-places)))
  (define perm-txes (permute-list txes 1))
  (let ([places (map (λ (n r t) (start-place n r t)) threads-per-place
                     (list-tail rxes 1) (list-tail perm-txes 1))])
    (place-channel-put (second txes) iterations)
    (interpose (first rxes) (first perm-txes))
    (for-each place-wait places)))

                                        ;***************************
                                        ;************ Kn ***********

#|(define (make-send-to-place-function txes chans-sizes-vec)
(define cumulative-size (cumulative-sum-vec chans-sizes-vec))
#;
(define (find-place thread-num)       ; ;
(vector-index (curry < thread-num) cumulative-size))
(define (send-to-place thread-num message)
(place-channel-put
(vector-ref txes (find-place-for-thread thread-num cumulative-size))
(cons thread-num message)))
(λ (n message) (send-to-place n message)))

(define (make-communicate-func base-msg-count base-comms-evts)
(define (communicate ch iteration message-count comms-events)
(let ([ic (zero? iteration)] [zc (zero? count)] [nc (null? comms-events)])
(cond
[ic (void)]
[(and zc nc) (communicate (sub1 iteration) base-msg-count base-comms-evts)]
[zc (let ([result (apply sync comms-events)])
(communicate ch iteration  message-count (remq result comms-events)))]
[nc (begin (sync ch)
(communicate ch (sub1 message-count) comms-events))]
[else (let* (#;[evs (list* ch comms-events)]
[result (apply sync ch comms-events)])
(if (channel-put-evt? result)
(communicate ch message-count (remq result comms-events))
(begin
(printf "~a\n" result)
(communicate ch (sub1 message-count) comms-events))))])))
(λ (ch i mc ce) (communicate ch i mc ce)))

(define (kn/place size num-places)
(define-values (rxes txes) (create-place-chans-vector num-places))
(define channels-sizes-vector (distribute-extra-threads size num-places))
(define send-to-place (make-send-to-place-function txes channels-sizes-vector))
(define list-of-chan-vecs
(for/list ([s (in-vector channels-sizes-vector)])
(chans-vector s)))
#;
(define threads                       ;
(for/list ([i (in-range size)])       ;
(let* ([events (map (λ (c) (channel-put-evt c i)) channels)] ;
[events2 (flatten (list* (take events i) (drop events (add1 i))))]) ;
(thread (λ () (communicate (list-ref channels i) (sub1 size) ;
events2))))))
(displayln "started kn")
#;(for-each thread-wait threads)
)|#

                                        ;***************************
                                        ;*********** Grid **********


#|(define (compute-neighbour-indices width idx)
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
(for-each thread-wait threads))|#

                                        ;***************************

#;(define (get-numerical-param-from-vec-or-default default vec param-pos)
  (if (< param-pos (vector-length vec))
      (string->number (vector-ref vec param-pos))
      default))

(module+ main
  (define default-width 50)
  (define cmd-params (current-command-line-arguments))
  (let* ([experiment-selection (string-trim (vector-ref cmd-params 0))]
         [iterations (string->number (vector-ref cmd-params 1))]
         [size-num (string->number (vector-ref cmd-params 2))]
         [num-places (min size-num (processor-count))])
    (if (< size-num num-places)
        (displayln (format "The number of threads called for is too small to test the capabilities of this program.  Please request a larger number.  For this computer, the minimum is ~v." num-places) (current-error-port))
        (begin
          (case (string-downcase experiment-selection)
            [("ring") (ring/place iterations size-num num-places)]
            #;[("kn") (kn iterations size-num num-places)]
            #;
            [("grid") (begin                  ; ; ; ;
            (define (gnp) (curry get-numerical-param-from-vec-or-default ; ; ; ;
            default-width cmd-params))        ; ; ; ;
            (grid iterations (gnp 3) (gnp 4) num-places))])
          (displayln (string-append experiment-selection " of Whispers completed successfully"))))))
