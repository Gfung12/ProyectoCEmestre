#lang typed/racket

(require "types.rkt")

(provide filtrar-lista-polimorfico
         filtrar-stream-polimorfico
         stream->list-polimorfico)

(: filtrar-lista-polimorfico (All (A) (-> (-> A Boolean) (Listof A) (Listof A))))
(define (filtrar-lista-polimorfico predicado lista)
  (cond
    [(null? lista) '()]
    [(predicado (car lista))
     (cons (car lista) (filtrar-lista-polimorfico predicado (cdr lista)))]
    [else
     (filtrar-lista-polimorfico predicado (cdr lista))]))

(: filtrar-stream-polimorfico (All (A) (-> (-> A Boolean) (LazyStream A) (LazyStream A))))
(define (filtrar-stream-polimorfico predicado flujo)
  (cond
    [(null? flujo) '()]
    [(predicado (StreamNode-first flujo))
     (StreamNode (StreamNode-first flujo)
                 (delay (filtrar-stream-polimorfico predicado (force (StreamNode-rest flujo)))))]
    [else
     (filtrar-stream-polimorfico predicado (force (StreamNode-rest flujo)))]))

(: stream->list-polimorfico (All (A) (-> (LazyStream A) (Listof A))))
(define (stream->list-polimorfico flujo)
  (cond
    [(null? flujo) '()]
    [else
     (cons (StreamNode-first flujo)
           (stream->list-polimorfico (force (StreamNode-rest flujo))))]))