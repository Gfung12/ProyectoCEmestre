#lang typed/racket

(require "types.rkt"
         "filters.rkt"
         "parser.rkt"
         "generator.rkt")

(printf "=====================================================\n")
(printf "   PRUEBA INTEGRAL ETAPA 2: CARGA Y GENERADOR       \n")
(printf "=====================================================\n\n")

;;CARGA DE ARCHIVOS DE ENTRADA
(printf "=== 1. CARGANDO CATÁLOGO DESDE C ===\n")
(define catalogo (load-catalog-from-json "../data/output_schedule.json"))
(printf "Total de cursos cargados en el catálogo: ~a\n\n" (length catalogo))

(printf "=== 2. CARGANDO PREFERENCIAS DEL ESTUDIANTE ===\n")
(define prefs (load-preferences-from-json "../data/preferencias.json"))
(printf "Rango de créditos deseados: [~a, ~a]\n" 
        (Preferences-min-credits prefs) 
        (Preferences-max-credits prefs))
(printf "Cursos de interés solicitados: ~a\n\n" 
        (length (Preferences-interested-courses prefs)))

;;CRUCE DE DATOS Y PREPARACIÓN DE CANDIDATOS
(printf "=== 3. CRUCE DE DATOS Y FILTRADO POLIMÓRFICO ===\n")
(define candidatos (prepare-candidate-courses catalogo prefs))
(printf "Cursos habilitados con grupos válidos para procesar: ~a\n\n" (length candidatos))

(printf "Detalle de los grupos candidatos preparados:\n")
(for ([curso-grupos : (Listof SelectedGroup) candidatos])
  (for ([opcion : SelectedGroup curso-grupos])
    (printf " - [~a] ~a | Grupo ~a | ~a créditos\n"
            (SelectedGroup-code opcion)
            (SelectedGroup-name opcion)
            (SelectedGroup-group-number opcion)
            (SelectedGroup-credits opcion))))

;;GENERACIÓN DE COMBINACIONES
(printf "\n=== 4. GENERACIÓN COMBINATORIA LIBRE DE CHOQUES ===\n")
(define combinaciones (generar-combinaciones candidatos))
(printf "Total de combinaciones válidas sin choques generadas: ~a\n\n" (length combinaciones))

(for ([comb : ScheduleCombination combinaciones] [i : Integer (in-naturals 1)])
  (printf "Combinación #~a (Créditos totales: ~a):\n" i (ScheduleCombination-total-credits comb))
  (for ([sel : SelectedGroup (ScheduleCombination-selections comb)])
    (printf "   - [~a] ~a (~a) | Grupo ~a | ~a créditos\n"
            (SelectedGroup-code sel)
            (SelectedGroup-name sel)
            (SelectedGroup-career sel)
            (SelectedGroup-group-number sel)
            (SelectedGroup-credits sel)))
  (printf "\n"))

(printf "======================================\n")
(printf " ¡Prueba completada con éxito! \n")
(printf "======================================\n")