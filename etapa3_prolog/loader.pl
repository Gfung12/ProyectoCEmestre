:- use_module(library(json)).
:- ensure_loaded('politica.pl').
:- ensure_loaded('modelo.pl').

% Hechos dinamicos EXCLUSIVOS para almacenar datos de entrada cargados
:- dynamic combinacion_entrada/3.
:- dynamic combinacion_hecho/1.
:- dynamic grupo_catalogo_entrada/3.

% -----------------------------------------------------------------------------
% 1. CARGA DE POLITICA ACADEMICA (consult)
% -----------------------------------------------------------------------------
% Permite recargar o cambiar el archivo de hechos de politica en cualquier
% momento (por ejemplo, durante la defensa).
cargar_politica(RutaArchivoPolitica) :-
    resolver_ruta_archivo(RutaArchivoPolitica, RutaReal),
    consult(RutaReal).

% -----------------------------------------------------------------------------
% 2. LECTURA ESTRUCTURADA DE COMBINACIONES DESDE JSON (POR UNIFICACION)
% -----------------------------------------------------------------------------
% cargar_combinaciones_json(+RutaJSON, -ListaCombinaciones)
% Lee el archivo JSON generado por Racket y unifica ListaCombinaciones con
% una lista de terminos compuestos:
%   [combinacion(1, TotalCreditos1, [curso(...), ...]), ...]
cargar_combinaciones_json(RutaJSON, ListaCombinaciones) :-
    resolver_ruta_archivo(RutaJSON, RutaReal),
    setup_call_cleanup(
        open(RutaReal, read, Stream, [encoding(utf8)]),
        json_read_dict(Stream, DatosJSON, [value_string_as(atom)]),
        close(Stream)
    ),
    transformar_lista_combinaciones(DatosJSON, 1, ListaCombinaciones).

% Transforma recursivamente la lista de diccionarios JSON en terminos combinacion/3
transformar_lista_combinaciones([], _IdActual, []).
transformar_lista_combinaciones([DictComb | RestoDicts], IdActual,
                                [CombinacionTerm | RestoTerminos]) :-
    extraer_campo_json(DictComb, total_credits, 0, TotalCreditosRaw),
    asegurar_entero(TotalCreditosRaw, TotalCreditos),
    extraer_campo_json(DictComb, selections, [], SeleccionesJSON),
    transformar_lista_cursos(SeleccionesJSON, ListaCursos),
    crear_combinacion(IdActual, TotalCreditos, ListaCursos, CombinacionTerm),
    SiguienteId is IdActual + 1,
    transformar_lista_combinaciones(RestoDicts, SiguienteId, RestoTerminos).

% Transforma recursivamente cada elemento de "selections" en un termino curso/5
transformar_lista_cursos([], []).
transformar_lista_cursos([DictCurso | RestoDicts], [CursoTerm | RestoCursos]) :-
    extraer_campo_json(DictCurso, course_code, '', CodigoRaw),
    extraer_campo_json(DictCurso, group_number, 1, GrupoRaw),
    extraer_campo_json(DictCurso, credits, 0, CreditosRaw),
    extraer_campo_json(DictCurso, career, '', CarreraRaw),
    extraer_campo_json(DictCurso, area, '', AreaRaw),
    asegurar_atomo(CodigoRaw, Codigo),
    asegurar_entero(GrupoRaw, Grupo),
    asegurar_entero(CreditosRaw, Creditos),
    asegurar_atomo(CarreraRaw, Carrera),
    asegurar_atomo(AreaRaw, Area),
    crear_curso(Codigo, Grupo, Creditos, Carrera, Area, CursoTerm),
    transformar_lista_cursos(RestoDicts, RestoCursos).

% -----------------------------------------------------------------------------
% 3. REGISTRO EN BASE DE CONOCIMIENTOS DE ENTRADA (PARA BACKTRACKING DIRECTO)
% -----------------------------------------------------------------------------
% Limpia cualquier carga previa de datos de entrada
limpiar_datos_entrada :-
    retractall(combinacion_entrada(_, _, _)),
    retractall(combinacion_hecho(_)),
    retractall(grupo_catalogo_entrada(_, _, _)).

% cargar_datos_entrada(+RutaJSON)
% Importa todas las combinaciones de Racket y las registra como hechos de entrada
% combinacion_entrada(Id, TotalCreditos, ListaCursos) y
% combinacion_hecho(combinacion(Id, TotalCreditos, ListaCursos)).
cargar_datos_entrada(RutaJSON) :-
    limpiar_datos_entrada,
    cargar_combinaciones_json(RutaJSON, ListaCombinaciones),
    registrar_combinaciones_entrada(ListaCombinaciones).

registrar_combinaciones_entrada([]).
registrar_combinaciones_entrada([combinacion(Id, TotalCreditos, ListaCursos) | Resto]) :-
    assertz(combinacion_entrada(Id, TotalCreditos, ListaCursos)),
    assertz(combinacion_hecho(combinacion(Id, TotalCreditos, ListaCursos))),
    registrar_combinaciones_entrada(Resto).

% Atajo por defecto que carga '../data/horarios_finales.json'
inicializar_datos_entrada :-
    cargar_datos_entrada('../data/horarios_finales.json').

