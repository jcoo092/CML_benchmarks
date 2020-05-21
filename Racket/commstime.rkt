
#lang racket/base

(require racket/place)

; Simply sends what it receives.  This doesn't need to be a place creator, since it should re-use prefix's place.  I think.
(define (ID in out iterations)
  (for ([i (in-range iterations)])
    (place-channel-put out (place-channel-get in))))

; Sends out an initial value, then behaves as ID
(define (place/prefix N in out iterations)
  (place/context
   c
   (begin
     (place-channel-put out N)
     (ID in out iterations))))

; Sends out what it receives plus one
(define (place/successor in out iterations)
  (place/context
   c
   (for ([i (in-range iterations)])
     (place-channel-put out (add1 (place-channel-get in))))))

; Sends out what it receives, but over two channels
; Strictly speaking, this probably should use a wrap combinator so that either channel can be used
; first, but I don't think it is particularly important here.  Moreover, I'm not sure that place channels
; actually permit one to sync on a send, which makes the wrap combinator difficult (impossible?) to use.
(define (place/delta in out0 out1 iterations)
  (place/context
   c
   (for ([i (in-range iterations)])
     (let ([x (place-channel-get in)])
       (place-channel-put out0 x)
       (place-channel-put out1 x)))))

; This isn't made a place, so that it runs on the main thread and thus keeps the whole program from appearing to have finished.
(define (consumer in iterations)
  (for ([i (in-range iterations)])
    (place-channel-get in)))

(define (experiment iterations)
  (let-values ([(a-rx a-tx) (place-channel)] [(b-rx b-tx) (place-channel)]
               [(c-rx c-tx) (place-channel)] [(d-rx d-tx) (place-channel)])
    (place/successor c-rx a-tx iterations)
    (place/delta b-rx c-tx d-tx iterations)
    (place/prefix 0 a-rx b-tx iterations)
    (consumer d-rx iterations)))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (experiment iterations)
  (displayln "Communications Time completed succesfully."))
