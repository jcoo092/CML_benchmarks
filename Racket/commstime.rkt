#lang racket

(provide main)

; Simply sends what it receives
(define (ID in out count)
  (for ([i (in-range count)])
    (channel-put out (channel-get in))))

; Sends out an initial value, then behaves as ID
(define (prefix N in out count)
  (channel-put out N)
  (ID in out count))

; Sends out what it receives plus one
(define (successor in out count)
  (for ([i (in-range count)])
    (let ([x (channel-get in)])
      (channel-put out (add1 x)))))

; Sends out what it receives, but over two channels
; Strictly speaking, this probably should use a wrap combinator so that either channel can be used
; first, but it isn't particularly important here
(define (delta in out0 out1 count)
  (for ([i (in-range count)])
    (let ([x (channel-get in)])
      (channel-put out0 x)
      (channel-put out1 x))))

(define (consumer in count)
  (for ([i (in-range count)])
    #(displayln (channel-get in))
    (channel-get in)))

(define (experiment experiments)
  (let ([a (make-channel)] [b (make-channel)] [c (make-channel)] [d (make-channel)])
    (thread (λ () (prefix 0 a b experiments)))
    (thread (λ () (delta b c d experiments)))
    (thread (λ () (successor c a experiments)))
    (consumer d experiments)))

(define (main experiments)
  (experiment (string->number experiments))
  (displayln "CommunicationsTime completed successfully"))