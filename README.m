
# CEmestre: Constructor Inteligente de Horarios

  

<p  align="center">

<img  src="https://img.shields.io/badge/Curso-CE1106%20Paradigmas%20de%20Programaci%C3%B3n-0052cc?style=for-the-badge"  alt="Curso"  />

<img  src="https://img.shields.io/badge/Instituci%C3%B3n-Instituto%20Tecnol%C3%B3gico%20de%20Costa%20Rica-00758f?style=for-the-badge"  alt="TEC"  />

<img  src="https://img.shields.io/badge/Etapa-1%20(Imperativo)%20y%202%20(Funcional)-orange?style=for-the-badge"  alt="Etapa"  />

<img  src="https://img.shields.io/badge/Lenguajes-C99%20%7C%20Typed%20Racket-blueviolet?style=for-the-badge"  alt="Lenguajes"  />

<img  src="https://img.shields.io/badge/Estado-Etapa%201%20Completa%20%2F%20Fase%202%20En%20Curso-success?style=for-the-badge"  alt="Estado"  />

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

  

*  **Etapa 1 (Paradigma Imperativo - C99):** Ingesta, saneamiento, validación semántica, verificación de requisitos y detección exhaustiva de traslapes en bloques de tiempo.

*  **Etapa 2 (Paradigma Funcional - Typed Racket):** Procesamiento perezoso mediante streams, validación tipada estática, polimorfismo paramétrico y backtracking libre de efectos secundarios.

  

---

  

## Arquitectura y Flujo del Pipeline

  

El núcleo en C opera como un motor de extracción, transformación y validación de datos (ETL) que produce el contrato JSON consumido por Racket:

  

```text

[ data/plan_estudios.json ] [ data/historial_estudiante.json ]

│ │

▼ ▼

[ parser.c ] [ parser.c ]

│ │

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

▼ (Entrada Etapa 2)

[ parte2_racket / Typed Racket ] ◄── [ data/preferencias.json ]

```

  

### Fases de Ejecución

  

1.  **Ingesta y Deserialización (`parser.c`):** Extrae datos jerárquicos desde los JSON de entrada y puebla las estructuras estáticas en memoria.

  

2.  **Saneamiento y Certificación (`validator.c`):** Normaliza cadenas, verifica integridad referencial, prohíbe cursos fantasma o auto-requisitos y asegura cronología horaria válida.

  

3.  **Resolución Académica (`prereq_checker.c`):** Calcula si una materia no aprobada cuenta con todos sus prerrequisitos y correquisitos viables.

  

4.  **Análisis Temporal de Colisiones (`schedule_checker.c`):** Detecta traslapes horarios entre asignaturas elegibles de la misma carrera.

  

5.  **Serialización Estandarizada (`exporter.c`):** Emite el catálogo estructurado con los estados booleanos calculados (`is_approved`, `is_eligible`, `has_clash`, `has_any_schedule_clash`).

  

---

  

## Estructura de Directorios

  

```text

ProyectoCEmestre/

├── data/ # Almacenamiento de esquemas JSON

│ ├── historial_estudiante.json # Materias aprobadas por el estudiante

│ ├── plan_estudios.json # Catálogo oficial (Semestres 0 al 6)

│ ├── preferencias.json # Cursos de interés y rango de créditos

│ └── output_schedule.json # Salida procesada generada por C

├── etapa1_c/ # Implementación del motor en C99

│ ├── Makefile # Script de compilación automatizada

│ ├── include/ # Cabeceras y contratos de tipos

│ │ ├── config.h # Constantes de dimensionamiento

│ │ ├── exporter.h # Declaración del serializador JSON

│ │ ├── parser.h # Declaración del parser de entrada

│ │ ├── prereq_checker.h # Declaración del verificador de requisitos

│ │ ├── schedule_checker.h # Declaración del evaluador de horarios

│ │ ├── struct_definitions.h # Modelado de structs imperativos

│ │ └── validator.h # Declaración del saneador de integridad

│ └── src/ # Código fuente modular

│ ├── exporter.c # Escritor del JSON formateado

│ ├── main.c # Orquestador del flujo

│ ├── parser.c # Lector seguro de cadenas JSON

│ ├── prereq_checker.c # Lógica de prerrequisitos y correquisitos

│ ├── schedule_checker.c # Comparador de traslapes en bloques temporales

│ └── validator.c # Validador semántico y anti-corrupción

└── parte2_racket/ # Implementación funcional (Etapa 2)

├── types.rkt # Tipos inmutables en Typed Racket

├── parser.rkt # Ingesta funcional y cruce de datos

└── filters.rkt # Abstracciones con polimorfismo paramétrico

```

  

---

  

## Constantes y Modelado de Datos en C

  

Las dimensiones del sistema se definen en `include/config.h`:

  

| Constante | Valor | Finalidad Técnica |

|---|---|---|

| `MAX_COURSES` | `200` | Capacidad máxima de asignaturas simultáneas en el catálogo. |

| `MAX_GROUPS` | `10` | Límite de grupos académicos ofertables por curso. |

