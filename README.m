# CEmestre: Constructor de Horarios
**Curso:** Paradigmas de Programación (CE1106)
**Etapa:** Etapa 1 – Paradigma Imperativo (Lenguaje C)
**Institución:** Instituto Tecnológico de Costa Rica (TEC)
**Carrera:** Ingeniería en Computadores
---

## 1. Arquitectura del Proyecto

El sistema está diseñado bajo el paradigma imperativo en lenguaje C, aplicando una división modular estricta de responsabilidades[cite: 2]. El objetivo central consiste en estructurar el catálogo académico de asignaturas, verificar la consistencia de los datos ingresados, calcular la elegibilidad de cada curso con base en prerrequisitos y correquisitos, identificar colisiones de horario entre grupos y serializar los resultados hacia un archivo JSON normalizado[cite: 2].

### Flujo de Ejecución y Pipeline de Datos
[ data/plan_estudios.json ]        [ data/historial_estudiante.json ]
│                                      │
▼                                      ▼
[ parser.c ]                           [ parser.c ]
│                                      │
└───────────────┬──────────────────────┘
▼
[ Catalog ] y [ StudentHistory ] (Memoria)
│
▼
[ validator.c ]  ──(Error detectado)──► Aborta la ejecución (stderr)
│ (Datos íntegros)
▼
[ prereq_checker.c ]
(Verificación de elegibilidad con correquisitos)
│
▼
[ schedule_checker.c ]
(Detección de choques de horario)
│
▼
[ exporter.c ]
│
▼
[ data/output_schedule.json ]

1. **Ingesta y Deserialización (`parser.c`):** Lee los archivos JSON sin procesar y traslada la información a estructuras en memoria (`Catalog` y `StudentHistory`).
2. **Validación y Normalización (`validator.c`):** Inspecciona y sanea las cadenas de texto, detecta datos inconsistentes, auto-dependencias, horas ilógicas o cursos fantasma, interrumpiendo el flujo antes de ejecutar cálculos sobre datos corruptos.
3. **Determinación de Elegibilidad (`prereq_checker.c`):** Analiza el historial académico para certificar el cumplimiento de prerrequisitos y correquisitos simultáneos.
4. **Evaluación de Traslapes Horarios (`schedule_checker.c`):** Contrasta los bloques de tiempo de cursos elegibles dentro del mismo semestre y carrera para reportar conflictos[cite: 1].
5. **Serialización (`exporter.c`):** Produce el archivo `data/output_schedule.json` con los metadatos requeridos por la etapa subsecuente[cite: 1, 2].

---

## 2. Estructuras de Datos y Constantes

El dimensionamiento de memoria y las limitaciones del modelo están centralizados en `include/config.h` para garantizar consistencia y evitar el uso de literales dispersos[cite: 1, 2]:

| Constante | Valor | Descripción |
| :--- | :--- | :--- |
| `MAX_STRING_LEN` | 100 | Longitud máxima para nombres descriptivos y carreras[cite: 1]. |
| `MAX_CODE_LEN` | 15 | Tamaño del búfer para códigos alfanuméricos de cursos[cite: 1]. |
| `MAX_GROUPS` | 10 | Cantidad máxima de grupos ofertados por curso[cite: 1]. |
| `MAX_SCHEDULES_PER_GROUP` | 5 | Bloques de horario asignables a un mismo grupo[cite: 1]. |
| `MAX_PREREQUISITES` | 10 | Límite de prerrequisitos por asignatura[cite: 1]. |
| `MAX_COREQUISITES` | 5 | Límite de correquisitos por asignatura[cite: 1]. |
| `MAX_COURSES` | 200 | Capacidad máxima del catálogo de asignaturas[cite: 1]. |
| `MAX_APPROVED_COURSES` | 100 | Límite de asignaturas acreditadas en el historial[cite: 1]. |
| `DAY_MONDAY` - `DAY_SATURDAY` | 1 a 6 | Codificación numérica de los días hábiles de la semana[cite: 1]. |

Las estructuras centrales definidas en `include/struct_definitions.h` son[cite: 1]:
* **`ScheduleBlock`:** Almacena el día (`day`), la hora de inicio (`start_time`) y la hora de fin (`end_time`) en formato militar (ej. 730 a 1120)[cite: 1].
* **`Group`:** Representa un grupo académico con su número identificador (`group_number`), su lista de bloques (`schedules`) y su conteo (`schedule_count`)[cite: 1].
* **`Course`:** Encapsula el código (`code`), nombre (`name`), créditos (`credits`), semestre (`semester`), carrera (`career`), arreglos estáticos de prerrequisitos (`prerequisites`) y correquisitos (`corequisites`), así como las banderas de evaluación (`is_eligible`, `has_any_schedule_clash` e `is_approved`)[cite: 1].
* **`Catalog`:** Contenedor global que almacena el arreglo de asignaturas (`courses`) y la cantidad efectiva de cursos cargados (`course_count`)[cite: 1].
* **`StudentHistory`:** Almacena los códigos de las asignaturas superadas por el estudiante (`approved_courses`) y su total (`approved_count`)[cite: 1].

