% REGLAS.PL - Lógica de Validación de Políticas 
% Depende de: modelo.pl y politica.pl


% 1. PREDICADO MULTIMODO 
filtrar_por_carrera([], _, []).

filtrar_por_carrera([Curso|Resto], Carrera, [Curso|RestoFiltrados]) :-
    curso_carrera(Curso, Carrera),
    filtrar_por_carrera(Resto, Carrera, RestoFiltrados).

filtrar_por_carrera([Curso|Resto], Carrera, RestoFiltrados) :-
    curso_carrera(Curso, OtraCarrera),
    Carrera \= OtraCarrera,
    filtrar_por_carrera(Resto, Carrera, RestoFiltrados).


% Predicado auxiliar: Sumar créditos de una lista de cursos
suma_creditos([], 0).
suma_creditos([Curso|Resto], Total) :-
    curso_creditos(Curso, Creds),
    suma_creditos(Resto, SubTotal),
    Total is Creds + SubTotal.


% Predicado auxiliar: Contar cursos de un área específica
contar_por_area([], _, 0).
contar_por_area([Curso|Resto], Area, Total) :-
    curso_area(Curso, Area),
    contar_por_area(Resto, Area, SubTotal),
    Total is SubTotal + 1.
contar_por_area([Curso|Resto], Area, Total) :-
    curso_area(Curso, OtraArea),
    Area \= OtraArea,
    contar_por_area(Resto, Area, Total).


% REGLA 1: Incompatibilidad entre cursos
% Da 'true' (falla la validación) si la combinación tiene dos cursos incompatibles.
rompe_incompatibilidad(ListaCursos, Cod1, Cod2) :-
    member(Curso1, ListaCursos),
    member(Curso2, ListaCursos),
    Curso1 \= Curso2,               % Asegura que no estemos comparando el mismo curso consigo mismo
    curso_codigo(Curso1, Cod1),
    curso_codigo(Curso2, Cod2),
    cursos_incompatibles(Cod1, Cod2).


% REGLA 2: Límite de cursos por área
% Da 'true' si el conteo de cursos de una misma área supera el máximo N.
rompe_limite_area(ListaCursos, Area, Cantidad, MaxPermitido) :-
    member(Curso, ListaCursos),
    curso_area(Curso, Area),
    contar_por_area(ListaCursos, Area, Cantidad),
    max_cursos_area(MaxPermitido),
    Cantidad > MaxPermitido.


% REGLA 3: Balance por carrera (Porcentaje máximo de créditos)
% Da 'true' si el porcentaje de créditos de una carrera supera el límite.
rompe_balance_carrera(ListaCursos, TotalCreditosCombinacion, Carrera, Porcentaje, MaxPorcentaje) :-
    member(Curso, ListaCursos),
    curso_carrera(Curso, Carrera),
    max_porcentaje_carrera(Carrera, MaxPorcentaje),
    filtrar_por_carrera(ListaCursos, Carrera, CursosCarrera),
    suma_creditos(CursosCarrera, CreditosCarrera),
    TotalCreditosCombinacion > 0,
    Porcentaje is (CreditosCarrera / TotalCreditosCombinacion) * 100,
    Porcentaje > MaxPorcentaje.



