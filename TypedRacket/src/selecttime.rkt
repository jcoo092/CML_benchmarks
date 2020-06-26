#lang typed/racket/base

(require racket/random)
(require racket/place racket/fixnum)

(: create-place-chans (-> Nonnegative-Fixnum (Values (Listof Place-Channel) (Listof Place-Channel))))
(define (create-place-chans length)
  (for/fold ([rxes : (Listof Place-Channel) null] [txes : (Listof Place-Channel) null] #:result (values rxes txes))
      ([iteration (in-range length)])
    (define-values (rx tx) (place-channel))
    (values (cons rx rxes) (cons tx txes))))

(: place/sender (-> Nonnegative-Fixnum (Listof Place-Channel) Place))
(define (place/sender iterations channels)
  (place/context
   c
   (begin
     (define choose (apply choice-evt channels))
     (for ([i (in-range (fxquotient iterations 2))])
       (place-channel-put (random-ref channels) i)
       (sync choose)))))

(: place/receiver (-> (Listof Place-Channel) Place))
(define (place/receiver channels)
  (place/context
   c
   (begin
     (define choose (apply choice-evt channels))
     (define (receive-and-process)
       (sync choose)
       (place-channel-put (random-ref channels) 'ACK)
       (receive-and-process))

     (receive-and-process))))

(: experiment (-> Nonnegative-Fixnum Nonnegative-Fixnum Void))
(define (experiment iterations num-channels)
  (let-values ([(ch-rxes ch-txes) (create-place-chans num-channels)])
    (let ([r (place/receiver ch-rxes)]
          [s (place/sender iterations ch-txes)])
      (place-wait s)))
  (displayln "Select Time completed successfully."))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (cast (string->number (vector-ref cmd-params 0)) Nonnegative-Fixnum))
  (define num-channels (cast (string->number (vector-ref cmd-params 1)) Nonnegative-Fixnum))
  (experiment iterations num-channels))
