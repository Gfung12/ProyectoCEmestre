# CEmestre: Constructor de Horarios
**Curso:** Paradigmas de Programación (CE1106)
**Etapa:** Etapa 1 – Paradigma Imperativo (Lenguaje C)
**Institución:** Instituto Tecnológico de Costa Rica (TEC)
**Carrera:** Ingeniería en Computadores
---

## 1. Arquitectura del Proyecto

El sistema está diseñado bajo el paradigma imperativo en lenguaje C, aplicando una división modular estricta de responsabilidades. El objetivo central consiste en estructurar el catálogo académico de asignaturas, verificar la consistencia de los datos ingresados, calcular la elegibilidad de cada curso con base en prerrequisitos y correquisitos, identificar colisiones de horario entre grupos y serializar los resultados hacia un archivo JSON normalizado.

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

1. **Ingesta y Deserialización (`parser.c`):** Lee los archivos JSON sin procesar y traslada la información a estructuras en memoria (`Catalog` y `StudentHistory`)[cite: 14].
2. **Validación y Normalización (`validator.c`):** Inspecciona y sanea las cadenas de texto, detecta datos inconsistentes, auto-dependencias, horas ilógicas o cursos fantasma, interrumpiendo el flujo antes de ejecutar cálculos sobre datos corruptos[cite: 14].
3. **Determinación de Elegibilidad (`prereq_checker.c`):** Analiza el historial académico para certificar el cumplimiento de prerrequisitos y correquisitos simultáneos[cite: 14].
4. **Evaluación de Traslapes Horarios (`schedule_checker.c`):** Contrasta los bloques de tiempo de cursos elegibles dentro de la misma carrera para reportar conflictos.
5. **Serialización (`exporter.c`):** Produce el archivo `data/output_schedule.json` con los metadatos requeridos por la etapa subsecuente[cite: 14].

---

## 2. Estructuras de Datos y Constantes

El dimensionamiento de memoria y las limitaciones del modelo están centralizados en `include/config.h` para garantizar consistencia y evitar el uso de literales dispersos[cite: 14]:

| Constante | Valor | Descripción |
| :--- | :--- | :--- |
| `MAX_STRING_LEN` | 100 | Longitud máxima para nombres descriptivos y carreras[cite: 14]. |
| `MAX_CODE_LEN` | 15 | Tamaño del búfer para códigos alfanuméricos de cursos[cite: 14]. |
| `MAX_GROUPS` | 10 | Cantidad máxima de grupos ofertados por curso[cite: 14]. |
| `MAX_SCHEDULES_PER_GROUP` | 5 | Bloques de horario asignables a un mismo grupo[cite: 14]. |
| `MAX_PREREQUISITES` | 10 | Límite de prerrequisitos por asignatura[cite: 14]. |
| `MAX_COREQUISITES` | 5 | Límite de correquisitos por asignatura[cite: 14]. |
| `MAX_COURSES` | 200 | Capacidad máxima del catálogo de asignaturas[cite: 14]. |
| `MAX_APPROVED_COURSES` | 100 | Límite de asignaturas acreditadas en el historial[cite: 14]. |
| `DAY_MONDAY` - `DAY_SATURDAY` | 1 a 6 | Codificación numérica de los días hábiles de la semana[cite: 14]. |

Las estructuras centrales definidas en `include/struct_definitions.h` son[cite: 14]:
* **`ScheduleBlock`:** Almacena el día (`day`), la hora de inicio (`start_time`) y la hora de fin (`end_time`) en formato militar (ej. 730 a 1120)[cite: 14].
* **`Group`:** Representa un grupo académico con su número identificador (`group_number`), su lista de bloques (`schedules`) y su conteo (`schedule_count`)[cite: 14].
* **`Course`:** Encapsula el código (`code`), nombre (`name`), créditos (`credits`), semestre (`semester`), carrera (`career`), arreglos estáticos de prerrequisitos (`prerequisites`) y correquisitos (`corequisites`), así como las banderas de evaluación (`is_eligible`, `has_any_schedule_clash` e `is_approved`)[cite: 14].
* **`Catalog`:** Contenedor global que almacena el arreglo de asignaturas (`courses`) y la cantidad efectiva de cursos cargados (`course_count`)[cite: 14].
* **`StudentHistory`:** Almacena los códigos de las asignaturas superadas por el estudiante (`approved_courses`) y su total (`approved_count`)[cite: 14].