| `MAX_SCHEDULES_PER_GROUP` | `5` | Máximo de bloques horarios por grupo. |

| `MAX_PREREQUISITES` | `10` | Límite superior de prerrequisitos por materia. |

| `MAX_COREQUISITES` | `5` | Límite superior de correquisitos por materia. |

| `MAX_APPROVED_COURSES` | `100` | Máximo de asignaturas acreditadas en el expediente. |

| `MAX_SEMESTER` | `6` | Alcance curricular cubierto por el sistema. |

| `MAX_STRING_LEN` | `100` | Tamaño de búfer para nombres y carreras. |

| `MAX_CODE_LEN` | `15` | Tamaño de búfer para códigos alfanuméricos. |

| `DAY_MONDAY` - `DAY_SATURDAY` | `1` - `6` | Representación numérica de los días lectivos. |

  

### Estructuras Centrales (`include/struct_definitions.h`)

  

-  **`ScheduleBlock`:** Encapsula el día lectivo (`day`), hora de inicio (`start_time`) y fin (`end_time`) en formato militar (ej. `730` para 07:30, `1650` para 16:50).

  

-  **`Group`:** Contiene el identificador (`group_number`), arreglo de bloques (`schedules`), contador (`schedule_count`) y bandera individual de colisión (`has_clash`).

  

-  **`Course`:** Almacena metadatos (`code`, `name`, `credits`, `semester`, `career`), dependencias (`prerequisites`, `corequisites`), grupos asociados (`groups`) y banderas de decisión (`is_approved`, `is_eligible`, `has_any_schedule_clash`).

  

-  **`Catalog`:** Registro global contenedor con arreglo estático de asignaturas y total efectivo (`course_count`).

  

-  **`StudentHistory`:** Almacén del expediente del estudiante (`approved_courses`, `approved_count`).

  

---

  

## Descripción Modular de la Etapa 1 (`etapa1_c`)

  

### 1. Verificador de Requisitos (`src/prereq_checker.c`)

  

-  **`is_course_approved`:** Comprobación rápida para saber si un código figura en el expediente.

-  **`can_take_course`:** Evalúa si la materia ya fue aprobada (la descarta), certifica que todos los prerrequisitos figuren como aprobados y analiza que los correquisitos sean simultáneamente cursables comprobando a su vez los requisitos del correquisito.

  

### 2. Validador Semántico (`src/validator.c`)

  

-  **`sanitize_code`:** Limpia espacios residuales y uniforma códigos a mayúsculas.

-  **`validate_catalog`:** Impone saneamiento universal, descarta duplicados dentro de la misma carrera, verifica límites de créditos (0 a 10), acota el rango de semestres a `MAX_SEMESTER` (0 a 6), detecta auto-dependencias, prerrequisitos/correquisitos fantasma y traslapes horarios internos dentro de un mismo grupo académico.

-  **`validate_student_history`:** Confirma que cada asignatura acreditada exista en el catálogo y evita registros repetidos.

  

### 3. Motor de Horarios y Choques (`src/schedule_checker.c`)

  

-  **`blocks_overlap`:** Evalúa si dos bloques coinciden en día y se intersectan temporalmente mediante la regla:

  

$$\text{start}_1 < \text{end}_2 \;\land\; \text{start}_2 < \text{end}_1$$

  

-  **`groups_overlap`:** Compara exhaustivamente todos los bloques del Grupo A contra el Grupo B.

-  **`check_schedule_clashes`:** Realiza comparaciones cruzadas únicamente entre materias simultáneamente elegibles (`is_eligible == true`) de la misma carrera. Marca `has_clash` por grupo y levanta `has_any_schedule_clash = true` en el curso si todos sus grupos colisionan sin alternativa disponible.

  

### 4. Deserializador Seguro (`src/parser.c`)

  

- Implementa lectura binaria protegida (`read_file_to_string`), extracción delimitada de campos (`get_json_string_val`, `get_json_int_val`), captura de arreglos y parseo de profundidad de llaves balanceadas (`parse_groups_and_schedules`) sin dependencias externas, aplicando candados de fin de cadena (`\0`) explícitos.

  

### 5. Serializador JSON (`src/exporter.c`)

  

- Genera el archivo normalizado `output_schedule.json` con control de comas terminales y exportación estricta de booleanos nativos.

  

---

  

## Actualizaciones y Transición hacia la Etapa 2

  

Para satisfacer los requerimientos de la Fase Funcional, se realizaron las siguientes extensiones en la arquitectura:

  

### 1. Extensión del Plan de Estudios a 6 Semestres

  

Se amplió el archivo `data/plan_estudios.json` integrando el catálogo oficial hasta el semestre 6 para **Ingeniería en Computadores** y para **Ingeniería en Biotecnología**, elevando el catálogo procesado a **91 asignaturas**.

  

> [!NOTE]

> En `etapa1_c/include/config.h` se definió `MAX_SEMESTER 6` y se actualizó `etapa1_c/src/validator.c` para certificar la presencia del campo `career` y validar semestres en el intervalo $[0, 6]$.

  

