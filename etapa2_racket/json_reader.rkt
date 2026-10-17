#lang racket

(require json)

(provide read-catalog-raw
         read-preferences-raw)

;; Lee output_schedule.json y extrae solo listas y valores atómicos
(define (read-catalog-raw filepath)
  (call-with-input-file filepath
    (lambda (in)
      (define data (read-json in))
      (if (list? data)
          (map
           (lambda (c)
             (list
              (hash-ref c 'code "")
              (hash-ref c 'name "")
              (hash-ref c 'career "")
              (hash-ref c 'credits 0)
              (hash-ref c 'semester 0)
              (hash-ref c 'is_approved #f)
              (hash-ref c 'is_eligible #f)
              (hash-ref c 'has_any_schedule_clash #f)
              (hash-ref c 'prerequisites '())
              (hash-ref c 'corequisites '())
              (map
               (lambda (g)
                 (list
                  (hash-ref g 'group_number 0)
                  (hash-ref g 'has_clash #f)
                  (map
                   (lambda (s)
                     (list
                      (hash-ref s 'day 0)
                      (hash-ref s 'start_time 0)
                      (hash-ref s 'end_time 0)))
                   (hash-ref g 'schedules '()))))
               (hash-ref c 'groups '()))))
           data)
          '()))))

;; Lee preferencias.json y extrae listas simples
(define (read-preferences-raw filepath)
  (call-with-input-file filepath
    (lambda (in)
      (define data (read-json in))
      (if (hash? data)
          (list
           (hash-ref data 'min_credits 0)
           (hash-ref data 'max_credits 0)
           (map
            (lambda (i)
              (list
               (hash-ref i 'code "")
               (hash-ref i 'career "")
               (hash-ref i 'groups '())))
            (hash-ref data 'interested_courses '())))
          (list 0 0 '())))))