---

## 3. Descripción Detallada de Módulos Implementados

### 3.1. Módulo de Verificación de Requisitos (`src/prereq_checker.c`)
Este módulo evalúa si un estudiante cumple las condiciones académicas para cursar una materia determinada, analizando el historial académico y la resolución contextual de correquisitos[cite: 14].

* **`is_course_approved`:** Determina si un código de materia específico ya fue acreditado por el estudiante[cite: 14].
* **`can_take_course`:** Evalúa la viabilidad de matricular la asignatura comprobando que la materia no esté aprobada, que todos sus prerrequisitos estén en el historial, y que los correquisitos sean matriculables simultáneamente (verificando a su vez los prerrequisitos del correquisito)[cite: 14].

### 3.2. Módulo Validador de Entrada (`src/validator.c`)
Actúa como una barrera de integridad que sanea y certifica la consistencia de los datos leídos desde los archivos JSON[cite: 14].

* **`validate_catalog`:** Estandariza textos a mayúsculas, valida duplicados (mismo código en la misma carrera), detecta dependencias fantasma, prohíbe auto-dependencias, valida horas militares y confirma que la hora de inicio sea estrictamente menor a la hora de fin[cite: 14].
* **`validate_student_history`:** Sanea el historial, verifica que los cursos aprobados existan en el catálogo y previene registros duplicados de aprobación[cite: 14].

### 3.3. Motor Temporal (`src/schedule_checker.c`)
Responsable de evaluar los traslapes horarios bajando la granularidad hasta el nivel de bloques de hora por grupo.

* **`blocks_overlap`:** Compara lógicamente dos bloques de horario. Retorna `true` si ocurren en el mismo día y se intersectan temporalmente ($b_1.\text{start\_time} < b_2.\text{end\_time} \land b_2.\text{start\_time} < b_1.\text{end\_time}$).
* **`groups_overlap`:** Cruza todos los bloques de horario del Grupo A contra todos los bloques del Grupo B.
* **`check_schedule_clashes`:** Realiza un escaneo de intersección múltiple. Solo compara materias que pertenezcan a la misma carrera y que sean simultáneamente elegibles para el estudiante (`is_eligible == true`). Si un grupo colisiona, se levanta la bandera interna `has_clash`. Si todos los grupos de una materia colisionan, el curso completo recibe `has_any_schedule_clash = true`.

### 3.4. Módulo de Deserialización Segura (`src/parser.c`)
Implementa programación defensiva para leer el JSON de entrada sin depender de librerías externas.

* **Validación de Punteros:** El uso de `strstr` y `strchr` está fuertemente protegido. Si una etiqueta esperada no existe en el texto, las funciones escapan de forma segura (`if (!pos) return;`) previniendo accesos nulos a memoria (*Segmentation Faults*).
* **Límites de Búfer:** Se imponen los topes definidos en `config.h` durante la iteración (ej. `count < MAX_GROUPS`). Al copiar cadenas con `strncpy`, se fuerza explícitamente el candado final (`\0`) evitando la lectura de memoria basura.

### 3.5. Motor de Serialización JSON (`src/exporter.c`)
Se encarga de escribir las estructuras de C de vuelta a un archivo de texto en formato JSON.

* **`export_catalog_to_json`:** Genera un JSON estrictamente estructurado iterando sobre los arreglos. Maneja lógicamente el cierre de comas (`,`) para asegurar que el último elemento de una lista o un objeto no imprima coma, garantizando un archivo válido que no corrompa el compilador en la siguiente etapa del proyecto. Exporta explícitamente la bandera `is_approved`.