### 2. Archivo de Preferencias del Estudiante (`data/preferencias.json`)

  

A diferencia de `historial_estudiante.json` (que refleja el pasado académico), `preferencias.json` modela la intención de matrícula inmediata del estudiante:

  

```json

{

"min_credits": 8,

"max_credits": 16,

"interested_courses": [

{

"code": "CE1107",

"career": "Ingeniería en Computadores",

"groups": [1, 2]

},

{

"code": "MA1102",

"career": "Ingeniería en Computadores",

"groups": [1]

}

]

}

```

  

- Permite configurar un rango de créditos deseados (`min_credits`, `max_credits`) para el filtrado en Racket.

- Incorpora el atributo `"career"` por curso de interés, evitando ambigüedades en materias compartidas entre carreras.

- Permite seleccionar múltiples grupos alternativos para un mismo curso de interés.

  

---

  

## Compilación y Ejecución

  

### 1. Compilación mediante Makefile

  

Desde el directorio `etapa1_c/`:

  

```bash

make

```

  

> [!TIP]

> En entornos Windows sin `rm` nativo en el Path, para limpiar archivos compilados se puede ejecutar en PowerShell:

>

> ```powershell

> Remove-Item  -Force -ErrorAction SilentlyContinue cemestre_c.exe,  *.o

> ```

  

### 2. Compilación manual alternativa con GCC

  

```bash

gcc  -Wall  -Wextra  -std=c99  -Iinclude  src/*.c  -o  cemestre_c

```

  

### 3. Ejecución del Sistema

  

El ejecutable debe lanzarse desde dentro de la carpeta `etapa1_c` para resolver las rutas relativas `../data/`:

  

-  **En Windows (PowerShell / CMD):**

  

```powershell

.\cemestre_c.exe

```

  

-  **En Linux / macOS:**

  

```bash

./cemestre_c

```

  

**Salida esperada:**

  

```text

Proceso completado con éxito. Resultados guardados en ../data/output_schedule.json

```

  

---

  

## Batería de Comandos de Inspección y Pruebas

  

Para auditar y validar el resultado de `data/output_schedule.json` de forma automatizada:

  

### En Windows (PowerShell)

  

1.  **Listar cursos de semestres avanzados (Semestres 5 y 6):**

  

```powershell

(Get-Content  -Raw -Path "..\data\output_schedule.json"  |  ConvertFrom-Json) |  Where-Object { $_.semester  -ge  5 } |  Select-Object code, semester, career, is_eligible

```

  

2.  **Verificar elegibilidad de una materia específica de semestre 5 (`CE1107`):**

  

```powershell

(Get-Content  -Raw -Path "..\data\output_schedule.json"  |  ConvertFrom-Json) |  Where-Object { $_.code  -eq  "CE1107" } |  Select-Object code, name, semester, career, is_eligible, is_approved

```

  

3.  **Auditar distribución de cursos por número de semestre:**

  

```powershell

(Get-Content  -Raw -Path "..\data\output_schedule.json"  |  ConvertFrom-Json) |  Group-Object semester |  Select-Object Name, Count |  Sort-Object Name

```

  

4.  **Contar la cantidad total de cursos procesados en el catálogo:**

  

```powershell

(Get-Content  -Raw -Path "..\data\output_schedule.json"  |  ConvertFrom-Json).Count

```

  

### En Linux / macOS (Bash + `jq`)

  

1.  **Listar cursos de semestres 5 y 6:**

  

```bash

jq '.[] | select(.semester >= 5) | {code, semester, career, is_eligible}' ../data/output_schedule.json

```

  

2.  **Inspeccionar estado detallado de `CE1107`:**

  

```bash

jq '.[] | select(.code == "CE1107") | {code, name, semester, is_eligible, is_approved}' ../data/output_schedule.json

```

  

3.  **Conteo total de asignaturas registradas:**

  

```bash

jq 'length' ../data/output_schedule.json

```

  

---

  

## Manejo Defensivo y Casos Límite

  

-  **Aislamiento por Carrera en Detección de Choques:** En `schedule_checker.c`, dos grupos con horarios idénticos no se marcan en colisión si pertenecen a carreras distintas, garantizando coherencia para estudiantes que cursan planes independientes.

  

-  **Independencia del Semestre al Evaluar Choques:** El sistema no asume que un estudiante solo cursa materias de un único bloque lectivo. Estudiantes con asignaturas de rezago y adelanto son evaluados de forma global.

  

-  **Prevención de Ciclos de Correquisitos:** La comprobación de correquisitos en `prereq_checker.c` valida la matriculabilidad de la materia par sin permitir recursión infinita.

  

-  **Tolerancia Cero ante Datos Corruptos:** El módulo `validator.c` detiene la ejecución inmediatamente si detecta auto-dependencias, referencias a cursos inexistentes o inconsistencias en los intervalos de tiempo militar, evitando la propagación de datos corruptos hacia la fase en Racket.
