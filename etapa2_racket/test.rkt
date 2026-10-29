#lang typed/racket

(require "types.rkt"
         "filters.rkt"
         "parser.rkt"
         "generator.rkt"
         "exporter.rkt")

(: imprimir-grupos-candidatos (-> (Listof (Listof SelectedGroup)) Void))
(define (imprimir-grupos-candidatos candidatos)
  (cond
    [(null? candidatos) (void)]
    [else
     (imprimir-opciones-grupo (car candidatos))
     (imprimir-grupos-candidatos (cdr candidatos))]))

(: imprimir-opciones-grupo (-> (Listof SelectedGroup) Void))
(define (imprimir-opciones-grupo opciones)
  (cond
    [(null? opciones) (void)]
    [else
     (let ([opcion (car opciones)])
       (printf " - [~a] ~a | Grupo ~a | ~a creditos\n"
               (SelectedGroup-code opcion)
               (SelectedGroup-name opcion)
               (SelectedGroup-group-number opcion)
               (SelectedGroup-credits opcion))
       (imprimir-opciones-grupo (cdr opciones)))]))

(: imprimir-selecciones (-> (Listof SelectedGroup) Void))
(define (imprimir-selecciones selecciones)
  (cond
    [(null? selecciones) (void)]
    [else
     (let ([sel (car selecciones)])
       (printf "   - [~a] ~a (~a) | Grupo ~a | ~a creditos\n"
               (SelectedGroup-code sel)
               (SelectedGroup-name sel)
               (SelectedGroup-career sel)
               (SelectedGroup-group-number sel)
               (SelectedGroup-credits sel))
       (imprimir-selecciones (cdr selecciones)))]))

(: imprimir-stream-combinaciones (-> (LazyStream ScheduleCombination) Integer Integer))
(define (imprimir-stream-combinaciones flujo contador)
  (cond
    [(null? flujo) (- contador 1)]
    [else
     (let ([comb (StreamNode-first flujo)])
       (printf "Combinacion #~a (Creditos totales: ~a):\n"
               contador
               (ScheduleCombination-total-credits comb))
       (imprimir-selecciones (ScheduleCombination-selections comb))
       (printf "\n")
       (imprimir-stream-combinaciones (force (StreamNode-rest flujo)) (+ contador 1)))]))

(printf "=====================================================\n")
(printf "   PRUEBA INTEGRAL ETAPA 2: CARGA Y GENERADOR       \n")
(printf "=====================================================\n\n")

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

(printf "=== 3. CRUCE DE DATOS Y FILTRADO POLIMORFICO ===\n")
(define candidatos (prepare-candidate-courses catalogo prefs))
(printf "Cursos habilitados con grupos validos para procesar: ~a\n\n" (length candidatos))

(printf "Detalle de los grupos candidatos preparados:\n")
(imprimir-grupos-candidatos candidatos)

(printf "\n=== 4. GENERACION LAZY STREAM Y FILTRADO DE CREDITOS ===\n")
(define flujo-combinaciones (generar-combinaciones candidatos))
(define flujo-filtrado
  (filtrar-rango-creditos
   (Preferences-min-credits prefs)
   (Preferences-max-credits prefs)
   flujo-combinaciones))

(define total-validas (imprimir-stream-combinaciones flujo-filtrado 1))
(printf "Total de combinaciones validas en rango de creditos: ~a\n\n" total-validas)

(printf "=== 5. EXPORTANDO A JSON ===\n")
(exportar-combinaciones-json "../data/horarios_finales.json" flujo-filtrado)
(printf "Archivo guardado en ../data/horarios_finales.json con exito.\n")

(printf "======================================\n")
(printf "  Prueba completada con exito! \n")
(printf "======================================\n")