### 3.6. Orquestador del Sistema (`src/main.c`)
Articula el procesamiento mediante el siguiente flujo[cite: 14]:
1. Carga archivos a memoria mediante `parser.c`[cite: 14].
2. Ejecuta `validator.c`; si detecta un error estructural, imprime en `stderr` y aborta la ejecución con código `1`[cite: 14].
3. Itera calculando `is_approved` e `is_eligible` mediante `prereq_checker.c`.
4. Evalúa colisiones horarias mediante `schedule_checker.c`[cite: 14].
5. Escribe los resultados procesados hacia `data/output_schedule.json` mediante `exporter.c` y libera recursos[cite: 14].

---

## 4. Decisiones de Diseño y Casos Límite

* **Justificación Técnica del Formato JSON de Salida:** Se eligió JSON como contrato de serialización porque permite modelar de forma nativa relaciones jerárquicas (Cursos -> Grupos -> Horarios) y arreglos dinámicos (Prerrequisitos), algo que en CSV requeriría redundancia de filas o formatos híbridos. Racket (lenguaje de la Etapa 2) posee librerías estándar altamente eficientes para deserializar JSON directamente en Listas y Hash Tables, facilitando el procesamiento funcional.
* **Eliminación de la Barrera de Semestre:** En `schedule_checker.c`, el motor compara todos los cursos elegibles entre sí, ignorando el semestre de pertenencia. *Caso límite resuelto:* Un estudiante rezagado puede matricular simultáneamente una materia atrasada (ej. semestre 1) y una adelantada (ej. semestre 3). Al eliminar el filtro de semestre, el sistema detecta choques cruzados en horarios de distintos niveles.
* **Evaluación de Correquisitos sin Recursión:** Se evitó la recursión en `can_take_course` para proteger el programa contra desbordamientos de pila (*Stack Overflow*) provocados por posibles referencias circulares académicas[cite: 14].
* **Separación de Saneamiento y Validación:** En `validator.c`, asegurar que todas las cadenas se conviertan a mayúsculas antes de verificar la coherencia de requisitos elimina falsos positivos por errores de digitación en el archivo JSON original[cite: 14].

---

## 5. Compilación, Ejecución y Manejo de Excepciones

El proyecto incluye un archivo `Makefile` configurado con banderas de diagnóstico rigurosas (`-Wall -Wextra -std=c99`)[cite: 14].

### Proceso de Compilación
Se proveen dos métodos de compilación:

