% MAIN.PL
% Une todos los módulos y ejecuta el flujo de inicio a fin.

% 1. Carga de todos los módulos en el orden correcto
:- consult('politica.pl').     % Parámetros y hechos configurables
:- consult('modelo.pl').       % Términos compuestos y selectores
:- consult('loader.pl').       % Lectura y parseo del JSON de entrada
:- consult('reglas.pl').       % Lógica de reglas y predicado multimodo
:- consult('evaluador.pl').    % Motor de decisión con cortes y negación
:- consult('exporter.pl').     % Serialización del resultado JSON

main :-
    write('======================================================'), nl,
    write(' INICIANDO EVALUADOR DE POLITICAS (ETAPA 3 - PROLOG)  '), nl,
    write('======================================================'), nl,
    
    RutaEntrada = '../data/horarios_finales.json',
    RutaSalida = '../data/resultado_politicas.json',
    
    % Paso A: Limpiar memoria por si se ejecuta varias veces en la misma sesión
    retractall(combinacion_entrada(_, _, _)),
    
    % Paso B: Cargar datos (Llamada al módulo loader.pl que hará el Integrante 2)
    write('-> Cargando combinaciones generadas por Racket...'), nl,
    cargar_datos_entrada(RutaEntrada),
    
    % Paso C: Evaluar todo y exportar (Llamada al módulo exporter.pl)
    write('-> Evaluando políticas académicas y escribiendo JSON...'), nl,
    exportar_resultados(RutaSalida),
    
    write('======================================================'), nl,
    write(' EXITO: Archivo generado en: ../data/resultado_politicas.json'), nl,
    write('======================================================'), nl.