% Predicado generador para que el Integrante 3 recorra por backtracking todas
% las combinaciones cargadas sin importar cual predicado prefiera invocar:
obtener_combinacion_cargada(Id, TotalCreditos, ListaCursos) :-
    combinacion_entrada(Id, TotalCreditos, ListaCursos).

obtener_combinacion_cargada(combinacion(Id, TotalCreditos, ListaCursos)) :-
    combinacion_entrada(Id, TotalCreditos, ListaCursos).

% -----------------------------------------------------------------------------
% 4. CARGA OPCIONAL DE HORARIOS DEL CATALOGO (output_schedule.json)
% -----------------------------------------------------------------------------
% Permite importar los bloques horario(Dia, Inicio, Fin) de cada grupo desde
% el JSON exportado por C si se desea consultar horarios detallados en Prolog.
cargar_horarios_catalogo(RutaCatalogoJSON) :-
    resolver_ruta_archivo(RutaCatalogoJSON, RutaReal),
    retractall(grupo_catalogo_entrada(_, _, _)),
    setup_call_cleanup(
        open(RutaReal, read, Stream, [encoding(utf8)]),
        json_read_dict(Stream, CursosJSON, [value_string_as(atom)]),
        close(Stream)
    ),
    registrar_grupos_catalogo(CursosJSON).

registrar_grupos_catalogo([]).
registrar_grupos_catalogo([DictCurso | Resto]) :-
    extraer_campo_json(DictCurso, code, '', CodigoRaw),
    asegurar_atomo(CodigoRaw, Codigo),
    extraer_campo_json(DictCurso, groups, [], GruposJSON),
    registrar_grupos_de_curso(Codigo, GruposJSON),
    registrar_grupos_catalogo(Resto).

registrar_grupos_de_curso(_Codigo, []).
registrar_grupos_de_curso(Codigo, [DictGrupo | Resto]) :-
    extraer_campo_json(DictGrupo, group_number, 1, NumGrupoRaw),
    asegurar_entero(NumGrupoRaw, NumGrupo),
    extraer_campo_json(DictGrupo, schedules, [], HorariosJSON),
    transformar_bloques_horario(HorariosJSON, ListaHorarios),
    assertz(grupo_catalogo_entrada(Codigo, NumGrupo, ListaHorarios)),
    registrar_grupos_de_curso(Codigo, Resto).

transformar_bloques_horario([], []).
transformar_bloques_horario([DictH | Resto], [HorarioTerm | RestoTerminos]) :-
    extraer_campo_json(DictH, day, 1, DiaRaw),
    extraer_campo_json(DictH, start_time, 700, InicioRaw),
    extraer_campo_json(DictH, end_time, 850, FinRaw),
    asegurar_entero(DiaRaw, Dia),
    asegurar_entero(InicioRaw, Inicio),
    asegurar_entero(FinRaw, Fin),
    crear_horario(Dia, Inicio, Fin, HorarioTerm),
    transformar_bloques_horario(Resto, RestoTerminos).

% -----------------------------------------------------------------------------
% 5. UTILIDADES DE RESOLUCION DE RUTAS Y CONVERSION DE TIPOS
% -----------------------------------------------------------------------------
% Resuelve la ruta del archivo ya sea que swipl se ejecute desde etapa3_prolog/
% o desde la raiz del repositorio ProyectoCEmestre-Parte3/.
resolver_ruta_archivo(RutaSolicitada, RutaSolicitada) :-
    exists_file(RutaSolicitada), !.
resolver_ruta_archivo('../data/horarios_finales.json', 'data/horarios_finales.json') :-
    exists_file('data/horarios_finales.json'), !.
resolver_ruta_archivo('../data/horarios_finales.json', 'horarios_finales.json') :-
    exists_file('horarios_finales.json'), !.
resolver_ruta_archivo('../data/output_schedule.json', 'data/output_schedule.json') :-
    exists_file('data/output_schedule.json'), !.
resolver_ruta_archivo('politica.pl', 'etapa3_prolog/politica.pl') :-
    exists_file('etapa3_prolog/politica.pl'), !.
resolver_ruta_archivo(RutaSolicitada, RutaSolicitada).

% Extrae de forma segura una llave de un dict JSON de SWI-Prolog
extraer_campo_json(Dict, Llave, _ValorPorDefecto, Valor) :-
    is_dict(Dict),
    get_dict(Llave, Dict, Valor), !.
extraer_campo_json(_Dict, _Llave, ValorPorDefecto, ValorPorDefecto).

asegurar_atomo(Valor, Valor) :-
    atom(Valor), !.
asegurar_atomo(Valor, Atomo) :-
    string(Valor), !,
    atom_string(Atomo, Valor).
asegurar_atomo(Valor, Atomo) :-
    number(Valor), !,
    atom_number(Atomo, Valor).

asegurar_entero(Valor, Valor) :-
    integer(Valor), !.
asegurar_entero(Valor, Entero) :-
    number(Valor), !,
    Entero is round(Valor).
asegurar_entero(Valor, Entero) :-
    atom(Valor),
    atom_number(Valor, Num), !,
    Entero is round(Num).
asegurar_entero(Valor, Entero) :-
    string(Valor),
    number_string(Num, Valor), !,
    Entero is round(Num).
asegurar_entero(_, 0).
