#lang racket/base

(require racket/random racket/match)
(require racket/place)

(define (create-place-chans length)
  (for/fold ([rxes null] [txes null] #:result (values rxes txes))
      ([iteration (in-range length)])
    (define-values (rx tx) (place-channel))
    (values (cons rx rxes) (cons tx txes))))

(define (place/sender iterations channels)
  (place/context
   c
   (begin
     (for ([i (in-range iterations)])
       (place-channel-put (random-ref channels) i))
     (place-channel-put (random-ref channels) 'NONE))))

(define (place/receiver channels)
  (place/context
   c
   (begin
     (define choose (apply choice-evt channels))
     (define (receive-and-process)
       (match (sync choose)
         ['NONE
          (void)]
         [Some
          (begin
            (printf "Received message ~v~n" Some)
            (receive-and-process))]))

     (receive-and-process))))

(define (experiment iterations num-channels)
  (let-values ([(ch-rxes ch-txes) (create-place-chans num-channels)])
    (let ([r (place/receiver ch-rxes)]
          [s (place/sender iterations ch-txes)])
      (place-wait r)
      (place-wait s)))
  (displayln "Select Time completed successfully."))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (define num-channels (string->number (vector-ref cmd-params 1)))
  (experiment iterations num-channels))