---

## 3. Descripción Detallada de Módulos Implementados

### 3.1. Módulo de Verificación de Requisitos (`src/prereq_checker.c`)

Este módulo evalúa si un estudiante cumple las condiciones académicas para cursar una materia determinada[cite: 1]. Se adaptó para incluir la validación completa de correquisitos y su resolución contextual dentro del catálogo[cite: 1].

#### `bool is_course_approved(const char *code, const StudentHistory *history)`
* **Propósito:** Determina si un código de materia específico ya fue acreditado por el estudiante[cite: 1].
* **Parámetros:**
  * `code`: Cadena de texto con el código a verificar[cite: 1].
  * `history`: Puntero al historial del estudiante[cite: 1].
* **Retorno:** `true` si el código existe dentro de `history->approved_courses`; de lo contrario, `false`[cite: 1].

#### `bool can_take_course(const Course *course, const StudentHistory *history, const Catalog *catalog)`
* **Propósito:** Evalúa la viabilidad de matricular la asignatura `course` considerando prerrequisitos y correquisitos simultáneos[cite: 1].
* **Parámetros:**
  * `course`: Puntero a la estructura del curso evaluado[cite: 1].
  * `history`: Puntero al historial académico del estudiante[cite: 1].
  * `catalog`: Puntero al catálogo global, necesario para inspeccionar las restricciones de las asignaturas correquisito[cite: 1].
* **Variables internas:**
  * `coreq_code`: Almacena temporalmente el código del correquisito examinado[cite: 1].
  * `can_take_coreq`: Bandera booleana que verifica si un correquisito no aprobado puede matricularse concurrentemente.
  * `i, j, k`: Variables de control de iteración para recorrer los correquisitos, el catálogo y los prerrequisitos del correquisito, respectivamente[cite: 1].
* **Lógica implementada:**
  1. Si la materia ya fue aprobada (`is_course_approved`), retorna `false`[cite: 1].
  2. Si alguno de los prerrequisitos listados en `course->prerequisites` no está aprobado, retorna `false` de forma inmediata[cite: 1].
  3. Para cada elemento en `course->corequisites`:
     * Si ya está aprobado en el historial, continúa con el siguiente[cite: 1].
     * Si no ha sido superado, se busca la asignatura en `catalog`[cite: 1]. Si se encuentra, se verifica que todos los prerrequisitos de dicho correquisito estén aprobados en el historial[cite: 1]. Si no los cumple o el curso no es matriculable, la función retorna `false` impidiendo la matrícula del curso principal.

---

### 3.2. Módulo Validador de Entrada (`src/validator.c`)

Este módulo actúa como una barrera de integridad que sanea y certifica la consistencia de los datos leídos desde los archivos JSON, previniendo fallos en tiempo de ejecución derivados de errores de digitación o inconsistencias lógicas.

#### Funciones Auxiliares Privadas

* **`static void sanitize_code(char *code)`:** Normaliza las cadenas alfanuméricas eliminando espacios en blanco en los extremos (*trimming*) y convirtiendo todos los caracteres alfabéticos a mayúsculas mediante `toupper`. Utiliza punteros `start` y `end` para delimitar la región válida de la cadena.
* **`static bool is_valid_code_format(const char *code)`:** Verifica que el código no esté vacío y contenga exclusivamente caracteres alfanuméricos mediante `isalnum`, descartando símbolos de puntuación, espacios intermedios y caracteres especiales.
* **`static bool course_exists_in_catalog(const char *code, const Catalog *catalog)`:** Ejecuta una búsqueda lineal para comprobar si un código dado existe formalmente en el arreglo `catalog->courses`[cite: 1].
* **`static bool is_valid_military_time(int time)`:** Valida que un entero corresponda al rango horario militar ($0000$ a $2359$), descomponiendo el valor para comprobar que $\text{time} \pmod{100} < 60$.
* **`static bool blocks_clash(const ScheduleBlock *b1, const ScheduleBlock *b2)`:** Determina si dos bloques horarios colisionan en el mismo día evaluando el solapamiento temporal[cite: 1]:
  $$\text{Choque} \iff (b_1.\text{start\_time} < b_2.\text{end\_time}) \land (b_2.\text{start\_time} < b_1.\text{end\_time})$$

