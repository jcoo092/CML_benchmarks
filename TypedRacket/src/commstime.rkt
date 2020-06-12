#lang typed/racket/base

(require racket/place)

                                        ; Simply sends what it receives.  This doesn't need to be a place creator, since it should re-use prefix's place.  I think.
(: ID (-> Place-Channel Place-Channel Void))
(define (ID in out)
  ((place-channel-put out (place-channel-get in))
   (ID in out)))

(: run-prefix (-> Integer Place-Channel Place-Channel Void))
(define (run-prefix N in out)
  (place-channel-put out N)
  (ID in out))

                                        ; Sends out an initial value, then behaves as ID
(: place/prefix (-> Nonnegative-Fixnum Place-Channel Place-Channel Place))
(define (place/prefix N in out)
  (place/context
   c
   (run-prefix N in out)))

(: run-successor (-> (Place-Channel Integer) Place-Channel Void))
(define (run-successor in out)
  (place-channel-put out (add1 (place-channel-get in)))
  (run-successor in out))

                                        ; Sends out what it receives plus one
(: place/successor (-> Place-Channel Place-Channel Place))
(define (place/successor in out)
  (place/context
   c
   (run-successor in out)))

(: run-delta (-> Place-Channel Place-Channel Place-Channel Void))
(define (run-delta in out0 out1)
  (let ([x (place-channel-get in)])
    (place-channel-put out0 x)
    (place-channel-put out1 x))
  (run-delta in out0 out1))

; Sends out what it receives, but over two channels
(: place/delta (-> Place-Channel Place-Channel Place-Channel Place))
(define (place/delta in out0 out1)
  (place/context
   c
   (run-delta in out0 out1)))

(: place/consumer (-> Place-Channel Nonnegative-Fixnum Place))
(define (place/consumer in iterations)
  (place/context
   c
   (for ([i (in-range iterations)])
     (place-channel-get in))))

(: experiment (-> Nonnegative-Fixnum Void))
(define (experiment iterations)
  (let-values ([(a-rx a-tx) (place-channel)] [(b-rx b-tx) (place-channel)]
               [(c-rx c-tx) (place-channel)] [(d-rx d-tx) (place-channel)])
    (place/successor c-rx a-tx)
    (place/delta b-rx c-tx d-tx)
    (place/prefix 0 a-rx b-tx)
    (place-wait (place/consumer d-rx iterations)))
  (displayln "Communications Time completed succesfully."))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (experiment iterations))
