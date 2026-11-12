% -----------------------------------------------------------------------------
% 1. DEFINICION DE TERMINOS COMPUESTOS DEL DOMINIO
% -----------------------------------------------------------------------------
% Representacion de un curso seleccionado dentro de una combinacion:
%   curso(Codigo, Grupo, Creditos, Carrera, Area)
%     - Codigo   : Atomo (ej. 'CE1107')
%     - Grupo    : Entero (ej. 1)
%     - Creditos : Entero (ej. 4)
%     - Carrera  : Atomo (ej. 'Ingeniería en Computadores')
%     - Area     : Atomo (ej. 'Computadores')
%
% Representacion de un bloque de horario y grupo del catalogo:
%   horario(Dia, HoraInicio, HoraFin)
%   grupo_horario(CodigoCurso, NumeroGrupo, ListaHorarios)
%
% Representacion de una combinacion de horario generada por Racket:
%   combinacion(Id, TotalCreditos, ListaCursos)
%     - Id            : Entero identificador (1..M)
%     - TotalCreditos : Entero con los creditos totales de la combinacion
%     - ListaCursos   : Lista de terminos curso(Codigo, Grupo, Creditos, Carrera, Area)
%
% Representacion de un par curso-grupo para exportacion:
%   par_curso_grupo(Codigo, Grupo)
%
% Representacion del veredicto de evaluacion (contrato hacia Java / Etapa 4):
%   resultado_combinacion(Id, TotalCreditos, ListaParesCursoGrupo, Cumple, Razon)

% -----------------------------------------------------------------------------
% 2. CONSTRUCTORES Y SELECTORES PUROS DE CURSO (curso/5)
% -----------------------------------------------------------------------------
crear_curso(Codigo, Grupo, Creditos, Carrera, Area,
            curso(Codigo, Grupo, Creditos, Carrera, Area)).

curso_codigo(curso(Codigo, _, _, _, _), Codigo).
curso_grupo(curso(_, Grupo, _, _, _), Grupo).
curso_creditos(curso(_, _, Creditos, _, _), Creditos).
curso_carrera(curso(_, _, _, Carrera, _), Carrera).
curso_area(curso(_, _, _, _, Area), Area).

es_curso_valido(curso(Codigo, Grupo, Creditos, Carrera, Area)) :-
    atom(Codigo),
    integer(Grupo), Grupo > 0,
    integer(Creditos), Creditos >= 0,
    atom(Carrera),
    atom(Area).

% -----------------------------------------------------------------------------
% 3. CONSTRUCTORES Y SELECTORES DE HORARIOS Y GRUPOS (horario/3, grupo_horario/3)
% -----------------------------------------------------------------------------
crear_horario(Dia, HoraInicio, HoraFin, horario(Dia, HoraInicio, HoraFin)).

horario_dia(horario(Dia, _, _), Dia).
horario_inicio(horario(_, HoraInicio, _), HoraInicio).
horario_fin(horario(_, _, HoraFin), HoraFin).

es_horario_valido(horario(Dia, HoraInicio, HoraFin)) :-
    integer(Dia), Dia >= 1, Dia =< 6,
    integer(HoraInicio), integer(HoraFin),
    HoraInicio < HoraFin.

crear_grupo_horario(Codigo, NumeroGrupo, Horarios,
                    grupo_horario(Codigo, NumeroGrupo, Horarios)).

grupo_horario_codigo(grupo_horario(Codigo, _, _), Codigo).
grupo_horario_numero(grupo_horario(_, NumeroGrupo, _), NumeroGrupo).
grupo_horario_bloques(grupo_horario(_, _, Horarios), Horarios).

% -----------------------------------------------------------------------------
% 4. CONSTRUCTORES Y SELECTORES DE COMBINACION (combinacion/3)
% -----------------------------------------------------------------------------
crear_combinacion(Id, TotalCreditos, ListaCursos,
                  combinacion(Id, TotalCreditos, ListaCursos)).

combinacion_id(combinacion(Id, _, _), Id).
combinacion_total_creditos(combinacion(_, TotalCreditos, _), TotalCreditos).
combinacion_cursos(combinacion(_, _, ListaCursos), ListaCursos).

es_combinacion_valida(combinacion(Id, TotalCreditos, ListaCursos)) :-
    integer(Id), Id > 0,
    integer(TotalCreditos), TotalCreditos >= 0,
    is_list(ListaCursos),
    todos_cursos_validos(ListaCursos).

todos_cursos_validos([]).
todos_cursos_validos([Curso | Resto]) :-
    es_curso_valido(Curso),
    todos_cursos_validos(Resto).