1. **Mediante Makefile (Recomendado):**
   ```bash
   make
Para limpiar los archivos objeto generados y el ejecutable:
    make clean
    gcc -Wall -Wextra -std=c99 -Iinclude src/main.c src/parser.c src/prereq_checker.c src/schedule_checker.c src/exporter.c src/validator.c -o curso_app.exe
Ejecución Paso a Paso
El sistema asume que los archivos de entrada existen de antemano en las rutas relativas data/plan_estudios.json y data/historial_estudiante.json.

En plataformas Windows (PowerShell / CMD):
.\curso_app.exe

En plataformas Linux / macOS:
./curso_app.exe

Tras una ejecución exitosa, la terminal imprimirá un mensaje de éxito y el resultado final estará disponible en data/output_schedule.json.

Manejo de Excepciones y Errores Críticos
El sistema posee una tolerancia cero ante datos corruptos que puedan comprometer la lógica de matrícula. Todas las excepciones fatales se reportan inmediatamente por la salida de error estándar (stderr) y abortan la ejecución (retornando el código de salida 1), garantizando que nunca se produzca un archivo output_schedule.json inválido.

Las excepciones capturadas incluyen:

Fallo de I/O (Entrada/Salida): Si el sistema operativo deniega la lectura de los archivos JSON de entrada, o el archivo no existe en la ruta esperada, el parser retorna NULL y el programa se detiene.

Corrupción Semántica y Lógica (Validador): Si se detectan dependencias a materias fantasma (prerrequisitos que no existen), horas de finalización anteriores a las horas de inicio (cronología ilógica), créditos fuera del rango permitido (0 a 10), o ciclos de auto-dependencia (un curso pidiéndose a sí mismo).

Límites Estrictos de Memoria: Si los JSON de entrada exceden los topes de dimensionamiento estático definidos en config.h (por ejemplo, declarar más de 200 cursos o más de 10 grupos para un mismo curso), el parser truncará la lectura de forma defensiva para evitar la sobreescritura de memoria, y el validador procesará únicamente la información íntegra capturada hasta el límite.

---

## 6. Funciones Auxiliares, de Saneamiento y Control de Versiones

Para asegurar la robustez interna y la mantenibilidad del código, los módulos implementan rutinas auxiliares privadas (estáticas) que gestionan las operaciones de bajo nivel, complementadas con la configuración de control de versiones del repositorio.

### 6.1. Rutinas Auxiliares por Módulo

* **Deserialización Segura (`src/parser.c`):**
  * `read_file_to_string`: Abre el archivo en modo binario, calcula su longitud mediante `fseek`/`ftell`, reserva memoria dinámica exacta e incorpora un byte nulo (`\0`) como candado de seguridad final[cite: 13].
  * `get_json_string_val` / `get_json_int_val`: Buscan patrones de claves mediante `strstr`, localizan delimitadores de asignación y extraen cadenas o enteros protegiéndose contra desbordamientos de búfer con `max_len`[cite: 13].
  * `get_json_array_strings`: Itera sobre arreglos delimitados por corchetes (`[...]`) extrayendo códigos alfanuméricos de forma acotada a las capacidades máximas definidas en `config.h`[cite: 3, 13].
  * `parse_groups_and_schedules`: Implementa un algoritmo de seguimiento de profundidad de llaves (`{` y `}`) para aislar dinámicamente bloques anidados de grupos y horarios sin errores de segmentación[cite: 13].

* **Saneamiento e Integridad (`src/validator.c`):**
  * `sanitize_code`: Elimina espacios en blanco iniciales/finales y convierte de manera uniforme todos los caracteres alfanuméricos a mayúsculas para evitar falsos positivos por formato[cite: 16].
  * `is_valid_code_format`: Verifica que los códigos de curso cumplan estipulaciones estrictas de contenido alfanumérico puro[cite: 16].
  * `course_exists_in_catalog`: Realiza búsquedas lineales en memoria para certificar la existencia real de los cursos referenciados, erradicando dependencias fantasma[cite: 16].
  * `is_valid_military_time` & `blocks_clash`: Validan la corrección de horas bajo formato militar (0000 a 2359) y evalúan traslapes internos dentro de un mismo grupo académico[cite: 16].

* **Evaluación Temporal y de Bloques (`src/schedule_checker.c`):**
  * `blocks_overlap`: Comprueba la intersección exacta entre dos bloques individuales de horario evaluando coincidencia de día y solapamiento estricto de intervalos de tiempo ($b_1.\text{start} < b_2.\text{end} \land b_2.\text{start} < b_1.\text{end}$)[cite: 15].

### 6.2. Configuración del Entorno y Control de Versiones

* **Automatización de Compilación (`Makefile`):** Centraliza las reglas de construcción incremental del proyecto utilizando el compilador `gcc` bajo directrices rigurosas de depuración y compatibilidad (`-Wall -Wextra -std=c99 -Iinclude`). Gestiona la compilación separada de archivos objeto (`.o`) y provee la regla `clean` para la purga de binarios temporales y del ejecutable principal (`curso_app`)[cite: 19].
* **Higiene del Repositorio (`.gitignore`):** Excluye automáticamente archivos de objetos compilados, bibliotecas estáticas/dinámicas, binarios ejecutables, archivos de depuración, carpetas de configuración de entornos de desarrollo (como VS Code o CLion) y archivos transitorios de salida (`data/output_schedule.json`)[cite: 18].
* **Normalización Multiplataforma (`.gitattributes`):** Configura la detección automática de archivos de texto aplicando normalización de saltos de línea a formato estándar `LF`, previniendo conflictos de codificación al colaborar entre sistemas operativos Windows y Unix/Linux[cite: 17].