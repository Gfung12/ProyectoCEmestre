<h1 align="center">📅 CEmestre</h1>
<h3 align="center">Constructor Inteligente de Horarios</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Curso-CE1106%20Paradigmas%20de%20Programaci%C3%B3n-0052cc?style=for-the-badge" alt="Curso" />
  <img src="https://img.shields.io/badge/Instituci%C3%B3n-Instituto%20Tecnol%C3%B3gico%20de%20Costa%20Rica-00758f?style=for-the-badge" alt="TEC" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Etapa%201-Imperativo-1f6feb?style=for-the-badge" alt="Etapa 1" />
  <img src="https://img.shields.io/badge/Etapa%202-Funcional-8957e5?style=for-the-badge" alt="Etapa 2" />
  <img src="https://img.shields.io/badge/Lenguajes-C99%20%7C%20Typed%20Racket-blueviolet?style=for-the-badge" alt="Lenguajes" />
  <img src="https://img.shields.io/badge/Estado-Etapa%201%20%26%202%20Completas-success?style=for-the-badge" alt="Estado" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/C-C99-00599C?style=flat-square&logo=c&logoColor=white" alt="C99" />
  <img src="https://img.shields.io/badge/Racket-Typed-9F1D20?style=flat-square" alt="Typed Racket" />
  <img src="https://img.shields.io/badge/Build-Makefile-6D8086?style=flat-square" alt="Makefile" />
  <img src="https://img.shields.io/badge/Datos-JSON-000000?style=flat-square&logo=json&logoColor=white" alt="JSON" />
  <img src="https://img.shields.io/badge/Cat%C3%A1logo-91%20asignaturas-orange?style=flat-square" alt="91 asignaturas" />
</p>

---

## Tabla de Contenidos

