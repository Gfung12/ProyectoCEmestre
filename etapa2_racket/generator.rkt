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

(: horarios-grupo-chocan? (-> (Listof ScheduleBlock) (Listof ScheduleBlock) Boolean))
(define (horarios-grupo-chocan? nuevos-horarios horarios-existentes)
  (cond
    [(null? nuevos-horarios) #false]
    [(choca-con-lista? (car nuevos-horarios) horarios-existentes) #true]
    [else (horarios-grupo-chocan? (cdr nuevos-horarios) horarios-existentes)]))

(: extraer-horarios (-> (Listof SelectedGroup) (Listof ScheduleBlock)))
(define (extraer-horarios seleccionados)
  (cond
    [(null? seleccionados) '()]
    [else (append (SelectedGroup-schedules (car seleccionados))
                  (extraer-horarios (cdr seleccionados)))]))

(: grupo-valido-en-combinacion? (-> SelectedGroup (Listof SelectedGroup) Boolean))
(define (grupo-valido-en-combinacion? nuevo-grupo seleccionados)
  (not (horarios-grupo-chocan? (SelectedGroup-schedules nuevo-grupo)
                               (extraer-horarios seleccionados))))

(: concatenar-streams (All (A) (-> (LazyStream A) (Promise (LazyStream A)) (LazyStream A))))
(define (concatenar-streams s1 s2-promesa)
  (cond
    [(null? s1) (force s2-promesa)]
    [else
     (StreamNode (StreamNode-first s1)
                 (delay (concatenar-streams (force (StreamNode-rest s1)) s2-promesa)))]))

(: insertar-grupo-en-stream (-> SelectedGroup (LazyStream ScheduleCombination) (LazyStream ScheduleCombination)))
(define (insertar-grupo-en-stream grupo flujo-resto)
  (cond
    [(null? flujo-resto) '()]
    [else
     (let ([comb (StreamNode-first flujo-resto)]
           [resto (StreamNode-rest flujo-resto)])
       (if (grupo-valido-en-combinacion? grupo (ScheduleCombination-selections comb))
           (StreamNode
            (ScheduleCombination
             (cons grupo (ScheduleCombination-selections comb))
             (+ (SelectedGroup-credits grupo) (ScheduleCombination-total-credits comb)))
            (delay (insertar-grupo-en-stream grupo (force resto))))
           (insertar-grupo-en-stream grupo (force resto))))]))

(: expandir-grupos-stream (-> (Listof SelectedGroup) (LazyStream ScheduleCombination) (LazyStream ScheduleCombination)))
(define (expandir-grupos-stream grupos flujo-resto)
  (cond
    [(null? grupos) '()]
    [else
     (concatenar-streams
      (insertar-grupo-en-stream (car grupos) flujo-resto)
      (delay (expandir-grupos-stream (cdr grupos) flujo-resto)))]))

(: generar-combinaciones (-> (Listof (Listof SelectedGroup)) (LazyStream ScheduleCombination)))
(define (generar-combinaciones lista-de-cursos-candidatos)
  (cond
    [(null? lista-de-cursos-candidatos)
     (StreamNode (ScheduleCombination '() 0) (delay '()))]
    [else
     (let ([grupos-curso-actual (car lista-de-cursos-candidatos)]
           [flujo-resto (generar-combinaciones (cdr lista-de-cursos-candidatos))])
       (expandir-grupos-stream grupos-curso-actual flujo-resto))]))