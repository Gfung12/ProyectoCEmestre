#lang typed/racket

(require racket/match
         "types.rkt"
         "filters.rkt")

;; Importamos el lector seguro con tipos limpios sin HashTables opacos
(require/typed "json_reader.rkt"
  [read-catalog-raw
   (-> Path-String
       (Listof (List String String String Integer Integer Boolean Boolean Boolean
                     (Listof String) (Listof String)
                     (Listof (List Integer Boolean (Listof (List Integer Integer Integer)))))))]
  [read-preferences-raw
   (-> Path-String
       (List Integer Integer (Listof (List String String (Listof Integer)))))])

(provide load-catalog-from-json
         load-preferences-from-json
         prepare-candidate-courses)

;; =========================================================================
;; CONVERSORES A STRUCTS INMUTABLES TIPADOS MEDIANTE PATTERN MATCHING
;; =========================================================================

(: raw->schedule-block (-> (List Integer Integer Integer) ScheduleBlock))
(define (raw->schedule-block raw)
  (match-define (list d s e) raw)
  (ScheduleBlock d s e))

(: raw->group (-> (List Integer Boolean (Listof (List Integer Integer Integer))) Group))
(define (raw->group raw)
  (match-define (list g-num clash scheds) raw)
  (Group g-num clash (map raw->schedule-block scheds)))

(: raw->course (-> (List String String String Integer Integer Boolean Boolean Boolean
                         (Listof String) (Listof String)
                         (Listof (List Integer Boolean (Listof (List Integer Integer Integer)))))
                   Course))
(define (raw->course raw)
  (match-define (list c-code c-name c-career c-credits c-semester
                      c-approved c-eligible c-any-clash
                      c-prereqs c-coreqs c-groups) raw)
  (Course c-code
          c-name
          c-career
          c-credits
          c-semester
          c-approved
          c-eligible
          c-any-clash
          c-prereqs
          c-coreqs
          (map raw->group c-groups)))

(: load-catalog-from-json (-> Path-String (Listof Course)))
(define (load-catalog-from-json filepath)
  (map raw->course (read-catalog-raw filepath)))

(: raw->interested-course (-> (List String String (Listof Integer)) InterestedCourse))
(define (raw->interested-course raw)
  (match-define (list i-code i-career i-groups) raw)
  (InterestedCourse i-code i-career i-groups))

(: load-preferences-from-json (-> Path-String Preferences))
(define (load-preferences-from-json filepath)
  (match-define (list min-c max-c interested-raw) (read-preferences-raw filepath))
  (Preferences min-c max-c (map raw->interested-course interested-raw)))

;; =========================================================================
;; CRUCE DE DATOS CON POLIMORFISMO PARAMÉTRICO
;; =========================================================================

(: prepare-candidate-courses (-> (Listof Course) Preferences (Listof (Listof SelectedGroup))))
(define (prepare-candidate-courses catalog prefs)
  (define eligible-courses
    (filtrar-lista-polimorfico
     (lambda ([c : Course]) (Course-is-eligible c))
     catalog))

  (define grouped-options
    (map
     (lambda ([interest : InterestedCourse])
       (define matching-courses
         (filtrar-lista-polimorfico
          (lambda ([c : Course])
            (and (string=? (Course-code c) (InterestedCourse-code interest))
                 (or (string=? (InterestedCourse-career interest) "")
                     (string=? (Course-career c) (InterestedCourse-career interest)))))
          eligible-courses))

       (if (null? matching-courses)
           '()
           (let ([course (car matching-courses)])
             (define matching-groups
               (filtrar-lista-polimorfico
                (lambda ([g : Group])
                  (not (false? (member (Group-group-number g)
                                       (InterestedCourse-groups interest)))))
                (Course-groups course)))

             (map (lambda ([g : Group])
                    (SelectedGroup
                     (Course-code course)
                     (Course-name course)
                     (Course-career course)
                     (Course-credits course)
                     (Group-group-number g)
                     (Group-has-clash g)
                     (Group-schedules g)))
                  matching-groups))))
     (Preferences-interested-courses prefs)))

  (filtrar-lista-polimorfico
   (lambda ([lst : (Listof SelectedGroup)]) (not (null? lst)))
   grouped-options))