| # | Sección | Contenido |
|:-:|---|---|
| 1 | [Visión General del Proyecto](#-1-visión-general-del-proyecto) | Objetivo y paradigmas |
| 2 | [Arquitectura y Flujo del Pipeline](#-2-arquitectura-y-flujo-del-pipeline) | Diagrama de punta a punta |
| 3 | [Estructura de Directorios](#-3-estructura-de-directorios) | Árbol del proyecto por zonas |
| 4 | [Constantes y Modelado de Datos en C](#-4-constantes-y-modelado-de-datos-en-c) | `config.h` y structs |
| 5 | [Descripción Modular de la Etapa 1](#-5-descripción-modular-de-la-etapa-1-etapa1_c) | Módulos en C |
| 6 | [Actualizaciones de Datos para la Etapa 2](#-6-actualizaciones-de-datos-para-la-etapa-2) | Plan a 6 semestres y preferencias |
| 7 | [Arquitectura Funcional en Racket](#-7-arquitectura-funcional-en-racket-parte2_racket) | Tipos, polimorfismo, ingesta, generación y exportación |
| 8 | [Guía de Integración para Desarrolladores](#-8-guía-de-integración-para-desarrolladores-etapa-2) | Cómo consumir los módulos base |
| 9 | [Compilación y Ejecución](#-9-compilación-y-ejecución) | C y Racket |
| 10 | [Batería de Comandos de Inspección y Pruebas](#-10-batería-de-comandos-de-inspección-y-pruebas) | PowerShell y `jq` |
| 11 | [Manejo Defensivo y Casos Límite](#-11-manejo-defensivo-y-casos-límite) | Robustez del sistema |
| 12 | [Decisiones de Diseño de la Etapa 2](#-12-decisiones-de-diseño-de-la-etapa-2) | Justificaciones, caso límite real y formato de salida |
| 13 | [Estructuras de Datos Desarrolladas](#-13-estructuras-de-datos-desarrolladas) | Tipos, tuplas intermedias y mapa de funciones |

---

## 1. Visión General del Proyecto

**CEmestre** es un sistema modular de planificación académica desarrollado para el **Instituto Tecnológico de Costa Rica (TEC)**. Su propósito es procesar la malla curricular de **Ingeniería en Computadores** e **Ingeniería en Biotecnología**, verificar el expediente del estudiante, determinar la elegibilidad de asignaturas mediante grafos de requisitos y correquisitos, identificar colisiones horarias y generar combinaciones válidas de matrícula libres de choques.

El sistema integra dos paradigmas de programación:

| | Etapa | Paradigma | Lenguaje | Responsabilidad |
|:-:|---|---|---|---|
| 🟦 | **Etapa 1** | Imperativo | **C99** | Ingesta, saneamiento, validación semántica, cálculo de elegibilidad académica y detección de traslapes en bloques de tiempo. |
| 🟪 | **Etapa 2** | Funcional | **Typed Racket** | Modelado inmutable con tipos estáticos explícitos, funciones de orden superior con polimorfismo paramétrico, evaluación perezosa mediante *streams*, generación combinatoria sin mutación de estado, filtrado por rango de créditos y exportación de las combinaciones a `data/horarios_finales.json` para la Etapa 3 (Prolog). |

---

## 2. Arquitectura y Flujo del Pipeline

El motor en C opera como una tubería de **extracción, transformación y validación (ETL)** que produce `data/output_schedule.json`. Este archivo es consumido, junto con `data/preferencias.json`, por los módulos funcionales en Racket, que generan las combinaciones sin choques, las filtran por rango de créditos y exportan `data/horarios_finales.json`, el contrato de entrada de la Etapa 3 (Prolog).

```mermaid
flowchart TD
    subgraph IN["Entradas (data/)"]
        A1["plan_estudios.json"]
        A2["historial_estudiante.json"]
    end

    subgraph C["🟦 ETAPA 1 · C99 (etapa1_c)"]
        B1["parser.c<br/>Ingesta"]
        B2["Catalog + StudentHistory"]
        B3["validator.c<br/>Saneamiento y certificación"]
        B4["prereq_checker.c<br/>Elegibilidad + correquisitos"]
        B5["schedule_checker.c<br/>Detección de traslapes"]
        B6["exporter.c<br/>Serialización"]
    end

    ERR(["Aborta proceso (stderr)"])
    OUT[("output_schedule.json")]
    OUT2[("horarios_finales.json")]
    NEXT(["🟧 ETAPA 3 · Prolog"])
    PREF["preferencias.json"]

    subgraph R["🟪 ETAPA 2 · Typed Racket (parte2_racket)"]
        D1["json_reader.rkt<br/>parser.rkt"]
        D2["filters.rkt<br/>Polimorfismo paramétrico"]
        D3["Candidatos tipados<br/>(Listof (Listof SelectedGroup))"]
        D4["generator.rkt<br/>Combinaciones sin choques"]
        D5["exporter.rkt<br/>Stream + filtro de créditos + JSON"]
    end

    A1 --> B1
    A2 --> B1
    B1 --> B2 --> B3
    B3 -- "Fallo semántico" --> ERR
    B3 -- "Datos conformes" --> B4 --> B5 --> B6 --> OUT
    OUT --> D1
    PREF --> D1
    D1 --> D2 --> D3 --> D4 --> D5 --> OUT2 --> NEXT

    classDef input fill:#fff3cd,stroke:#e0a800,color:#533f03;
    classDef cstage fill:#ddf4ff,stroke:#1f6feb,color:#0a3069;
    classDef rstage fill:#f3e8ff,stroke:#8957e5,color:#3b1f72;
    classDef error fill:#ffebe9,stroke:#cf222e,color:#82071e;
    classDef output fill:#dafbe1,stroke:#1a7f37,color:#0f4620;

    class A1,A2,PREF,NEXT input;
    class B1,B2,B3,B4,B5,B6 cstage;
    class D1,D2,D3,D4,D5 rstage;
    class ERR error;
    class OUT,OUT2 output;
```

<details>
<summary>Ver versión en texto plano del pipeline</summary>

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
                  [ json_reader.rkt / parser.rkt ] ◄── [ data/preferencias.json ]
                              │
                              ▼
              [ filters.rkt (Polimorfismo Paramétrico) ]
                              │
                              ▼
            [ Candidatos Tipados: (Listof (Listof SelectedGroup)) ]
                              │
                              ▼
                [ generator.rkt: generar-combinaciones ]
                              │   (Listof ScheduleCombination)
                              ▼
   [ exporter.rkt: list->lazy-stream → filtrar-rango-creditos → JSON ]
                              │
                              ▼
                [ data/horarios_finales.json ]
                              │
                              ▼  (Entrada Etapa 3)
                          [ Prolog ]
```

</details>

### Fases de Ejecución de la Etapa 1

| Fase | Módulo | Descripción |
|:-:|---|---|
| **1** | `parser.c` | **Ingesta y deserialización.** Extrae datos jerárquicos desde los JSON de entrada y puebla las estructuras estáticas en memoria. |
| **2** | `validator.c` | **Saneamiento y certificación.** Normaliza cadenas, verifica integridad referencial, prohíbe cursos fantasma o auto-requisitos y asegura cronología horaria válida. |
| **3** | `prereq_checker.c` | **Resolución académica.** Calcula si una materia no aprobada cuenta con todos sus prerrequisitos y correquisitos viables. |
| **4** | `schedule_checker.c` | **Análisis temporal de colisiones.** Detecta traslapes horarios entre asignaturas elegibles de la misma carrera. |
| **5** | `exporter.c` | **Serialización estandarizada.** Emite el catálogo con los estados booleanos calculados: `is_approved`, `is_eligible`, `has_clash`, `has_any_schedule_clash`. |

### Fases de Ejecución de la Etapa 2

| Fase | Módulo | Descripción |
|:-:|---|---|
| **1** | `json_reader.rkt` / `parser.rkt` | **Ingesta tipada.** Lee `output_schedule.json` y `preferencias.json` y los convierte a structs inmutables (`Course`, `Preferences`). |
| **2** | `parser.rkt` (`prepare-candidate-courses`) | **Cruce catálogo–preferencias.** Descarta cursos no elegibles, conserva solo los grupos pedidos y entrega una sublista de `SelectedGroup` por curso. |
| **3** | `generator.rkt` | **Generación combinatoria.** Construye recursivamente las combinaciones de un grupo por curso, descartando cualquier grupo que choque con los ya elegidos. |
| **4** | `exporter.rkt` (`list->lazy-stream`, `filtrar-rango-creditos`) | **Streaming y filtrado.** Convierte las combinaciones a `LazyStream` y filtra por `[min_credits, max_credits]` con la función polimórfica. |
| **5** | `exporter.rkt` (`exportar-combinaciones-json`) | **Serialización.** Fuerza el stream nodo por nodo y escribe `data/horarios_finales.json`. |

---

## 3. Estructura de Directorios

```text
ProyectoCEmestre/
│
├── 📁 data/                              # ── Esquemas JSON (entradas y salida) ──
│   ├── historial_estudiante.json         # Materias aprobadas por el estudiante
│   ├── plan_estudios.json                # Catálogo oficial (Semestres 0 al 6)
│   ├── preferencias.json                 # Cursos de interés, grupos y rango de créditos
│   ├── output_schedule.json              # Salida validada generada por C
│   └── horarios_finales.json             # Salida de Racket: combinaciones sin choques (contrato con Prolog)
│
├── 📁 etapa1_c/                          # ── 🟦 Motor imperativo en C99 ──
│   ├── Makefile                          # Script de compilación automatizada
│   │
│   ├── 📁 include/                       # Cabeceras y definiciones de estructuras
│   │   ├── config.h                      # Constantes de dimensionamiento
│   │   ├── exporter.h                    # Interfaz del serializador JSON
│   │   ├── parser.h                      # Interfaz del lector de entrada
│   │   ├── prereq_checker.h              # Interfaz del verificador de requisitos
│   │   ├── schedule_checker.h            # Interfaz del evaluador de horarios
│   │   ├── struct_definitions.h          # Modelado de structs en C
│   │   └── validator.h                   # Interfaz del validador de integridad
│   │
│   └── 📁 src/                           # Código fuente modular
│       ├── exporter.c                    # Escritor del JSON formateado
│       ├── main.c                        # Orquestador del flujo
│       ├── parser.c                      # Lector defensivo de cadenas JSON
│       ├── prereq_checker.c              # Prerrequisitos y correquisitos
│       ├── schedule_checker.c            # Detección de choques en bloques horarios
│       └── validator.c                   # Validador semántico y de formato
│
└── 📁 parte2_racket/                     # ── 🟪 Implementación funcional (Etapa 2) ──
    ├── types.rkt                         # Structs inmutables y LazyStream
    ├── filters.rkt                       # Funciones con polimorfismo paramétrico
    ├── json_reader.rkt                   # Puente de lectura JSON a tuplas nativas
    ├── parser.rkt                        # Conversión tipada y preparación de candidatos
    ├── generator.rkt                     # Motor combinatorio recursivo puro
    ├── exporter.rkt                      # Stream, filtro de créditos y exportación JSON
    └── test.rkt                          # Prueba integral: ingesta, generación, filtrado y exportación
```

### Resumen por zona

| Zona | Carpeta | Rol | Archivos clave |
|:-:|---|---|---|
| 🟨 | `data/` | Contrato de datos entre etapas | `plan_estudios.json`, `historial_estudiante.json`, `preferencias.json`, `output_schedule.json`, `horarios_finales.json` |
| 🟦 | `etapa1_c/include/` | Contratos de tipos e interfaces | `config.h`, `struct_definitions.h` |
| 🟦 | `etapa1_c/src/` | Lógica imperativa | `main.c`, `parser.c`, `validator.c`, `prereq_checker.c`, `schedule_checker.c`, `exporter.c` |
| 🟪 | `parte2_racket/` | Lógica funcional tipada | `types.rkt`, `filters.rkt`, `json_reader.rkt`, `parser.rkt`, `generator.rkt`, `exporter.rkt`, `test.rkt` |

---

## 4. Constantes y Modelado de Datos en C

### 4.1 Constantes de dimensionamiento

Las dimensiones de memoria estática están centralizadas en `etapa1_c/include/config.h`:

<table>
  <thead>
    <tr>
      <th>Constante</th>
      <th align="center">Valor</th>
      <th>Finalidad técnica</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>MAX_COURSES</code></td><td align="center"><code>200</code></td><td>Capacidad máxima de asignaturas simultáneas en el catálogo.</td></tr>
    <tr><td><code>MAX_GROUPS</code></td><td align="center"><code>10</code></td><td>Límite de grupos académicos ofertables por curso.</td></tr>
    <tr><td><code>MAX_SCHEDULES_PER_GROUP</code></td><td align="center"><code>5</code></td><td>Máximo de bloques horarios por grupo.</td></tr>
    <tr><td><code>MAX_PREREQUISITES</code></td><td align="center"><code>10</code></td><td>Límite superior de prerrequisitos por materia.</td></tr>
    <tr><td><code>MAX_COREQUISITES</code></td><td align="center"><code>5</code></td><td>Límite superior de correquisitos por materia.</td></tr>
    <tr><td><code>MAX_APPROVED_COURSES</code></td><td align="center"><code>100</code></td><td>Máximo de asignaturas acreditadas en el expediente.</td></tr>
    <tr><td><code>MAX_SEMESTER</code></td><td align="center"><code>6</code></td><td>Alcance curricular cubierto por el sistema.</td></tr>
    <tr><td><code>MAX_STRING_LEN</code></td><td align="center"><code>100</code></td><td>Tamaño de búfer para nombres y carreras.</td></tr>
    <tr><td><code>MAX_CODE_LEN</code></td><td align="center"><code>15</code></td><td>Tamaño de búfer para códigos alfanuméricos.</td></tr>
    <tr><td><code>DAY_MONDAY</code> – <code>DAY_SATURDAY</code></td><td align="center"><code>1</code> – <code>6</code></td><td>Representación numérica de los días lectivos.</td></tr>
  </tbody>
</table>

### 4.2 Estructuras centrales

Definidas en `etapa1_c/include/struct_definitions.h`:

| Estructura | Campos principales | Descripción |
|---|---|---|
| **`ScheduleBlock`** | `day`, `start_time`, `end_time` | Bloque horario en formato militar (ej. `730` a `1120`; `730` equivale a 07:30 y `1650` a 16:50). |
| **`Group`** | `group_number`, `schedules`, `schedule_count`, `has_clash` | Grupo académico con su arreglo de bloques y bandera individual de choque. |
| **`Course`** | `code`, `name`, `credits`, `semester`, `career`, prerrequisitos, correquisitos, `groups`, `is_approved`, `is_eligible`, `has_any_schedule_clash` | Asignatura completa con dependencias y banderas de decisión. |
| **`Catalog`** | arreglo de cursos, `course_count` | Contenedor global del catálogo. |
| **`StudentHistory`** | `approved_courses`, `approved_count` | Expediente del estudiante (códigos aprobados). |

---

## 5. Descripción Modular de la Etapa 1 (`etapa1_c`)

### 5.1 Verificador de Requisitos · `src/prereq_checker.c`

| Función | Qué hace |
|---|---|
| `is_course_approved` | Comprueba si un código consta en el historial del estudiante. |
| `can_take_course` | Certifica que la materia no haya sido aprobada previamente, que todos sus prerrequisitos estén cumplidos y que sus correquisitos sean simultáneamente matriculables (verificando, a su vez, los requisitos del correquisito). |

### 5.2 Validador Semántico · `src/validator.c`

| Función | Qué hace |
|---|---|
| `sanitize_code` | Limpia espacios residuales y uniforma códigos a mayúsculas. |
| `validate_catalog` | Normaliza códigos, impide cursos duplicados en la misma carrera, verifica que `career` no esté vacío, valida créditos (0 a 10) y semestres (0 a `MAX_SEMESTER`), y detecta requisitos fantasma, auto-dependencias y traslapes internos dentro de un mismo grupo. |
| `validate_student_history` | Asegura que las materias aprobadas existan en el catálogo y no estén duplicadas. |

### 5.3 Motor de Horarios · `src/schedule_checker.c`

| Función | Qué hace |
|---|---|
| `blocks_overlap` | Determina si dos bloques coinciden en día y se intersectan temporalmente. |
| `groups_overlap` | Compara exhaustivamente todos los bloques del Grupo A contra los del Grupo B. |
| `check_schedule_clashes` | Evalúa choques únicamente entre cursos elegibles (`is_eligible == true`) de la misma carrera. Marca `has_clash` por grupo y levanta `has_any_schedule_clash = true` en el curso si todos sus grupos colisionan sin alternativa. |

Regla de intersección horaria en el mismo día:

$$\text{start}_1 < \text{end}_2 \;\land\; \text{start}_2 < \text{end}_1$$

### 5.4 Deserializador y Serializador · `src/parser.c` y `src/exporter.c`

- **`parser.c`:** lectura binaria acotada en memoria (`read_file_to_string`), extracción delimitada de campos (`get_json_string_val`, `get_json_int_val`), captura de arreglos y parseo de llaves balanceadas (`parse_groups_and_schedules`), todo sin librerías externas y con candados de fin de cadena (`\0`) explícitos.
- **`exporter.c`:** escritura estandarizada hacia `data/output_schedule.json`, con control de comas terminales y booleanos nativos.

---

## 6. Actualizaciones de Datos para la Etapa 2

### 6.1 Ampliación curricular a 6 semestres · `data/plan_estudios.json`

Se extendió el catálogo con las guías oficiales de horarios hasta el sexto semestre para **Ingeniería en Computadores** e **Ingeniería en Biotecnología**, alcanzando un total de **91 asignaturas** con múltiples grupos y bloques horarios.

> [!NOTE]
> En `etapa1_c/include/config.h` se definió `MAX_SEMESTER 6` y `etapa1_c/src/validator.c` certifica la presencia del campo `career` y valida semestres en el intervalo $[0, 6]$.

### 6.2 Archivo de preferencias · `data/preferencias.json`

A diferencia de `historial_estudiante.json` (que refleja el pasado académico), este archivo modela la **intención de matrícula inmediata** y define los parámetros de entrada para la generación de horarios en Racket:

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

| Campo | Propósito |
|---|---|
| `min_credits` / `max_credits` | Rango de créditos deseados para el filtrado en Racket. Ambos extremos son **inclusivos** y los aplica `filtrar-rango-creditos` (`exporter.rkt`). |
| `career` (por curso) | Evita ambigüedades en materias compartidas entre carreras. Si se deja vacío (`""`), `prepare-candidate-courses` acepta el primer curso elegible con ese código. |
| `groups` | Permite seleccionar múltiples grupos alternativos para un mismo curso de interés. |

---

## 🟪 7. Arquitectura Funcional en Racket (`parte2_racket`)

La base funcional está construida con **Typed Racket** (`#lang typed/racket`), lo que garantiza verificación estática de tipos, inmutabilidad por defecto y ausencia de efectos secundarios.

### 7.1 Modelado de tipos e inmutabilidad · `types.rkt`

Todas las estructuras del dominio son inmutables (`struct` sin `#:mutable`), y el módulo exporta constructores y selectores.

| Tipo | Campos | Descripción |
|---|---|---|
| **`LazyStream` / `StreamNode`** | `first`, promesa `(Promise (LazyStream A))` | Secuencias perezosas tipadas. Posterga la evaluación del resto del flujo con `delay` y la reclama bajo demanda con `force`. |
| **`ScheduleBlock`** | `[day : Integer]`, `[start-time : Integer]`, `[end-time : Integer]` | Bloque horario. |
| **`Group`** | `[group-number : Integer]`, `[has-clash : Boolean]`, `[schedules : (Listof ScheduleBlock)]` | Grupo con sus bloques. |
| **`Course`** | banderas `is-approved`, `is-eligible` y lista de grupos | Curso completo proveniente de C. |
| **`InterestedCourse`** y **`Preferences`** | `min-credits`, `max-credits`, `interested-courses` | Datos leídos desde `data/preferencias.json`. |
| **`SelectedGroup`** | `code`, `name`, `career`, `credits`, `group-number`, `has-clash`, `schedules` | **Estructura clave del generador.** Aplana una opción específica de matrícula uniendo los datos del curso con un grupo concreto. |
| **`ScheduleCombination`** | `[selections : (Listof SelectedGroup)]`, `[total-credits : Integer]` | Horario completo armado. |

### 7.2 Polimorfismo paramétrico · `filters.rkt`

Cumple el criterio de **Polimorfismo Paramétrico** mediante firmas genéricas `(All (A) ...)`, reutilizando la misma lógica sobre cualquier tipo (`Course`, `Group`, `SelectedGroup` o `ScheduleCombination`).

#### `filtrar-lista-polimorfico`

```racket
(: filtrar-lista-polimorfico (All (A) (-> (-> A Boolean) (Listof A) (Listof A))))
```

Recorre recursivamente una lista inmutable de elementos de tipo `A` y conserva únicamente los que satisfacen el predicado `(-> A Boolean)`, sin mutar variables.

#### `filtrar-stream-polimorfico`

```racket
(: filtrar-stream-polimorfico (All (A) (-> (-> A Boolean) (LazyStream A) (LazyStream A))))
```

Filtra un `LazyStream` de manera perezosa: evalúa el nodo actual (`StreamNode-first`) y envuelve la llamada recursiva del resto del flujo dentro de `(delay ...)`.

#### `stream->list-polimorfico`

```racket
(: stream->list-polimorfico (All (A) (-> (LazyStream A) (Listof A))))
```

Fuerza recursivamente las promesas de un `LazyStream` para convertirlo en una lista estándar cuando se requiera exportar el resultado final.

### 7.3 Ingesta segura y cruce de datos · `json_reader.rkt` y `parser.rkt`

> [!NOTE]
> Para evitar conflictos con el supertipo opaco `HashTableTop` de Racket 9.3 CS, la lectura se divide en dos capas.

| Capa | Lenguaje | Responsabilidad |
|---|---|---|
| **`json_reader.rkt`** | `#lang racket` | Lee `output_schedule.json` y `preferencias.json` con la librería nativa `json` y transforma los objetos en **tuplas inmutables**. |
| **`parser.rkt`** | `#lang typed/racket` | Importa las tuplas mediante `require/typed` con contratos de tipos estrictos y construye las estructuras tipadas con *pattern matching* (`match-define`). |

Funciones públicas de `parser.rkt`:

| Función | Entrada | Retorna |
|---|---|---|
| `load-catalog-from-json` | Ruta de `output_schedule.json` | `(Listof Course)` |
| `load-preferences-from-json` | Ruta de `preferencias.json` | `Preferences` |
| `prepare-candidate-courses` | Catálogo + preferencias | `(Listof (Listof SelectedGroup))` |

`prepare-candidate-courses` cruza el catálogo con las preferencias invocando **tres veces** a `filtrar-lista-polimorfico` (con tipos `Course`, `Group` y `(Listof SelectedGroup)`). Descarta cursos no elegibles (`is-eligible = #f`) y conserva únicamente los números de grupo deseados por el estudiante.

### 7.4 Generador de combinaciones · `generator.rkt`

Recibe la salida de `prepare-candidate-courses` y produce todas las combinaciones válidas: **un grupo por curso y sin traslapes entre los grupos elegidos**. Solo exporta `generar-combinaciones`; el resto son auxiliares privadas.

| Función | Firma | Qué hace |
|---|---|---|
| `bloques-chocan?` | `(-> ScheduleBlock ScheduleBlock Boolean)` | Dos bloques chocan si son del mismo día y se intersectan. Es la misma regla de `schedule_checker.c`, por lo que dos bloques contiguos (el fin de uno igual al inicio del otro) **no** chocan. |
| `choca-con-lista?` | `(-> ScheduleBlock (Listof ScheduleBlock) Boolean)` | Recorre recursivamente una lista de bloques y se detiene en el primer choque. |
| `grupo-valido-en-combinacion?` | `(-> SelectedGroup (Listof SelectedGroup) Boolean)` | Aplana con `append-map` los bloques de los grupos ya elegidos y verifica con `ormap` que ningún bloque del grupo nuevo choque con ellos. |
| `generar-combinaciones` | `(-> (Listof (Listof SelectedGroup)) (Listof ScheduleCombination))` | Función principal. Recursión estructural sobre la lista de cursos. |

**Algoritmo de `generar-combinaciones`:**

1. **Caso base.** Con `'()` devuelve `(list (ScheduleCombination '() 0))`: una única combinación vacía con 0 créditos, que actúa como elemento neutro.
2. **Paso recursivo.** Obtiene `combinaciones-resto` llamándose con `(cdr lista)`. Luego, para cada grupo del curso actual (`append-map`), recorre `combinaciones-resto` con `filter-map`:
   - si `grupo-valido-en-combinacion?` es verdadero, produce `(ScheduleCombination (cons grupo selecciones) (+ créditos-grupo créditos-resto))`;
   - si hay choque, devuelve `#false` y esa combinación parcial **se descarta en ese punto y nunca se extiende**.

Los créditos se acumulan incrementalmente al construir cada combinación, sin recorrer la lista al final. Las selecciones de cada combinación quedan en el mismo orden en que los cursos aparecen en `preferencias.json`, y las combinaciones se ordenan por el grupo del primer curso.

**Ejemplo:** con `CE1107` (grupos 1 y 2) y `MA1102` (grupo 1), si el grupo 2 de `CE1107` choca con `MA1102-G1`, el resultado es una sola combinación: `[CE1107-G1, MA1102-G1]`.

> [!NOTE]
> En el peor caso el número de combinaciones es el producto de la cantidad de grupos solicitados por curso. La poda al insertar reduce el trabajo, pero el generador devuelve una lista completa (`Listof ScheduleCombination`); ver la decisión 6 en la [sección 12.1](#121-justificación-de-decisiones-propias).

### 7.5 Exportador · `exporter.rkt`

Convierte las combinaciones a un `LazyStream`, las filtra por créditos y las escribe a disco. Exporta tres funciones públicas.

| Función | Firma | Qué hace |
|---|---|---|
| `list->lazy-stream` | `(-> (Listof ScheduleCombination) (LazyStream ScheduleCombination))` | Convierte recursivamente una lista en un stream: `'()` marca el fin y cada `StreamNode` guarda su resto bajo `(delay ...)`. |
| `filtrar-rango-creditos` | `(-> Integer Integer (LazyStream ScheduleCombination) (LazyStream ScheduleCombination))` | Filtra el stream conservando las combinaciones con `min <= total-credits <= max` (extremos inclusivos). |
| `exportar-combinaciones-json` | `(-> String (LazyStream ScheduleCombination) Void)` | Escribe el stream en la ruta indicada como un arreglo JSON. Sobrescribe el archivo si existe (`#:exists 'replace`). |

**`filtrar-rango-creditos` no define recursión propia.** Es la instancia de `filtrar-stream-polimorfico` con `A = ScheduleCombination` y un predicado de rango. Es la misma función genérica que `parser.rkt` usa sobre listas de `Course`, `Group` y `(Listof SelectedGroup)`.

**Funciones privadas de formato** (construyen el texto JSON sin librerías externas):

| Función | Firma | Qué hace |
|---|---|---|
| `formato-grupo-json` | `(-> SelectedGroup String)` | Serializa un objeto `{course_code, group_number, career}`. |
| `grupos->json` | `(-> (Listof SelectedGroup) String)` | Une los objetos con `",\n"` por recursión. Evita coma final con tres casos: lista vacía, último elemento y resto. |
| `formato-combinacion-json` | `(-> ScheduleCombination String)` | Serializa `{total_credits, selections: [...]}`. |
| `escribir-stream-json` | `(-> Output-Port (LazyStream ScheduleCombination) Boolean Void)` | Recorre el stream forzando **un nodo a la vez** y escribe cada combinación apenas se obtiene. |

**Manejo de las comas sin mutación.** `escribir-stream-json` recibe un parámetro `es-primero?`: la coma separadora se escribe solo cuando es `#false`, y la llamada recursiva (en posición de cola) pasa `#false`. El estado se lleva en el argumento de la recursión, sin contadores ni variables reasignadas.

**Uso desde `test.rkt`:**

```racket
(define flujo-inicial  (list->lazy-stream combinaciones))
(define flujo-filtrado (filtrar-rango-creditos
                        (Preferences-min-credits prefs)
                        (Preferences-max-credits prefs)
                        flujo-inicial))
(exportar-combinaciones-json "../data/horarios_finales.json" flujo-filtrado)
```

### 7.6 Archivo de salida · `data/horarios_finales.json`

Es el **contrato de la Etapa 3 (Prolog)**. Contiene un arreglo JSON en el nivel superior, con un objeto por combinación válida (sin choques y dentro del rango de créditos).

```json
[
  {
    "total_credits": 8,
    "selections": [
        {
          "course_code": "CE1107",
          "group_number": 1,
          "career": "Ingeniería en Computadores"
        },
        {
          "course_code": "MA1102",
          "group_number": 1,
          "career": "Ingeniería en Computadores"
        }
    ]
  }
]
```

| Campo | Tipo | Origen | Requisito de la etapa que cubre |
|---|---|---|---|
| `total_credits` | entero | `ScheduleCombination-total-credits` | Créditos totales |
| `selections` | arreglo de objetos | `ScheduleCombination-selections` | Lista de pares curso-grupo |
| `selections[].course_code` | cadena | `SelectedGroup-code` | Curso del par curso-grupo |
| `selections[].group_number` | entero | `SelectedGroup-group-number` | Grupo del par curso-grupo |
| `selections[].career` | cadena | `SelectedGroup-career` | Carrera de origen de cada curso |

**Garantías del archivo:**

- Ninguna combinación tiene dos grupos con bloques traslapados.
- Todo `total_credits` cumple `min_credits <= total_credits <= max_credits` (inclusivo).
- Cada combinación tiene como máximo un grupo por curso, y solo de los cursos de interés que están habilitados (`is_eligible`).
- Las `selections` conservan el orden de `preferencias.json`.
- El archivo siempre es JSON válido, también cuando ninguna combinación cumple el rango (en ese caso queda `[` + línea vacía + `]`).
- No se agregaron campos adicionales a los exigidos por la etapa. La justificación está en la [sección 12.3](#123-justificación-del-formato-de-salida).

---

## 8. Guía de Integración para Desarrolladores (Etapa 2)

Esta sección detalla cómo los demás integrantes del equipo deben consumir los módulos base para implementar el **generador de combinaciones** (`generator.rkt`) y el **exportador de streams** (`exporter.rkt`).

### 8.1 Importación en nuevos archivos `.rkt`

Todo archivo nuevo en `parte2_racket/` debe iniciar con `#lang typed/racket` e importar los módulos base:

```racket
#lang typed/racket

(require "types.rkt"
         "filters.rkt"
         "parser.rkt")
```

### 8.2 Qué recibe el motor generador · `generator.rkt`

Al llamar a `(prepare-candidate-courses catalogo prefs)` se obtiene un valor de tipo:

```racket
(Listof (Listof SelectedGroup))
```

**Estructura de los datos:** cada sublista interna representa un curso válido que el estudiante quiere matricular, y dentro de ella vienen las opciones de grupos (`SelectedGroup`) solicitadas.

**Ejemplo práctico:** si el estudiante pidió `CE1107` (Grupos 1 y 2) y `MA1102` (Grupo 1), `prepare-candidate-courses` entrega:

```racket
(list
  (list (SelectedGroup "CE1107" ... 1 ...) (SelectedGroup "CE1107" ... 2 ...)) ; Opciones para CE1107
  (list (SelectedGroup "MA1102" ... 1 ...)))                                   ; Opciones para MA1102
```

#### Acceso a los campos de un `SelectedGroup`

| Selector | Retorna | Ejemplo |
|---|---|---|
| `(SelectedGroup-code sg)` | `String` | `"CE1107"` |
| `(SelectedGroup-group-number sg)` | `Integer` | `1` |
| `(SelectedGroup-credits sg)` | `Integer` | `4` |
| `(SelectedGroup-schedules sg)` | `(Listof ScheduleBlock)` | lista de bloques |

#### Acceso a cada bloque horario (`ScheduleBlock`) para verificar choques

| Selector | Retorna | Ejemplo |
|---|---|---|
| `(ScheduleBlock-day blk)` | `Integer` | `1` a `6` |
| `(ScheduleBlock-start-time blk)` | `Integer` | `730` |
| `(ScheduleBlock-end-time blk)` | `Integer` | `1120` |

### 8.3 Cómo construir y filtrar streams perezosos · `exporter.rkt`

**Crear un nodo en el stream perezoso:**

```racket
(StreamNode combinacion-actual
            (delay (generar-resto-de-combinaciones ...)))
```

**Filtrar el stream por rango de créditos** usando la función polimórfica:

```racket
(define horarios-en-rango
  (filtrar-stream-polimorfico
   (lambda ([comb : ScheduleCombination])
     (and (>= (ScheduleCombination-total-credits comb) (Preferences-min-credits prefs))
          (<= (ScheduleCombination-total-credits comb) (Preferences-max-credits prefs))))
   flujo-horarios-sin-choques))
```

`exporter.rkt` ya encapsula este filtro en `filtrar-rango-creditos`, por lo que no hace falta reescribir el predicado:

```racket
(filtrar-rango-creditos (Preferences-min-credits prefs)
                        (Preferences-max-credits prefs)
                        flujo-horarios-sin-choques)
```

### 8.4 Pipeline completo de la Etapa 2

```racket
#lang typed/racket

(require "types.rkt" "parser.rkt" "generator.rkt" "exporter.rkt")

(define catalogo   (load-catalog-from-json "../data/output_schedule.json"))
(define prefs      (load-preferences-from-json "../data/preferencias.json"))
(define candidatos (prepare-candidate-courses catalogo prefs))   ; (Listof (Listof SelectedGroup))
(define combos     (generar-combinaciones candidatos))           ; (Listof ScheduleCombination)

(exportar-combinaciones-json
 "../data/horarios_finales.json"
 (filtrar-rango-creditos (Preferences-min-credits prefs)
                         (Preferences-max-credits prefs)
                         (list->lazy-stream combos)))
```

Las rutas son relativas, por lo que el programa debe ejecutarse desde `parte2_racket/`.
---

## 9. Compilación y Ejecución

### 9.1 🟦 Etapa 1 · Lenguaje C

**Compilación con Makefile** desde el directorio `etapa1_c/`:

```bash
make
```

**Compilación manual alternativa con GCC:**

```bash
gcc -Wall -Wextra -std=c99 -Iinclude src/*.c -o cemestre_c
```

**Ejecución del binario.** Debe lanzarse desde dentro de `etapa1_c/` para resolver las rutas relativas `../data/`:

| Sistema | Comando |
|---|---|
| Windows (PowerShell / CMD) | `.\cemestre_c.exe` |
| Linux / macOS | `./cemestre_c` |

**Salida esperada:**

```text
Proceso completado con éxito. Resultados guardados en ../data/output_schedule.json
```

> [!TIP]
> En entornos Windows sin `rm` nativo en el Path, para limpiar los archivos compilados se puede ejecutar en PowerShell:
>
> ```powershell
> Remove-Item -Force -ErrorAction SilentlyContinue cemestre_c.exe, *.o
> ```

### 9.2 🟪 Etapa 2 · Typed Racket

1. Abrir **DrRacket** y cargar el archivo `parte2_racket/test.rkt` (o `main.rkt` una vez integrado).
2. Presionar el botón **Run** (`Ctrl + R`).
3. El sistema leerá `../data/output_schedule.json` y `../data/preferencias.json`, ejecutará la validación de tipos y el filtrado polimórfico, mostrará en consola los cursos candidatos y las combinaciones sin choques, y escribirá `../data/horarios_finales.json` (secciones 1 a 5 de la prueba).
4. También puede ejecutarse desde la terminal, dentro de `parte2_racket/` (las rutas `../data/` son relativas a esa carpeta):

```bash
racket test.rkt
```

> [!IMPORTANT]
> `data/output_schedule.json` debe existir antes de ejecutar Racket: hay que correr primero la Etapa 1 (sección 9.1). Si `horarios_finales.json` ya existe, se sobrescribe.

---

## 10. Batería de Comandos de Inspección y Pruebas

Todos los comandos se ejecutan desde `etapa1_c/` y permiten auditar `data/output_schedule.json`.

### Windows (PowerShell)

**1. Listar cursos de semestres 5 y 6:**

```powershell
(Get-Content -Raw -Path "..\data\output_schedule.json" | ConvertFrom-Json) | Where-Object { $_.semester -ge 5 } | Select-Object code, semester, career, is_eligible
```

**2. Verificar elegibilidad de una asignatura de semestre 5 (`CE1107`):**

```powershell
(Get-Content -Raw -Path "..\data\output_schedule.json" | ConvertFrom-Json) | Where-Object { $_.code -eq "CE1107" } | Select-Object code, name, semester, career, is_eligible, is_approved
```

**3. Auditar cantidad de cursos por semestre:**

```powershell
(Get-Content -Raw -Path "..\data\output_schedule.json" | ConvertFrom-Json) | Group-Object semester | Select-Object Name, Count | Sort-Object Name
```

**4. Contar el total de asignaturas exportadas:**

```powershell
(Get-Content -Raw -Path "..\data\output_schedule.json" | ConvertFrom-Json).Count
```

### Linux / macOS (Bash + `jq`)

**1. Listar cursos de semestres 5 y 6:**

```bash
jq '.[] | select(.semester >= 5) | {code, semester, career, is_eligible}' ../data/output_schedule.json
```

**2. Inspeccionar el estado detallado de `CE1107`:**

```bash
jq '.[] | select(.code == "CE1107") | {code, name, semester, is_eligible, is_approved}' ../data/output_schedule.json
```

**3. Conteo total de asignaturas registradas:**

```bash
jq 'length' ../data/output_schedule.json
```

### Inspección de `data/horarios_finales.json` (salida de Racket)

Los rangos de ejemplo (8 y 16) corresponden al `preferencias.json` de la sección 6.2; deben ajustarse si se modifican las preferencias.

**Windows (PowerShell)**

```powershell
# Cantidad de combinaciones exportadas
(Get-Content -Raw -Path "..\data\horarios_finales.json" | ConvertFrom-Json).Count

# Mínimo y máximo de créditos (deben quedar dentro de [min_credits, max_credits])
(Get-Content -Raw -Path "..\data\horarios_finales.json" | ConvertFrom-Json) | Measure-Object total_credits -Minimum -Maximum

# Primera combinación completa
(Get-Content -Raw -Path "..\data\horarios_finales.json" | ConvertFrom-Json)[0] | ConvertTo-Json -Depth 4
```

**Linux / macOS (Bash + `jq`)**

```bash
# Cantidad de combinaciones exportadas
jq 'length' ../data/horarios_finales.json

# Validar el rango: debe imprimir 0
jq '[.[] | select(.total_credits < 8 or .total_credits > 16)] | length' ../data/horarios_finales.json

# Primera combinación
jq '.[0]' ../data/horarios_finales.json

# Pares curso-grupo de cada combinación en una línea
jq -r '.[] | "\(.total_credits) cr: " + ([.selections[] | "\(.course_code)-G\(.group_number)"] | join(", "))' ../data/horarios_finales.json
```

---

## 11. Manejo Defensivo y Casos Límite

| Caso | Cómo lo resuelve el sistema |
|---|---|
| **Desambiguación por carrera (`career`)** | Tanto en C (`validator.c` y `schedule_checker.c`) como en Racket (`prepare-candidate-courses`), los cursos se identifican por el par `(code, career)`. Esto resuelve el caso en que materias generales (ej. `MA0101`, `MA1102`, `CS1502`) comparten código en planes de estudio distintos. |
| **Aislamiento por carrera en choques** | Dos grupos con horarios idénticos no se marcan en colisión si pertenecen a carreras distintas, garantizando coherencia para estudiantes que cursan planes independientes. |
| **Independencia del nivel semestral en choques** | El motor evalúa colisiones entre cualesquiera dos cursos elegibles sin restringirlos al mismo semestre, soportando matrículas con cursos de rezago o adelanto. |
| **Prevención de ciclos de correquisitos** | La comprobación en `prereq_checker.c` valida la matriculabilidad de la materia par sin permitir recursión infinita. |
| **Tolerancia cero ante datos corruptos** | `validator.c` detiene la ejecución si detecta auto-dependencias, referencias a cursos inexistentes o intervalos de tiempo militar inconsistentes, evitando que datos corruptos lleguen a Racket. |
| **Frontera tipada contra datos dinámicos** | En `parte2_racket`, `require/typed` junto con desestructuración por patrones (`match-define`) garantiza que ningún dato malformado proveniente de un JSON externo viole las invariantes de tipos de Typed Racket. |
| **Curso de interés sin grupos utilizables** | Si un curso pedido no es elegible o ninguno de sus grupos solicitados existe, `prepare-candidate-courses` elimina su sublista vacía. Así no anula todas las combinaciones de los demás cursos (detalle en la [sección 12.2](#122-caso-límite-real-curso-de-interés-sin-grupos-utilizables)). |
| **Combinación vacía** | El caso base de `generar-combinaciones` devuelve una combinación con 0 créditos. Si no queda ningún curso candidato, esa combinación solo supera el filtro cuando `min_credits` es 0. |
| **Choques entre carreras en la combinación final** | `generator.rkt` compara los bloques de todos los grupos elegidos sin importar su carrera, porque el estudiante asistiría a todos. Esto es independiente de `has_clash`, que la Etapa 1 calcula solo entre cursos de la misma carrera. |
| **Resultado vacío tras el filtro de créditos** | Si ninguna combinación cumple el rango, `exportar-combinaciones-json` escribe `[`, una línea vacía y `]`, que sigue siendo JSON válido para la Etapa 3. |
| **Límites del rango de créditos** | Los extremos son inclusivos: una combinación con exactamente `min_credits` o `max_credits` créditos se exporta. |
| **Cadenas sin escape en la exportación** | `formato-grupo-json` inserta `code` y `career` tal cual, sin escapar comillas ni barras. Es seguro porque `validator.c` ya sanitiza los códigos y las carreras del catálogo; un valor con `"` o `\` produciría JSON inválido. |

---

## 12. Decisiones de Diseño de la Etapa 2

### 12.1 Justificación de decisiones propias

| # | Decisión | Alternativa descartada | Justificación |
|:-:|---|---|---|
| 1 | **Generación recursiva con la combinación como valor inmutable** (`ScheduleCombination` se reconstruye con `cons` en cada paso). | Acumular en una lista o contador mutable. | Cumple la restricción de no usar `set!` ni estructuras mutables. Los créditos viajan dentro de la combinación y se suman al construirla. |
| 2 | **Poda al insertar** cada grupo: `grupo-valido-en-combinacion?` se evalúa antes de crear la combinación. | Generar el producto cartesiano completo y filtrar los choques después. | Una combinación parcial con choque se descarta de inmediato y nunca se extiende, con lo que se evita construir las combinaciones completas inválidas. |
| 3 | **Recalcular los choques en Racket** en vez de usar `has-clash` de `SelectedGroup`. | Descartar todo grupo con `has-clash = #t`. | `has_clash` (Etapa 1) indica que el grupo choca con algún otro grupo del catálogo, no que choque con los grupos *concretamente elegidos*. Descartarlo eliminaría combinaciones válidas. Además, la Etapa 1 solo compara dentro de una misma carrera y la combinación final debe comparar todo. |
| 4 | **`filtrar-rango-creditos` como instancia de `filtrar-stream-polimorfico`**, no como recursión nueva. | Escribir un filtro de créditos específico sobre el stream. | El criterio de la etapa pide una función reutilizable para más de un tipo de filtro. Un cambio de criterio (otro rango, otro predicado) solo cambia el predicado. |
| 5 | **Responsabilidades separadas:** `generator.rkt` no conoce créditos ni formato, y `exporter.rkt` no conoce choques. | Filtrar créditos dentro del generador. | Sigue el orden pedido (generar, filtrar, exportar) y permite probar y modificar cada pieza por separado. |
| 6 | **El stream se construye desde la lista generada** (`list->lazy-stream`). La pereza se aprovecha en el filtrado y en la escritura, que fuerzan un nodo a la vez. | Un generador que produzca el stream directamente. | `generar-combinaciones` devuelve `(Listof ScheduleCombination)`, de modo que el stream se arma una vez generada la lista. Esta decisión dejó el generador simple y verificable, a costa de que la lista completa exista en memoria antes del filtrado. |
| 7 | **Escritura incremental** con `escribir-stream-json`: cada combinación se escribe apenas se fuerza su nodo. | Construir un único `String` o `jsexpr` con todo el archivo y volcarlo al final. | No se materializa el documento completo. Además evita la frontera con `HashTableTop` de `jsexpr` en Typed Racket (sección 7.3). |
| 8 | **JSON armado con `string-append`**, sin librería de serialización. | `write-json` sobre una estructura `jsexpr`. | Permite escribir elemento por elemento, controlar la indentación y mantener tipos estáticos simples (`String`) en todo `exporter.rkt`. |
| 9 | **Coma separadora mediante el parámetro `es-primero?`** de la recursión. | Contador o bandera reasignada con `set!`. | Resuelve el estado con recursión e inmutabilidad, como exige la etapa. La llamada recursiva está en posición de cola, así que el recorrido usa pila constante. |
| 10 | **Rango de créditos inclusivo** en ambos extremos. | Extremo superior exclusivo. | Coincide con la semántica de «créditos mínimos y máximos deseados» del enunciado. |
| 11 | **Combinaciones con un solo grupo por curso de interés** y solo de los cursos habilitados (`is_eligible`). | Permitir cursos no elegibles. | Respeta la validación de requisitos y correquisitos hecha en C; Racket no la repite. |

### 12.2 Caso límite real: curso de interés sin grupos utilizables

**Situación.** Un curso listado en `preferencias.json` puede no aportar ningún grupo: porque no es elegible (`is_eligible = #f`), porque no aparece en el catálogo con esa carrera, o porque ninguno de los números de grupo pedidos existe. Por ejemplo, `interested_courses` pide `CE1107` (grupos 1 y 2) y otro curso con un grupo inexistente.

**Problema.** `prepare-candidate-courses` produce una sublista vacía `'()` para ese curso. Si esa sublista llegara a `generar-combinaciones`, el `append-map` sobre sus grupos devolvería `'()`. Como cada nivel de la recursión se apoya en el resultado del siguiente, **el resultado final sería vacío** aunque los demás cursos tuvieran combinaciones válidas.

**Resolución.** La última expresión de `prepare-candidate-courses` descarta las sublistas vacías con el mismo filtro polimórfico:

```racket
(filtrar-lista-polimorfico
 (lambda ([lst : (Listof SelectedGroup)]) (not (null? lst)))
 grouped-options)
```

El curso sin grupos utilizables se ignora y las combinaciones se arman con el resto.

**Caso relacionado: ningún curso utilizable.** Si todas las sublistas se descartan, `generar-combinaciones` recibe `'()` y devuelve la combinación vacía del caso base (0 créditos). Esa combinación pasa por `filtrar-rango-creditos` y solo se exporta si `min_credits` es 0. En el caso habitual queda un arreglo vacío válido (`[`, línea vacía, `]`), y la Etapa 3 recibe JSON bien formado.

### 12.3 Justificación del formato de salida

**Formato elegido: JSON** (`data/horarios_finales.json`), como arreglo de objetos con una combinación por elemento.

| Decisión del formato | Decisión de diseño a la que responde |
|---|---|
| **JSON en lugar de CSV.** | Una combinación es una estructura anidada (total de créditos y una lista de pares curso-grupo de largo variable). En CSV habría que repetir el total en cada fila de una combinación o codificar la lista dentro de una celda con un delimitador propio. |
| **Un objeto por combinación, escrito al forzar cada nodo del stream.** | Es el reflejo de la decisión 7: cada elemento del `LazyStream` se convierte en un objeto JSON independiente, y el arreglo se cierra al terminar el stream. El formato se adapta a la escritura incremental. |
| **Mismo formato y convención `snake_case` que `output_schedule.json` y `preferencias.json`** (`group_number`, `total_credits`). | Toda la tubería usa JSON entre etapas; el consumidor de Prolog trabaja con un único formato y nomenclatura en todos los archivos de entrada. |
| **Solo `course_code`, `group_number` y `career` por selección, más `total_credits`.** | Son los campos que pide la etapa. El par `(course_code, career)` es la misma identidad que se usa en toda la tubería (sección 11), así que Prolog puede cruzar con `output_schedule.json` para obtener nombre, créditos por curso u horarios sin duplicarlos en cada una de las combinaciones, cuyo número crece con el producto de los grupos. |
| **`total_credits` precalculado.** | Ya se acumula al construir la combinación (decisión 1), y la regla de créditos máximos de Prolog puede aplicarse sin recalcular. |
| **Arreglo vacío válido cuando no hay resultados.** | El consumidor siempre recibe JSON bien formado. Un archivo vacío o truncado haría fallar la lectura en Prolog. |

> [!NOTE]
> Si la Etapa 3 requiere más datos por combinación (por ejemplo, créditos por curso o bloques horarios para reglas de compatibilidad), basta con agregar nuevas llaves a los objetos de `formato-grupo-json` y `formato-combinacion-json`. Los lectores JSON ignoran las llaves que no usan, por lo que los campos actuales no se rompen.

---

## 13. Estructuras de Datos Desarrolladas

Todas las estructuras de `parte2_racket/types.rkt` son `struct` inmutables y `#:transparent`; el módulo las publica con `(provide (all-defined-out))`.

### 13.1 Tipos de `types.rkt` (campos completos)

**Secuencia perezosa**

```racket
(define-type (LazyStream A) (U Null (StreamNode A)))

(struct (A) StreamNode
  ([first : A]
   [rest  : (Promise (LazyStream A))]))
```

`'()` (`Null`) marca el fin del flujo; no se usa una estructura centinela. Para obtener el resto del flujo se aplica `force` a `StreamNode-rest`.

**Estructuras de dominio**

| Struct | Campo | Tipo |
|---|---|---|
| **`ScheduleBlock`** | `day` | `Integer` (1 a 6) |
| | `start-time` | `Integer` (formato militar, ej. `730`) |
| | `end-time` | `Integer` |
| **`Group`** | `group-number` | `Integer` |
| | `has-clash` | `Boolean` |
| | `schedules` | `(Listof ScheduleBlock)` |
| **`Course`** | `code`, `name`, `career` | `String` |
| | `credits`, `semester` | `Integer` |
| | `is-approved`, `is-eligible`, `has-any-schedule-clash` | `Boolean` |
| | `prerequisites`, `corequisites` | `(Listof String)` |
| | `groups` | `(Listof Group)` |
| **`InterestedCourse`** | `code`, `career` | `String` |
| | `groups` | `(Listof Integer)` |
| **`Preferences`** | `min-credits`, `max-credits` | `Integer` |
| | `interested-courses` | `(Listof InterestedCourse)` |
| **`SelectedGroup`** | `code`, `name`, `career` | `String` |
| | `credits`, `group-number` | `Integer` |
| | `has-clash` | `Boolean` |
| | `schedules` | `(Listof ScheduleBlock)` |
| **`ScheduleCombination`** | `selections` | `(Listof SelectedGroup)` |
| | `total-credits` | `Integer` |

### 13.2 Transformación de los datos a lo largo de la Etapa 2

| Paso | Función | Tipo de entrada | Tipo de salida |
|:-:|---|---|---|
| 1 | `load-catalog-from-json` | `Path-String` | `(Listof Course)` |
| 2 | `load-preferences-from-json` | `Path-String` | `Preferences` |
| 3 | `prepare-candidate-courses` | `(Listof Course)`, `Preferences` | `(Listof (Listof SelectedGroup))` |
| 4 | `generar-combinaciones` | `(Listof (Listof SelectedGroup))` | `(Listof ScheduleCombination)` |
| 5 | `list->lazy-stream` | `(Listof ScheduleCombination)` | `(LazyStream ScheduleCombination)` |
| 6 | `filtrar-rango-creditos` | `Integer`, `Integer`, `(LazyStream ScheduleCombination)` | `(LazyStream ScheduleCombination)` |
| 7 | `exportar-combinaciones-json` | `String`, `(LazyStream ScheduleCombination)` | `Void` (archivo `horarios_finales.json`) |

### 13.3 Tuplas intermedias de `json_reader.rkt`

`json_reader.rkt` (`#lang racket`) convierte el JSON en listas posicionales con tipos simples. `parser.rkt` las declara con `require/typed` y las transforma a structs con `match-define`.

| Tupla | Posiciones |
|---|---|
| **Curso** `(List String String String Integer Integer Boolean Boolean Boolean (Listof String) (Listof String) (Listof Grupo))` | `code`, `name`, `career`, `credits`, `semester`, `is_approved`, `is_eligible`, `has_any_schedule_clash`, `prerequisites`, `corequisites`, `groups` |
| **Grupo** `(List Integer Boolean (Listof Bloque))` | `group_number`, `has_clash`, `schedules` |
| **Bloque** `(List Integer Integer Integer)` | `day`, `start_time`, `end_time` |
| **Preferencias** `(List Integer Integer (Listof (List String String (Listof Integer))))` | `min_credits`, `max_credits`, lista de `(code, career, groups)` |

Los campos ausentes toman valores por defecto (`""`, `0`, `#f`, `'()`) y, si la raíz del JSON no es la esperada, el lector devuelve una lista vacía (catálogo) o `(list 0 0 '())` (preferencias).

### 13.4 Mapa de funciones por módulo

| Módulo | Funciones públicas | Funciones privadas |
|---|---|---|
| `types.rkt` | Todos los tipos y structs de 13.1 | — |
| `filters.rkt` | `filtrar-lista-polimorfico`, `filtrar-stream-polimorfico`, `stream->list-polimorfico` | — |
| `json_reader.rkt` | `read-catalog-raw`, `read-preferences-raw` | — |
| `parser.rkt` | `load-catalog-from-json`, `load-preferences-from-json`, `prepare-candidate-courses` | `raw->schedule-block`, `raw->group`, `raw->course`, `raw->interested-course` |
| `generator.rkt` | `generar-combinaciones` | `bloques-chocan?`, `choca-con-lista?`, `grupo-valido-en-combinacion?` |
| `exporter.rkt` | `list->lazy-stream`, `filtrar-rango-creditos`, `exportar-combinaciones-json` | `formato-grupo-json`, `grupos->json`, `formato-combinacion-json`, `escribir-stream-json` |
| `test.rkt` | — (script de prueba integral) | — |

> [!NOTE]
> `stream->list-polimorfico` está disponible para convertir un `LazyStream` en lista, pero el flujo actual no la necesita: `exportar-combinaciones-json` escribe el stream directamente.

### 13.5 Instancias de la función polimórfica en el proyecto

| Función | Instancia (`A`) | Dónde se usa |
|---|---|---|
| `filtrar-lista-polimorfico` | `Course` | `prepare-candidate-courses`: filtra los cursos elegibles y el curso que coincide con el interés. |
| `filtrar-lista-polimorfico` | `Group` | `prepare-candidate-courses`: conserva solo los grupos pedidos. |
| `filtrar-lista-polimorfico` | `(Listof SelectedGroup)` | `prepare-candidate-courses`: elimina las sublistas vacías (sección 12.2). |
| `filtrar-stream-polimorfico` | `ScheduleCombination` | `filtrar-rango-creditos` (`exporter.rkt`): filtra por rango de créditos. |

---

<p align="center">
  <sub>CEmestre · CE1106 Paradigmas de Programación · Instituto Tecnológico de Costa Rica</sub>
</p>
