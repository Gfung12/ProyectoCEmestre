#lang typed/racket

(require "types.rkt")
(require "filters.rkt")

(provide list->lazy-stream
         filtrar-rango-creditos
         exportar-combinaciones-json)

;; 1. Convertir lista generada a LazyStream
(: list->lazy-stream (-> (Listof ScheduleCombination) (LazyStream ScheduleCombination)))
(define (list->lazy-stream lista)
  (if (null? lista)
      '()
      (StreamNode (car lista)
                  (delay (list->lazy-stream (cdr lista))))))

;; 2. Filtrar el stream usando el filtro polimórfico
(: filtrar-rango-creditos (-> Integer Integer (LazyStream ScheduleCombination) (LazyStream ScheduleCombination)))
(define (filtrar-rango-creditos min-cred max-cred flujo)
  (filtrar-stream-polimorfico
   (lambda ([comb : ScheduleCombination])
     (let ([total (ScheduleCombination-total-credits comb)])
       (and (>= total min-cred) (<= total max-cred))))
   flujo))

;; 3. Funciones auxiliares para dar formato JSON
(: formato-grupo-json (-> SelectedGroup String))
(define (formato-grupo-json grupo)
  (string-append
   "        {\n"
   "          \"course_code\": \"" (SelectedGroup-code grupo) "\",\n"
   "          \"group_number\": " (number->string (SelectedGroup-group-number grupo)) ",\n"
   "          \"career\": \"" (SelectedGroup-career grupo) "\"\n"
   "        }"))

(: grupos->json (-> (Listof SelectedGroup) String))
(define (grupos->json grupos)
  (cond
    [(null? grupos) ""]
    [(null? (cdr grupos)) (formato-grupo-json (car grupos))]
    [else (string-append (formato-grupo-json (car grupos)) ",\n" (grupos->json (cdr grupos)))]))

(: formato-combinacion-json (-> ScheduleCombination String))
(define (formato-combinacion-json comb)
  (string-append
   "  {\n"
   "    \"total_credits\": " (number->string (ScheduleCombination-total-credits comb)) ",\n"
   "    \"selections\": [\n"
   (grupos->json (ScheduleCombination-selections comb))
   "\n    ]\n"
   "  }"))

;; 4. Escritura perezosa (lazy) en el archivo JSON
(: escribir-stream-json (-> Output-Port (LazyStream ScheduleCombination) Boolean Void))
(define (escribir-stream-json puerto flujo es-primero?)
  (cond
    [(null? flujo) (void)]
    [else
     (unless es-primero?
       (display ",\n" puerto))
     (display (formato-combinacion-json (StreamNode-first flujo)) puerto)
     (escribir-stream-json puerto (force (StreamNode-rest flujo)) #false)]))

(: exportar-combinaciones-json (-> String (LazyStream ScheduleCombination) Void))
(define (exportar-combinaciones-json ruta flujo)
  (call-with-output-file ruta
    (lambda ([puerto : Output-Port])
      (display "[\n" puerto)
      (escribir-stream-json puerto flujo #true)
      (display "\n]\n" puerto))
    #:exists 'replace))