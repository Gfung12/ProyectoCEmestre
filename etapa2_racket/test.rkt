#lang typed/racket

(require "types.rkt"
         "filters.rkt"
         "parser.rkt")

(printf "=== 1. CARGANDO CATÁLOGO DESDE C ===\n")
(define catalogo (load-catalog-from-json "../data/output_schedule.json"))
(printf "Total de cursos cargados: ~a\n\n" (length catalogo))

(printf "=== 2. CARGANDO PREFERENCIAS DEL ESTUDIANTE ===\n")
(define prefs (load-preferences-from-json "../data/preferencias.json"))
(printf "Rango de créditos deseados: [~a, ~a]\n" 
        (Preferences-min-credits prefs) 
        (Preferences-max-credits prefs))
(printf "Cursos de interés solicitados: ~a\n\n" 
        (length (Preferences-interested-courses prefs)))

(printf "=== 3. CRUCE DE DATOS Y FILTRADO POLIMÓRFICO ===\n")
(define candidatos (prepare-candidate-courses catalogo prefs))
(printf "Cursos que sí están habilitados y tienen grupos válidos: ~a\n" (length candidatos))

(printf "\nDetalle de las opciones preparadas para el generador:\n")
(for ([curso-grupos : (Listof SelectedGroup) candidatos])
  (for ([opcion : SelectedGroup curso-grupos])
    (printf " - [~a] ~a | Grupo ~a | ~a créditos\n"
            (SelectedGroup-code opcion)
            (SelectedGroup-name opcion)
            (SelectedGroup-group-number opcion)
            (SelectedGroup-credits opcion))))

(printf "\n¡Todo cargó, parseó y cruzó al 100%% sin errores de tipos!\n")