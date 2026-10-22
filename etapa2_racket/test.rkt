#lang typed/racket

(require "types.rkt"
         "filters.rkt"
         "parser.rkt"
         "generator.rkt"
         "exporter.rkt")

(printf "=====================================================\n")
(printf "   PRUEBA INTEGRAL ETAPA 2: CARGA Y GENERADOR       \n")
(printf "=====================================================\n\n")

;;CARGA DE ARCHIVOS DE ENTRADA
(printf "=== 1. CARGANDO CATALOGO DESDE C ===\n")
(define catalogo (load-catalog-from-json "../data/output_schedule.json"))
(printf "Total de cursos cargados en el catalogo: ~a\n\n" (length catalogo))

(printf "=== 2. CARGANDO PREFERENCIAS DEL ESTUDIANTE ===\n")
(define prefs (load-preferences-from-json "../data/preferencias.json"))
(printf "Rango de creditos deseados: [~a, ~a]\n"
        (Preferences-min-credits prefs)
        (Preferences-max-credits prefs))
(printf "Cursos de interes solicitados: ~a\n\n"
        (length (Preferences-interested-courses prefs)))

;;CRUCE DE DATOS Y PREPARACION DE CANDIDATOS
(printf "=== 3. CRUCE DE DATOS Y FILTRADO POLIMORFICO ===\n")
(define candidatos (prepare-candidate-courses catalogo prefs))
(printf "Cursos habilitados con grupos validos para procesar: ~a\n\n" (length candidatos))

(printf "Detalle de los grupos candidatos preparados:\n")
(for ([curso-grupos : (Listof SelectedGroup) candidatos])
  (for ([opcion : SelectedGroup curso-grupos])
    (printf " - [~a] ~a | Grupo ~a | ~a creditos\n"
            (SelectedGroup-code opcion)
            (SelectedGroup-name opcion)
            (SelectedGroup-group-number opcion)
            (SelectedGroup-credits opcion))))

;;GENERACION DE COMBINACIONES
(printf "\n=== 4. GENERACION COMBINATORIA LIBRE DE CHOQUES ===\n")
(define combinaciones (generar-combinaciones candidatos))
(printf "Total de combinaciones validas sin choques generadas: ~a\n\n" (length combinaciones))

(for ([comb : ScheduleCombination combinaciones] [i : Integer (in-naturals 1)])
  (printf "Combinacion #~a (Creditos totales: ~a):\n" i (ScheduleCombination-total-credits comb))
  (for ([sel : SelectedGroup (ScheduleCombination-selections comb)])
    (printf "   - [~a] ~a (~a) | Grupo ~a | ~a creditos\n"
            (SelectedGroup-code sel)
            (SelectedGroup-name sel)
            (SelectedGroup-career sel)
            (SelectedGroup-group-number sel)
            (SelectedGroup-credits sel)))
  (printf "\n"))

;; === 5. EXPORTACION JSON ===
(printf "=== 5. EXPORTANDO A JSON ===\n")
(define flujo-inicial (list->lazy-stream combinaciones))
(define flujo-filtrado (filtrar-rango-creditos 
                         (Preferences-min-credits prefs) 
                         (Preferences-max-credits prefs) 
                         flujo-inicial))

(exportar-combinaciones-json "../data/horarios_finales.json" flujo-filtrado)
(printf "Archivo guardado en ../data/horarios_finales.json con exito.\n")

(printf "======================================\n")
(printf "  Prueba completada con exito! \n")
(printf "======================================\n")