#### Funciones Públicas

* **`bool validate_catalog(Catalog *catalog)`:**
  * **Fase 1 (Saneamiento):** Recorre el catálogo y estandariza los códigos del curso, sus prerrequisitos y correquisitos a mayúsculas y sin espacios[cite: 1].
  * **Fase 2 (Detección de Duplicados):** Contrasta cada materia contra las subsiguientes para certificar que ningún código esté registrado más de una vez en el catálogo.
  * **Fase 3 (Reglas de Integridad Académica):**
    * Verifica que los créditos pertenezcan al intervalo válido $[0, 10]$.
    * Restringe el semestre al alcance del proyecto ($[0, 4]$)[cite: 2].
    * Detecta dependencias fantasma (prerrequisitos o correquisitos ausentes en el catálogo).
    * Detecta auto-dependencias (cursos que se exigen a sí mismos como requisito o correquisito).
    * Detecta elementos repetidos dentro de las listas de requisitos de un mismo curso.
    * Detecta colisiones lógicas (materias declaradas simultáneamente como prerrequisito y correquisito).
    * Comprueba que los días asignados pertenezcan al rango $[1, 6]$ (`DAY_MONDAY` a `DAY_SATURDAY`)[cite: 1].
    * Comprueba la validez cronológica del bloque ($\text{start\_time} < \text{end\_time}$)[cite: 1].
    * Detecta autocolisiones internas entre bloques pertenecientes al mismo grupo[cite: 1].
* **`bool validate_student_history(StudentHistory *history, const Catalog *catalog)`:**
  * Sanea los códigos registrados en el historial académico del estudiante.
  * Certifica que cada materia aprobada exista realmente en el catálogo del plan de estudios.
  * Detecta y reporta cursos aprobados redundantes o duplicados en el registro.

---

### 3.3. Orquestador del Sistema (`src/main.c`)

El archivo principal articula el procesamiento mediante el siguiente flujo[cite: 1]:
1. Carga los archivos `data/plan_estudios.json` y `data/historial_estudiante.json` mediante `load_catalog` y `load_student_history`[cite: 1].
2. Ejecuta `validate_catalog(&catalog)` y `validate_student_history(&history, &catalog)`. Si cualquiera retorna `false`, se imprimen los diagnósticos en `stderr`, se libera la memoria y el proceso culmina con código de salida `1`.
3. Itera sobre las asignaturas del catálogo calculando el estado `is_eligible` mediante `can_take_course(course, &history, &catalog)`[cite: 1].
4. Ejecuta `check_schedule_clashes(&catalog)` para marcar posibles colisiones horarias entre materias elegibles[cite: 1].
5. Exporta el resultado final hacia `data/output_schedule.json` mediante `export_catalog_to_json` y concluye liberando las estructuras[cite: 1].

---

## 4. Decisiones de Diseño y Casos Límite

* **Evaluación de Correquisitos sin Recursión:** Se evitó la recursión directa en `can_take_course` para proteger el programa contra desbordamientos de pila (*Stack Overflow*) provocados por referencias circulares en planes académicos mal confeccionados. La verificación de correquisitos se limita a constatar los prerrequisitos del correquisito de manera desacoplada.
* **Canal de Diagnóstico `stderr`:** Todos los mensajes de validación e inconsistencia se canalizan mediante `fprintf(stderr, ...)`. Esto asegura la emisión inmediata de los errores en la consola sin verse afectados por el búfer de salida estándar.
* **Separación de Saneamiento y Validación:** La ejecución de `validate_catalog` en pasadas diferenciadas garantiza que todas las materias estén formalmente convertidas a mayúsculas antes de verificar la existencia cruzada de requisitos, eliminando falsos negativos ocasionados por el orden de los elementos en el JSON.

---

## 5. Compilación y Ejecución

El proyecto incluye un archivo `Makefile` configurado con banderas de diagnóstico rigurosas (`-Wall -Wextra -std=c99`)[cite: 1].

### Compilación usando Makefile

```bash
make

Para limpiar los archivos objeto generados y el ejecutable[cite: 1]:
make clean

Compilación Manual mediante GCC
gcc -Wall -Wextra -std=c99 -Iinclude src/main.c src/parser.c src/prereq_checker.c src/schedule_checker.c src/exporter.c src/validator.c -o curso_app.exe

En plataformas Windows (PowerShell / CMD)[cite: 1]:
.\curso_app.exe

