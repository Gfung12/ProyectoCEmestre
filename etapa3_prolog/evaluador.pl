% EVALUADOR.PL - Motor de Decisión 
% Depende de: reglas.pl, modelo.pl y los hechos cargados 


% es_valida verifica que la combinación no rompa ninguna regla.
es_valida(ListaCursos, TotalCreditos) :-
    \+ rompe_incompatibilidad(ListaCursos, _, _),
    \+ rompe_balance_carrera(ListaCursos, TotalCreditos, _, _, _),
    \+ rompe_limite_area(ListaCursos, _, _, _).


% EVALUACIÓN CON CORTES (!) Y ORDEN DE CLÁUSULAS
% Caso 1: La combinación es perfecta.
evaluar_combinacion(ListaCursos, TotalCreditos, aprobada, ninguna) :-
    es_valida(ListaCursos, TotalCreditos),
    !.

% Caso 2: Falla por incompatibilidad (Prioridad 1 en errores)
evaluar_combinacion(ListaCursos, _, rechazada, incompatibilidad(Cod1, Cod2)) :-
    rompe_incompatibilidad(ListaCursos, Cod1, Cod2),
    !.

% Caso 3: Falla por balance de carrera (Prioridad 2 en errores)
evaluar_combinacion(ListaCursos, TotalCreditos, rechazada, balance_carrera(Carrera, Pct, MaxPct)) :-
    rompe_balance_carrera(ListaCursos, TotalCreditos, Carrera, Pct, MaxPct),
    !. 

% Caso 4: Falla por límite de área (Prioridad 3 en errores)
evaluar_combinacion(ListaCursos, _, rechazada, limite_area(Area, Cant, Max)) :-
    rompe_limite_area(ListaCursos, Area, Cant, Max),
    !.


% PROCESAMIENTO EN LOTE (BACKTRACKING)
% evaluar_todas(-Resultados)
evaluar_todas(Resultados) :-
    findall(
        resultado(Id, Estado, Razon),
        (
            combinacion_entrada(Id, TotalCreditos, ListaCursos),
            evaluar_combinacion(ListaCursos, TotalCreditos, Estado, Razon)
        ),
        Resultados
    ).