% -----------------------------------------------------------------------------
% 5. PREDICADOS AUXILIARES PUROS PARA REGLAS Y EXPORTACION (SIN ESTADO GLOBAL)
% -----------------------------------------------------------------------------

% Extrae la lista de terminos par_curso_grupo(Codigo, Grupo) desde ListaCursos.
% Usable tanto para construir la salida como para consultar pares.
extraer_pares_curso_grupo([], []).
extraer_pares_curso_grupo([curso(Codigo, Grupo, _, _, _) | RestoCursos],
                          [par_curso_grupo(Codigo, Grupo) | RestoPares]) :-
    extraer_pares_curso_grupo(RestoCursos, RestoPares).

% Extrae la lista de pares con notacion estandar Codigo-Grupo de Prolog.
extraer_pares_guion([], []).
extraer_pares_guion([curso(Codigo, Grupo, _, _, _) | RestoCursos],
                    [Codigo-Grupo | RestoPares]) :-
    extraer_pares_guion(RestoCursos, RestoPares).

% Extrae unicamente la lista de codigos de curso de una combinacion.
extraer_codigos_cursos([], []).
extraer_codigos_cursos([curso(Codigo, _, _, _, _) | Resto], [Codigo | RestoCodigos]) :-
    extraer_codigos_cursos(Resto, RestoCodigos).

% Calcula recursivamente el total de creditos de una lista de cursos.
sumar_creditos_cursos([], 0).
sumar_creditos_cursos([curso(_, _, Creditos, _, _) | Resto], Total) :-
    sumar_creditos_cursos(Resto, Subtotal),
    Total is Subtotal + Creditos.

% Filtra los cursos de una combinacion que pertenecen a una Carrera especifica.
cursos_por_carrera([], _Carrera, []).
cursos_por_carrera([Curso | Resto], Carrera, [Curso | Filtrados]) :-
    curso_carrera(Curso, Carrera), !,
    cursos_por_carrera(Resto, Carrera, Filtrados).
cursos_por_carrera([_Curso | Resto], Carrera, Filtrados) :-
    cursos_por_carrera(Resto, Carrera, Filtrados).

% Calcula el total de creditos pertenecientes a una Carrera dentro de ListaCursos.
creditos_por_carrera(ListaCursos, Carrera, CreditosCarrera) :-
    cursos_por_carrera(ListaCursos, Carrera, CursosDeCarrera),
    sumar_creditos_cursos(CursosDeCarrera, CreditosCarrera).

% Filtra los cursos de una combinacion que pertenecen a un Area especifica.
cursos_por_area([], _Area, []).
cursos_por_area([Curso | Resto], Area, [Curso | Filtrados]) :-
    curso_area(Curso, Area), !,
    cursos_por_area(Resto, Area, Filtrados).
cursos_por_area([_Curso | Resto], Area, Filtrados) :-
    cursos_por_area(Resto, Area, Filtrados).

% Cuenta cuantos cursos de una misma Area existen en ListaCursos.
contar_cursos_por_area(ListaCursos, Area, Cantidad) :-
    cursos_por_area(ListaCursos, Area, CursosDeArea),
    length(CursosDeArea, Cantidad).

% Obtiene la lista de carreras presentes en ListaCursos sin duplicados.
carreras_presentes(ListaCursos, CarrerasUnicas) :-
    extraer_carreras_raw(ListaCursos, CarrerasRaw),
    list_to_set(CarrerasRaw, CarrerasUnicas).

extraer_carreras_raw([], []).
extraer_carreras_raw([curso(_, _, _, Carrera, _) | Resto], [Carrera | RestoCarreras]) :-
    extraer_carreras_raw(Resto, RestoCarreras).

% Obtiene la lista de areas presentes en ListaCursos sin duplicados.
areas_presentes(ListaCursos, AreasUnicas) :-
    extraer_areas_raw(ListaCursos, AreasRaw),
    list_to_set(AreasRaw, AreasUnicas).

extraer_areas_raw([], []).
extraer_areas_raw([curso(_, _, _, _, Area) | Resto], [Area | RestoAreas]) :-
    extraer_areas_raw(Resto, RestoAreas).

% Predicado multimodo de pertenencia de curso en una combinacion:
% - Modo (+Curso, +Combinacion): verifica si un curso especifico esta en la combinacion.
% - Modo (-Curso, +Combinacion): genera por backtracking cada curso de la combinacion.
% - Modo (+Codigo, -Grupo, +Combinacion): usando miembro_curso_combinacion/4.
curso_en_combinacion(Curso, combinacion(_, _, ListaCursos)) :-
    member(Curso, ListaCursos).

miembro_curso_combinacion(Codigo, Grupo, Area, combinacion(_, _, ListaCursos)) :-
    member(curso(Codigo, Grupo, _, _, Area), ListaCursos).
