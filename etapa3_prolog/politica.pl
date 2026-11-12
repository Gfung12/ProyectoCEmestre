:- discontiguous max_porcentaje_carrera/2.
:- discontiguous max_cursos_area/1.
:- discontiguous incompatible_directo/2.

% -----------------------------------------------------------------------------
% 1. BALANCE ENTRE CARRERAS (Porcentaje maximo de creditos por carrera)
% -----------------------------------------------------------------------------
% Formato: max_porcentaje_carrera(Carrera, PorcentajeMaximo).
% - Una combinacion incumple la regla si alguna carrera supera su maximo.
% - Una combinacion con cursos de una sola carrera (100% de los creditos)
%   es valida mientras no supere el maximo aqui configurado (por ejemplo, 100).
%   Si se desea forzar horarios mixtos entre carreras en pruebas, basta con
%   bajar este valor (ej. a 75 o 80).

max_porcentaje_carrera('Ingeniería en Computadores', 100).
max_porcentaje_carrera('Ingeniería en Biotecnología', 100).

% Alias cortos opcionales por si en consultas manuales se omite "Ingeniería en "
max_porcentaje_carrera('Computadores', 100).
max_porcentaje_carrera('Biotecnología', 100).

% Predicado auxiliar para consultar el porcentaje maximo normalizando texto/atomo
obtener_max_porcentaje_carrera(Carrera, MaxPorcentaje) :-
    normalizar_parametro_pol(Carrera, CarreraAtomo),
    max_porcentaje_carrera(CarreraAtomo, MaxPorcentaje).

% -----------------------------------------------------------------------------
% 2. LIMITE POR AREA (Maximo N de cursos de una misma area por combinacion)
% -----------------------------------------------------------------------------
% Formato: max_cursos_area(N).
% Define el numero maximo N de cursos permitidos de una misma area tematica
% dentro de una misma combinacion de horario.

max_cursos_area(2).

% Predicado parametrizado de consulta (compatible con consulta global o por area)
limite_cursos_area(_Area, N) :-
    max_cursos_area(N).

% -----------------------------------------------------------------------------
% 3. INCOMPATIBILIDAD DE CURSOS (Pares prohibidos declarados de forma simetrica)
% -----------------------------------------------------------------------------
% Formato base: incompatible_directo(CodigoCurso1, CodigoCurso2).
% Se declaran al menos dos pares identificados en los planes de estudio de
% Ingenieria en Computadores e Ingenieria en Biotecnologia:
%
% Par 1 (Inter-carrera): FI1101 (Fisica General I - Computadores) y
%        FI1105 (Fisica Para Biotecnologia - Biotecnologia).
%        Justificacion: Equivalencia de contenidos de mecanica clasica base.
%
% Par 2 (Inter-carrera): PI2609 (Probabilidad y Estadistica - Computadores) y
%        IB2113 (Analisis Estadistico Para Biotecnologia - Biotecnologia).
%        Justificacion: Solapamiento tematico en probabilidad e inferencia.
%
% Par 3 (Inter-carrera): CI1407 (Habilidades de Comunicacion en Ingenieria) y
%        CI1106 (Comunicacion Escrita - Biotecnologia).
%        Justificacion: Equivalencia curricular en redaccion tecnica inicial.
%
% Par 4 (Intra-carrera para pruebas de rechazo sobre horarios_finales.json):
%        CE1105 (Principios de Modelado en Ingenieria - Semestre 2) y
%        CE1107 (Fundamentos de Arquitectura de Computadores - Semestre 5).
%        Justificacion: Par de distintos niveles para verificar el rechazo y
%        demostrar como el orden de las reglas cambia la razon reportada.

incompatible_directo('FI1101', 'FI1105').
incompatible_directo('PI2609', 'IB2113').
incompatible_directo('CI1407', 'CI1106').
incompatible_directo('CE1105', 'CE1107').

% Regla simetrica de incompatibilidad:
% Funciona en multiples modos de consulta:
%   - Modo (+, +): verifica si dos cursos son incompatibles sin importar el orden.
%   - Modo (+, -): obtiene todos los cursos incompatibles con CursoA.
%   - Modo (-, -): enumera todos los pares incompatibles en ambas direcciones.
cursos_incompatibles(CursoA, CursoB) :-
    normalizar_parametro_pol(CursoA, AtomoA),
    normalizar_parametro_pol(CursoB, AtomoB),
    par_incompatible_simetrico(AtomoA, AtomoB).

par_incompatible_simetrico(AtomoA, AtomoB) :-
    incompatible_directo(AtomoA, AtomoB).
par_incompatible_simetrico(AtomoA, AtomoB) :-
    incompatible_directo(AtomoB, AtomoA).

% -----------------------------------------------------------------------------
% Utilidad interna para aceptar tanto atomos como strings sin romper variables
% -----------------------------------------------------------------------------
normalizar_parametro_pol(Var, Var) :-
    var(Var), !.
normalizar_parametro_pol(Str, Atomo) :-
    string(Str), !,
    atom_string(Atomo, Str).
normalizar_parametro_pol(Atomo, Atomo) :-
    atom(Atomo).
