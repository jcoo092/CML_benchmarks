#lang racket/base

(require racket/place)

; Simply sends what it receives.  This doesn't need to be a place creator, since it should re-use prefix's place.  I think.
(define (ID in out)
  ((place-channel-put out (place-channel-get in))
   (ID in out)))

(define (run-prefix N in out)
  (place-channel-put out N)
  (ID in out))

; Sends out an initial value, then behaves as ID
(define (place/prefix N in out)
  (place/context
   c
   (run-prefix N in out)))

(define (run-successor in out)
  (place-channel-put out (add1 (place-channel-get in)))
  (run-successor in out))

; Sends out what it receives plus one
(define (place/successor in out)
  (place/context
   c
   (run-successor in out)))

(define (run-delta in out0 out1)
  (let ([x (place-channel-get in)])
    (place-channel-put out0 x)
    (place-channel-put out1 x))
  (run-delta in out0 out1))

; Sends out what it receives, but over two channels
; Strictly speaking, this probably should use a wrap combinator so that either channel can be used
; first, but I don't think it is particularly important here.  Moreover, I'm not sure that place channels
; actually permit one to sync on a send, which makes the wrap combinator difficult (impossible?) to use.
(define (place/delta in out0 out1)
  (place/context
   c
   (run-delta in out0 out1)))

(define (place/consumer in iterations)
  (place/context
   c
   (for ([i (in-range iterations)])
     (place-channel-get in))))

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
