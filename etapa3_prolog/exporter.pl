% EXPORTER.PL - Serialización a JSON (Integrante 3)
% Depende de: evaluador.pl, modelo.pl y library(http/json)

:- use_module(library(json)).

% 1. TRANSFORMACIÓN DE DATOS (Mapeo a Diccionarios)
% Convierte el estado interno a booleano para el JSON
estado_bool(aprobada, true).
estado_bool(rechazada, false).


% Formatea las razones complejas a Strings legibles para el usuario/Java
formatear_razon(ninguna, "Ninguna").
formatear_razon(incompatibilidad(C1, C2), String) :-
    format(string(String), "Cursos incompatibles: ~w y ~w", [C1, C2]).
formatear_razon(balance_carrera(Carrera, Pct, MaxPct), String) :-
    format(string(String), "Excede balance en ~w: ~2f% > ~2f%", [Carrera, Pct, MaxPct]).
formatear_razon(limite_area(Area, Cant, Max), String) :-
    format(string(String), "Excede limite en area ~w: ~w > ~w", [Area, Cant, Max]).


% Extrae solo el código y grupo de la lista completa de cursos
extraer_pares_json([], []).
extraer_pares_json([Curso|Resto], [_{codigo: Codigo, grupo: Grupo} | ParesResto]) :-
    curso_codigo(Curso, Codigo),
    curso_grupo(Curso, Grupo),
    extraer_pares_json(Resto, ParesResto).


% Convierte el término resultado(Id, Estado, Razon) en un dict JSON
resultado_a_dict(resultado(Id, Estado, Razon), Dict) :-
    estado_bool(Estado, CumpleBooleano),
    formatear_razon(Razon, RazonStr),
    combinacion_entrada(Id, _, ListaCursos),
    extraer_pares_json(ListaCursos, CursosExport),
    % Construye el diccionario
    Dict = _{
        id_combinacion: Id,
        cumple_politicas: CumpleBooleano,
        razon: RazonStr,
        cursos: CursosExport
    }.


% 2. EXPORTACIÓN A ARCHIVO
% exportar_resultados(+RutaArchivo)
exportar_resultados(RutaArchivo) :-
    evaluar_todas(ResultadosCrudos),
    maplist(resultado_a_dict, ResultadosCrudos, ListaDictsJSON),
    
    % Abre el archivo, escribe el JSON y cierra seguro
    open(RutaArchivo, write, Stream),
    json_write_dict(Stream, ListaDictsJSON, [width(120)]),
    close(Stream).




