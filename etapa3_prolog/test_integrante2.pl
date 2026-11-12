:- ensure_loaded('politica.pl').
:- ensure_loaded('modelo.pl').
:- ensure_loaded('loader.pl').

ejecutar_pruebas_i2 :-
    writeln('============================================================='),
    writeln('  PRUEBA INTEGRAL ETAPA 3 - INTEGRANTE 2 (MODELO Y CARGA)    '),
    writeln('============================================================='),
    nl,
    probar_politicas,
    nl,
    probar_carga_y_modelo,
    nl,
    writeln('============================================================='),
    writeln('  Todas las pruebas del Integrante 2 finalizaron con exito!  '),
    writeln('=============================================================').

probar_politicas :-
    writeln('--- 1. VERIFICANDO PARAMETROS DE POLITICA (politica.pl) ---'),
    obtener_max_porcentaje_carrera('Ingeniería en Computadores', MaxComp),
    obtener_max_porcentaje_carrera('Ingeniería en Biotecnología', MaxBio),
    max_cursos_area(MaxArea),
    format('  * Max porcentaje Ingenieria en Computadores  : ~w%~n', [MaxComp]),
    format('  * Max porcentaje Ingenieria en Biotecnologia : ~w%~n', [MaxBio]),
    format('  * Limite N de cursos por area                : ~w~n', [MaxArea]),
    writeln('  * Verificando simetria de cursos incompatibles:'),
    (   cursos_incompatibles('FI1101', 'FI1105'),
        cursos_incompatibles('FI1105', 'FI1101')
    ->  writeln('    [OK] Simetria FI1101 <-> FI1105 verificada.')
    ;   writeln('    [ERROR] Fallo simetria FI1101 <-> FI1105.')
    ),
    (   cursos_incompatibles('PI2609', 'IB2113'),
        cursos_incompatibles('IB2113', 'PI2609')
    ->  writeln('    [OK] Simetria PI2609 <-> IB2113 verificada.')
    ;   writeln('    [ERROR] Fallo simetria PI2609 <-> IB2113.')
    ),
    (   cursos_incompatibles('CE1105', 'CE1107'),
        cursos_incompatibles('CE1107', 'CE1105')
    ->  writeln('    [OK] Simetria CE1105 <-> CE1107 verificada.')
    ;   writeln('    [ERROR] Fallo simetria CE1105 <-> CE1107.')
    ).

probar_carga_y_modelo :-
    writeln('--- 2. CARGANDO COMBINACIONES DE RACKET (loader.pl) ---'),
    inicializar_datos_entrada,
    findall(C, obtener_combinacion_cargada(C), ListaCombinaciones),
    length(ListaCombinaciones, TotalCombs),
    format('  * Total de combinaciones importadas desde JSON: ~w~n', [TotalCombs]),
    (   ListaCombinaciones = [PrimeraComb | _]
    ->  mostrar_detalle_combinacion(PrimeraComb)
    ;   writeln('  * Aviso: El archivo JSON no contiene combinaciones.')
    ).

mostrar_detalle_combinacion(Combinacion) :-
    writeln('--- 3. INSPECCIONANDO MODELADO DE LA COMBINACION #1 (modelo.pl) ---'),
    (   es_combinacion_valida(Combinacion)
    ->  writeln('  * Validacion estructural de termino compuesto: [OK]')
    ;   writeln('  * Validacion estructural de termino compuesto: [FALLO]')
    ),
    combinacion_id(Combinacion, Id),
    combinacion_total_creditos(Combinacion, TotalCred),
    combinacion_cursos(Combinacion, Cursos),
    extraer_pares_guion(Cursos, ParesGuion),
    carreras_presentes(Cursos, Carreras),
    areas_presentes(Cursos, Areas),
    contar_cursos_por_area(Cursos, 'Computadores', CantCompArea),
    creditos_por_carrera(Cursos, 'Ingeniería en Computadores', CredCompCarrera),
    format('  * ID Combinacion         : ~w~n', [Id]),
    format('  * Total Creditos         : ~w~n', [TotalCred]),
    format('  * Terminos curso/5       : ~w~n', [Cursos]),
    format('  * Pares Curso-Grupo      : ~w~n', [ParesGuion]),
    format('  * Carreras presentes     : ~w~n', [Carreras]),
    format('  * Areas presentes        : ~w~n', [Areas]),
    format('  * Cursos area Computadores: ~w~n', [CantCompArea]),
    format('  * Creditos Ing. Computad.: ~w~n', [CredCompCarrera]).
