#lang typed/racket

(require "types.rkt")

(provide generar-combinaciones)


(: bloques-chocan? (-> ScheduleBlock ScheduleBlock Boolean))
(define (bloques-chocan? b1 b2)
  (and (= (ScheduleBlock-day b1) (ScheduleBlock-day b2))
       (< (ScheduleBlock-start-time b1) (ScheduleBlock-end-time b2))
       (< (ScheduleBlock-start-time b2) (ScheduleBlock-end-time b1))))

(: choca-con-lista? (-> ScheduleBlock (Listof ScheduleBlock) Boolean))
(define (choca-con-lista? bloque lista-bloques)
  (cond
    [(null? lista-bloques) #false]
    [(bloques-chocan? bloque (car lista-bloques)) #true]
    [else (choca-con-lista? bloque (cdr lista-bloques))]))

(: grupo-valido-en-combinacion? (-> SelectedGroup (Listof SelectedGroup) Boolean))
(define (grupo-valido-en-combinacion? nuevo-grupo seleccionados)
  ;;Extraemos y aplanamos todos los bloques de horarios de los grupos ya seleccionados en la combinación
  (define horarios-existentes
    (append-map SelectedGroup-schedules seleccionados))
  
  ;;Verificamos que ningún bloque del nuevo grupo colisione con los horarios existentes
  (not (ormap (lambda ([b : ScheduleBlock])
                (choca-con-lista? b horarios-existentes))
              (SelectedGroup-schedules nuevo-grupo))))


(: generar-combinaciones (-> (Listof (Listof SelectedGroup)) (Listof ScheduleCombination)))
(define (generar-combinaciones lista-de-cursos-candidatos)
  (cond
    ;;Caso base: si ya no hay cursos por procesar, retornamos un horario vacío (0 créditos)
    [(null? lista-de-cursos-candidatos)
     (list (ScheduleCombination '() 0))]
    
    [else
     (define grupos-curso-actual (car lista-de-cursos-candidatos))
     (define combinaciones-resto (generar-combinaciones (cdr lista-de-cursos-candidatos)))
     
     ;;Para cada opción de grupo del curso actual, intentamos insertarla en las combinaciones válidas del resto
     (append-map
      (lambda ([grupo : SelectedGroup])
        (filter-map
         (lambda ([comb : ScheduleCombination])
           (if (grupo-valido-en-combinacion? grupo (ScheduleCombination-selections comb))
               (ScheduleCombination
                (cons grupo (ScheduleCombination-selections comb))
                (+ (SelectedGroup-credits grupo) (ScheduleCombination-total-credits comb)))
               #false))
         combinaciones-resto))
      grupos-curso-actual)]))