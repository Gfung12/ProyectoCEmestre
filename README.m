# CEmestre: Constructor Inteligente de Horarios

<p align="center">
  <img src="https://img.shields.io/badge/Curso-CE1106%20Paradigmas%20de%20Programaci%C3%B3n-0052cc?style=for-the-badge" alt="Curso" />
  <img src="https://img.shields.io/badge/Instituci%C3%B3n-Instituto%20Tecnol%C3%B3gico%20de%20Costa%20Rica-00758f?style=for-the-badge" alt="TEC" />
  <img src="https://img.shields.io/badge/Etapa-1%20(Imperativo)%20y%202%20(Funcional)-orange?style=for-the-badge" alt="Etapa" />
  <img src="https://img.shields.io/badge/Lenguajes-C99%20%7C%20Typed%20Racket-blueviolet?style=for-the-badge" alt="Lenguajes" />
  <img src="https://img.shields.io/badge/Estado-Etapa%201%20Completa%20%2F%20Fase%202%20En%20Curso-success?style=for-the-badge" alt="Estado" />
</p>

---

## Tabla de Contenidos
1. [Visión General del Proyecto](#visión-general-del-proyecto)
2. [Arquitectura y Flujo del Pipeline](#arquitectura-y-flujo-del-pipeline)
3. [Estructura de Directorios](#estructura-de-directorios)
4. [Constantes y Modelado de Datos en C](#constantes-y-modelado-de-datos-en-c)
5. [Descripción Modular de la Etapa 1 (`etapa1_c`)](#descripción-modular-de-la-etapa-1-etapa1_c)
6. [Actualizaciones y Transición hacia la Etapa 2](#actualizaciones-y-transición-hacia-la-etapa-2)
7. [Compilación y Ejecución](#compilación-y-ejecución)
8. [Batería de Comandos de Inspección y Pruebas](#batería-de-comandos-de-inspección-y-pruebas)
9. [Manejo Defensivo y Casos Límite](#manejo-defensivo-y-casos-límite)

---

## Visión General del Proyecto

**CEmestre** es un sistema modular de planificación académica diseñado para el **Instituto Tecnológico de Costa Rica (TEC)**. El objetivo principal consiste en procesar la malla curricular de las carreras de **Ingeniería en Computadores** e **Ingeniería en Biotecnología**, verificar el historial del estudiante, determinar la elegibilidad de asignaturas mediante grafos de requisitos/correquisitos, resolver colisiones horarias y generar combinaciones óptimas de matrícula libres de choques de horario.

El proyecto articula múltiples paradigmas computacionales:
* **Etapa 1 (Paradigma Imperativo - C99):** Ingesta, saneamiento, validación semántica, verificación de requisitos y detección exhaustiva de traslapes en bloques de tiempo.
* **Etapa 2 (Paradigma Funcional - Typed Racket):** Procesamiento perezoso mediante streams, validación tipada estática, polimorfismo paramétrico y backtracking libre de efectos secundarios.

---

## Arquitectura y Flujo del Pipeline

El núcleo en C opera como un motor de extracción, transformación y validación de datos (ETL) que produce el contrato JSON consumido por Racket:

```text
[ data/plan_estudios.json ]        [ data/historial_estudiante.json ]
          │                                        │
          ▼                                        ▼
   [ parser.c ]                             [ parser.c ]
          │                                        │
          └───────────────────┬────────────────────┘
                              ▼
                 [ Catalog ] y [ StudentHistory ]
                              │
                              ▼
                       [ validator.c ] ──(Fallo semántico)──► Aborta proceso (stderr)
                              │
                      (Datos conformes)
                              ▼
                     [ prereq_checker.c ]
               (Elegibilidad + Correquisitos)
                              │
                              ▼
                    [ schedule_checker.c ]
                 (Detección de traslapes)
                              │
                              ▼
                       [ exporter.c ]
                              │
                              ▼
                 [ data/output_schedule.json ]
                              │
                              ▼  (Entrada Etapa 2)
              [ parte2_racket / Typed Racket ] ◄── [ data/preferencias.json ]