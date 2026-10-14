<!DOCTYPE html>
<html>

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CEmestre</title>
  <link rel="stylesheet" href="https://stackedit.io/style.css" />
</head>

<body class="stackedit">
  <div class="stackedit__html"><h1 id="cemestre-constructor-inteligente-de-horarios">CEmestre: Constructor Inteligente de Horarios</h1>
<p align="center">
</p><img src="https://img.shields.io/badge/Curso-CE1106%20Paradigmas%20de%20Programaci%C3%B3n-0052cc?style=for-the-badge" alt="Curso">
<img src="https://img.shields.io/badge/Instituci%C3%B3n-Instituto%20Tecnol%C3%B3gico%20de%20Costa%20Rica-00758f?style=for-the-badge" alt="TEC">
<img src="https://img.shields.io/badge/Etapa-1%20(Imperativo)%20y%202%20(Funcional)-orange?style=for-the-badge" alt="Etapa">
<img src="https://img.shields.io/badge/Lenguajes-C99%20%7C%20Typed%20Racket-blueviolet?style=for-the-badge" alt="Lenguajes">
<img src="https://img.shields.io/badge/Estado-Etapa%201%20Completa%20%2F%20Fase%202%20En%20Curso-success?style=for-the-badge" alt="Estado">

<hr>
<h2 id="tabla-de-contenidos">Tabla de Contenidos</h2>
<ol>
<li>
<p><a href="#visi%C3%B3n-general-del-proyecto">Visión General del Proyecto</a></p>
</li>
<li>
<p><a href="#arquitectura-y-flujo-del-pipeline">Arquitectura y Flujo del Pipeline</a></p>
</li>
<li>
<p><a href="#estructura-de-directorios">Estructura de Directorios</a></p>
</li>
<li>
<p><a href="#constantes-y-modelado-de-datos-en-c">Constantes y Modelado de Datos en C</a></p>
</li>
<li>
<p><a href="#descripci%C3%B3n-modular-de-la-etapa-1-etapa1_c">Descripción Modular de la Etapa 1 (<code>etapa1_c</code>)</a></p>
</li>
<li>
<p><a href="#actualizaciones-y-transici%C3%B3n-hacia-la-etapa-2">Actualizaciones y Transición hacia la Etapa 2</a></p>
</li>
<li>
<p><a href="#compilaci%C3%B3n-y-ejecuci%C3%B3n">Compilación y Ejecución</a></p>
</li>
<li>
<p><a href="#bater%C3%ADa-de-comandos-de-inspecci%C3%B3n-y-pruebas">Batería de Comandos de Inspección y Pruebas</a></p>
</li>
<li>
<p><a href="#manejo-defensivo-y-casos-l%C3%ADmite">Manejo Defensivo y Casos Límite</a></p>
</li>
</ol>
<hr>
<h2 id="visión-general-del-proyecto">Visión General del Proyecto</h2>
<p><strong>CEmestre</strong> es un sistema modular de planificación académica diseñado para el <strong>Instituto Tecnológico de Costa Rica (TEC)</strong>. El objetivo principal consiste en procesar la malla curricular de las carreras de <strong>Ingeniería en Computadores</strong> e <strong>Ingeniería en Biotecnología</strong>, verificar el historial del estudiante, determinar la elegibilidad de asignaturas mediante grafos de requisitos/correquisitos, resolver colisiones horarias y generar combinaciones óptimas de matrícula libres de choques de horario.</p>
<p>El proyecto articula múltiples paradigmas computacionales:</p>
<ul>
<li>
<p><strong>Etapa 1 (Paradigma Imperativo - C99):</strong> Ingesta, saneamiento, validación semántica, verificación de requisitos y detección exhaustiva de traslapes en bloques de tiempo.</p>
</li>
<li>
<p><strong>Etapa 2 (Paradigma Funcional - Typed Racket):</strong> Procesamiento perezoso mediante streams, validación tipada estática, polimorfismo paramétrico y backtracking libre de efectos secundarios.</p>
</li>
</ul>
<hr>
<h2 id="arquitectura-y-flujo-del-pipeline">Arquitectura y Flujo del Pipeline</h2>
<p>El núcleo en C opera como un motor de extracción, transformación y validación de datos (ETL) que produce el contrato JSON consumido por Racket:</p>
<pre class=" language-text"><code class="prism  language-text">
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

</code></pre>
<h3 id="fases-de-ejecución">Fases de Ejecución</h3>
<ol>
<li>
<p><strong>Ingesta y Deserialización (<code>parser.c</code>):</strong> Extrae datos jerárquicos desde los JSON de entrada y puebla las estructuras estáticas en memoria.</p>
</li>
<li>
<p><strong>Saneamiento y Certificación (<code>validator.c</code>):</strong> Normaliza cadenas, verifica integridad referencial, prohíbe cursos fantasma o auto-requisitos y asegura cronología horaria válida.</p>
</li>
<li>
<p><strong>Resolución Académica (<code>prereq_checker.c</code>):</strong> Calcula si una materia no aprobada cuenta con todos sus prerrequisitos y correquisitos viables.</p>
</li>
<li>
<p><strong>Análisis Temporal de Colisiones (<code>schedule_checker.c</code>):</strong> Detecta traslapes horarios entre asignaturas elegibles de la misma carrera.</p>
</li>
<li>
<p><strong>Serialización Estandarizada (<code>exporter.c</code>):</strong> Emite el catálogo estructurado con los estados booleanos calculados (<code>is_approved</code>, <code>is_eligible</code>, <code>has_clash</code>, <code>has_any_schedule_clash</code>).</p>
</li>
</ol>
<hr>
<h2 id="estructura-de-directorios">Estructura de Directorios</h2>
<pre class=" language-text"><code class="prism  language-text">
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

</code></pre>
<hr>
<h2 id="constantes-y-modelado-de-datos-en-c">Constantes y Modelado de Datos en C</h2>
<p>Las dimensiones del sistema se definen en <code>include/config.h</code>:</p>
<p>| Constante | Valor | Finalidad Técnica |</p>
<p>|—|---|—|</p>
<p>| <code>MAX_COURSES</code> | <code>200</code> | Capacidad máxima de asignaturas simultáneas en el catálogo. |</p>
<p>| <code>MAX_GROUPS</code> | <code>10</code> | Límite de grupos académicos ofertables por curso. |</p>
<p>| <code>MAX_SCHEDULES_PER_GROUP</code> | <code>5</code> | Máximo de bloques horarios por grupo. |</p>
<p>| <code>MAX_PREREQUISITES</code> | <code>10</code> | Límite superior de prerrequisitos por materia. |</p>
<p>| <code>MAX_COREQUISITES</code> | <code>5</code> | Límite superior de correquisitos por materia. |</p>
<p>| <code>MAX_APPROVED_COURSES</code> | <code>100</code> | Máximo de asignaturas acreditadas en el expediente. |</p>
<p>| <code>MAX_SEMESTER</code> | <code>6</code> | Alcance curricular cubierto por el sistema. |</p>
<p>| <code>MAX_STRING_LEN</code> | <code>100</code> | Tamaño de búfer para nombres y carreras. |</p>
<p>| <code>MAX_CODE_LEN</code> | <code>15</code> | Tamaño de búfer para códigos alfanuméricos. |</p>
<p>| <code>DAY_MONDAY</code> - <code>DAY_SATURDAY</code> | <code>1</code> - <code>6</code> | Representación numérica de los días lectivos. |</p>
<h3 id="estructuras-centrales-includestruct_definitions.h">Estructuras Centrales (<code>include/struct_definitions.h</code>)</h3>
<ul>
<li>
<p><strong><code>ScheduleBlock</code>:</strong> Encapsula el día lectivo (<code>day</code>), hora de inicio (<code>start_time</code>) y fin (<code>end_time</code>) en formato militar (ej. <code>730</code> para 07:30, <code>1650</code> para 16:50).</p>
</li>
<li>
<p><strong><code>Group</code>:</strong> Contiene el identificador (<code>group_number</code>), arreglo de bloques (<code>schedules</code>), contador (<code>schedule_count</code>) y bandera individual de colisión (<code>has_clash</code>).</p>
</li>
<li>
<p><strong><code>Course</code>:</strong> Almacena metadatos (<code>code</code>, <code>name</code>, <code>credits</code>, <code>semester</code>, <code>career</code>), dependencias (<code>prerequisites</code>, <code>corequisites</code>), grupos asociados (<code>groups</code>) y banderas de decisión (<code>is_approved</code>, <code>is_eligible</code>, <code>has_any_schedule_clash</code>).</p>
</li>
<li>
<p><strong><code>Catalog</code>:</strong> Registro global contenedor con arreglo estático de asignaturas y total efectivo (<code>course_count</code>).</p>
</li>
<li>
<p><strong><code>StudentHistory</code>:</strong> Almacén del expediente del estudiante (<code>approved_courses</code>, <code>approved_count</code>).</p>
</li>
</ul>
<hr>
<h2 id="descripción-modular-de-la-etapa-1-etapa1_c">Descripción Modular de la Etapa 1 (<code>etapa1_c</code>)</h2>
<h3 id="verificador-de-requisitos-srcprereq_checker.c">1. Verificador de Requisitos (<code>src/prereq_checker.c</code>)</h3>
<ul>
<li>
<p><strong><code>is_course_approved</code>:</strong> Comprobación rápida para saber si un código figura en el expediente.</p>
</li>
<li>
<p><strong><code>can_take_course</code>:</strong> Evalúa si la materia ya fue aprobada (la descarta), certifica que todos los prerrequisitos figuren como aprobados y analiza que los correquisitos sean simultáneamente cursables comprobando a su vez los requisitos del correquisito.</p>
</li>
</ul>
<h3 id="validador-semántico-srcvalidator.c">2. Validador Semántico (<code>src/validator.c</code>)</h3>
<ul>
<li>
<p><strong><code>sanitize_code</code>:</strong> Limpia espacios residuales y uniforma códigos a mayúsculas.</p>
</li>
<li>
<p><strong><code>validate_catalog</code>:</strong> Impone saneamiento universal, descarta duplicados dentro de la misma carrera, verifica límites de créditos (0 a 10), acota el rango de semestres a <code>MAX_SEMESTER</code> (0 a 6), detecta auto-dependencias, prerrequisitos/correquisitos fantasma y traslapes horarios internos dentro de un mismo grupo académico.</p>
</li>
<li>
<p><strong><code>validate_student_history</code>:</strong> Confirma que cada asignatura acreditada exista en el catálogo y evita registros repetidos.</p>
</li>
</ul>
<h3 id="motor-de-horarios-y-choques-srcschedule_checker.c">3. Motor de Horarios y Choques (<code>src/schedule_checker.c</code>)</h3>
<ul>
<li><strong><code>blocks_overlap</code>:</strong> Evalúa si dos bloques coinciden en día y se intersectan temporalmente mediante la regla:</li>
</ul>
<p><span class="katex--display"><span class="katex-display"><span class="katex"><span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><msub><mtext>start</mtext><mn>1</mn></msub><mo>&lt;</mo><msub><mtext>end</mtext><mn>2</mn></msub>  <mo>∧</mo>  <msub><mtext>start</mtext><mn>2</mn></msub><mo>&lt;</mo><msub><mtext>end</mtext><mn>1</mn></msub></mrow><annotation encoding="application/x-tex">\text{start}_1 &lt; \text{end}_2 \;\land\; \text{start}_2 &lt; \text{end}_1</annotation></semantics></math></span><span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height: 0.76508em; vertical-align: -0.15em;"></span><span class="mord"><span class="mord text"><span class="mord">start</span></span><span class="msupsub"><span class="vlist-t vlist-t2"><span class="vlist-r"><span class="vlist" style="height: 0.301108em;"><span class="" style="top: -2.55em; margin-right: 0.05em;"><span class="pstrut" style="height: 2.7em;"></span><span class="sizing reset-size6 size3 mtight"><span class="mord mtight">1</span></span></span></span><span class="vlist-s">​</span></span><span class="vlist-r"><span class="vlist" style="height: 0.15em;"><span class=""></span></span></span></span></span></span><span class="mspace" style="margin-right: 0.277778em;"></span><span class="mrel">&lt;</span><span class="mspace" style="margin-right: 0.277778em;"></span></span><span class="base"><span class="strut" style="height: 0.84444em; vertical-align: -0.15em;"></span><span class="mord"><span class="mord text"><span class="mord">end</span></span><span class="msupsub"><span class="vlist-t vlist-t2"><span class="vlist-r"><span class="vlist" style="height: 0.301108em;"><span class="" style="top: -2.55em; margin-right: 0.05em;"><span class="pstrut" style="height: 2.7em;"></span><span class="sizing reset-size6 size3 mtight"><span class="mord mtight">2</span></span></span></span><span class="vlist-s">​</span></span><span class="vlist-r"><span class="vlist" style="height: 0.15em;"><span class=""></span></span></span></span></span></span><span class="mspace" style="margin-right: 0.277778em;"></span><span class="mspace" style="margin-right: 0.222222em;"></span><span class="mbin">∧</span><span class="mspace" style="margin-right: 0.277778em;"></span><span class="mspace" style="margin-right: 0.222222em;"></span></span><span class="base"><span class="strut" style="height: 0.76508em; vertical-align: -0.15em;"></span><span class="mord"><span class="mord text"><span class="mord">start</span></span><span class="msupsub"><span class="vlist-t vlist-t2"><span class="vlist-r"><span class="vlist" style="height: 0.301108em;"><span class="" style="top: -2.55em; margin-right: 0.05em;"><span class="pstrut" style="height: 2.7em;"></span><span class="sizing reset-size6 size3 mtight"><span class="mord mtight">2</span></span></span></span><span class="vlist-s">​</span></span><span class="vlist-r"><span class="vlist" style="height: 0.15em;"><span class=""></span></span></span></span></span></span><span class="mspace" style="margin-right: 0.277778em;"></span><span class="mrel">&lt;</span><span class="mspace" style="margin-right: 0.277778em;"></span></span><span class="base"><span class="strut" style="height: 0.84444em; vertical-align: -0.15em;"></span><span class="mord"><span class="mord text"><span class="mord">end</span></span><span class="msupsub"><span class="vlist-t vlist-t2"><span class="vlist-r"><span class="vlist" style="height: 0.301108em;"><span class="" style="top: -2.55em; margin-right: 0.05em;"><span class="pstrut" style="height: 2.7em;"></span><span class="sizing reset-size6 size3 mtight"><span class="mord mtight">1</span></span></span></span><span class="vlist-s">​</span></span><span class="vlist-r"><span class="vlist" style="height: 0.15em;"><span class=""></span></span></span></span></span></span></span></span></span></span></span></p>
<ul>
<li>
<p><strong><code>groups_overlap</code>:</strong> Compara exhaustivamente todos los bloques del Grupo A contra el Grupo B.</p>
</li>
<li>
<p><strong><code>check_schedule_clashes</code>:</strong> Realiza comparaciones cruzadas únicamente entre materias simultáneamente elegibles (<code>is_eligible == true</code>) de la misma carrera. Marca <code>has_clash</code> por grupo y levanta <code>has_any_schedule_clash = true</code> en el curso si todos sus grupos colisionan sin alternativa disponible.</p>
</li>
</ul>
<h3 id="deserializador-seguro-srcparser.c">4. Deserializador Seguro (<code>src/parser.c</code>)</h3>
<ul>
<li>Implementa lectura binaria protegida (<code>read_file_to_string</code>), extracción delimitada de campos (<code>get_json_string_val</code>, <code>get_json_int_val</code>), captura de arreglos y parseo de profundidad de llaves balanceadas (<code>parse_groups_and_schedules</code>) sin dependencias externas, aplicando candados de fin de cadena (<code>\0</code>) explícitos.</li>
</ul>
<h3 id="serializador-json-srcexporter.c">5. Serializador JSON (<code>src/exporter.c</code>)</h3>
<ul>
<li>Genera el archivo normalizado <code>output_schedule.json</code> con control de comas terminales y exportación estricta de booleanos nativos.</li>
</ul>
<hr>
<h2 id="actualizaciones-y-transición-hacia-la-etapa-2">Actualizaciones y Transición hacia la Etapa 2</h2>
<p>Para satisfacer los requerimientos de la Fase Funcional, se realizaron las siguientes extensiones en la arquitectura:</p>
<h3 id="extensión-del-plan-de-estudios-a-6-semestres">1. Extensión del Plan de Estudios a 6 Semestres</h3>
<p>Se amplió el archivo <code>data/plan_estudios.json</code> integrando el catálogo oficial hasta el semestre 6 para <strong>Ingeniería en Computadores</strong> y para <strong>Ingeniería en Biotecnología</strong>, elevando el catálogo procesado a <strong>91 asignaturas</strong>.</p>
<blockquote>
<p>[!NOTE]</p>
</blockquote>
<blockquote>
<p>En <code>etapa1_c/include/config.h</code> se definió <code>MAX_SEMESTER 6</code> y se actualizó <code>etapa1_c/src/validator.c</code> para certificar la presencia del campo <code>career</code> y validar semestres en el intervalo <span class="katex--inline"><span class="katex"><span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mo stretchy="false">[</mo><mn>0</mn><mo separator="true">,</mo><mn>6</mn><mo stretchy="false">]</mo></mrow><annotation encoding="application/x-tex">[0, 6]</annotation></semantics></math></span><span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height: 1em; vertical-align: -0.25em;"></span><span class="mopen">[</span><span class="mord">0</span><span class="mpunct">,</span><span class="mspace" style="margin-right: 0.166667em;"></span><span class="mord">6</span><span class="mclose">]</span></span></span></span></span>.</p>
</blockquote>
<h3 id="archivo-de-preferencias-del-estudiante-datapreferencias.json">2. Archivo de Preferencias del Estudiante (<code>data/preferencias.json</code>)</h3>
<p>A diferencia de <code>historial_estudiante.json</code> (que refleja el pasado académico), <code>preferencias.json</code> modela la intención de matrícula inmediata del estudiante:</p>
<pre class=" language-json"><code class="prism  language-json">
<span class="token punctuation">{</span>

<span class="token string">"min_credits"</span><span class="token punctuation">:</span> <span class="token number">8</span><span class="token punctuation">,</span>

<span class="token string">"max_credits"</span><span class="token punctuation">:</span> <span class="token number">16</span><span class="token punctuation">,</span>

<span class="token string">"interested_courses"</span><span class="token punctuation">:</span> <span class="token punctuation">[</span>

<span class="token punctuation">{</span>

<span class="token string">"code"</span><span class="token punctuation">:</span> <span class="token string">"CE1107"</span><span class="token punctuation">,</span>

<span class="token string">"career"</span><span class="token punctuation">:</span> <span class="token string">"Ingeniería en Computadores"</span><span class="token punctuation">,</span>

<span class="token string">"groups"</span><span class="token punctuation">:</span> <span class="token punctuation">[</span><span class="token number">1</span><span class="token punctuation">,</span> <span class="token number">2</span><span class="token punctuation">]</span>

<span class="token punctuation">}</span><span class="token punctuation">,</span>

<span class="token punctuation">{</span>

<span class="token string">"code"</span><span class="token punctuation">:</span> <span class="token string">"MA1102"</span><span class="token punctuation">,</span>

<span class="token string">"career"</span><span class="token punctuation">:</span> <span class="token string">"Ingeniería en Computadores"</span><span class="token punctuation">,</span>

<span class="token string">"groups"</span><span class="token punctuation">:</span> <span class="token punctuation">[</span><span class="token number">1</span><span class="token punctuation">]</span>

<span class="token punctuation">}</span>

<span class="token punctuation">]</span>

<span class="token punctuation">}</span>

</code></pre>
<ul>
<li>
<p>Permite configurar un rango de créditos deseados (<code>min_credits</code>, <code>max_credits</code>) para el filtrado en Racket.</p>
</li>
<li>
<p>Incorpora el atributo <code>"career"</code> por curso de interés, evitando ambigüedades en materias compartidas entre carreras.</p>
</li>
<li>
<p>Permite seleccionar múltiples grupos alternativos para un mismo curso de interés.</p>
</li>
</ul>
<hr>
<h2 id="compilación-y-ejecución">Compilación y Ejecución</h2>
<h3 id="compilación-mediante-makefile">1. Compilación mediante Makefile</h3>
<p>Desde el directorio <code>etapa1_c/</code>:</p>
<pre class=" language-bash"><code class="prism  language-bash">
<span class="token function">make</span>

</code></pre>
<blockquote>
<p>[!TIP]</p>
</blockquote>
<blockquote>
<p>En entornos Windows sin <code>rm</code> nativo en el Path, para limpiar archivos compilados se puede ejecutar en PowerShell:</p>
</blockquote>
<blockquote></blockquote>
<blockquote>
<pre class=" language-powershell"><code class="prism  language-powershell"></code></pre>
</blockquote>
<blockquote>
<p>Remove-Item  -Force -ErrorAction SilentlyContinue cemestre_c.exe,  *.o</p>
</blockquote>
<blockquote>
<pre><code></code></pre>
</blockquote>
<h3 id="compilación-manual-alternativa-con-gcc">2. Compilación manual alternativa con GCC</h3>
<pre class=" language-bash"><code class="prism  language-bash">
gcc  -Wall  -Wextra  -std<span class="token operator">=</span>c99  -Iinclude  src/*.c  -o  cemestre_c

</code></pre>
<h3 id="ejecución-del-sistema">3. Ejecución del Sistema</h3>
<p>El ejecutable debe lanzarse desde dentro de la carpeta <code>etapa1_c</code> para resolver las rutas relativas <code>../data/</code>:</p>
<ul>
<li><strong>En Windows (PowerShell / CMD):</strong></li>
</ul>
<pre class=" language-powershell"><code class="prism  language-powershell">
<span class="token punctuation">.</span>\cemestre_c<span class="token punctuation">.</span>exe

</code></pre>
<ul>
<li><strong>En Linux / macOS:</strong></li>
</ul>
<pre class=" language-bash"><code class="prism  language-bash">
./cemestre_c

</code></pre>
<p><strong>Salida esperada:</strong></p>
<pre class=" language-text"><code class="prism  language-text">
Proceso completado con éxito. Resultados guardados en ../data/output_schedule.json

</code></pre>
<hr>
<h2 id="batería-de-comandos-de-inspección-y-pruebas">Batería de Comandos de Inspección y Pruebas</h2>
<p>Para auditar y validar el resultado de <code>data/output_schedule.json</code> de forma automatizada:</p>
<h3 id="en-windows-powershell">En Windows (PowerShell)</h3>
<ol>
<li><strong>Listar cursos de semestres avanzados (Semestres 5 y 6):</strong></li>
</ol>
<pre class=" language-powershell"><code class="prism  language-powershell">
<span class="token punctuation">(</span><span class="token function">Get-Content</span>  <span class="token operator">-</span>Raw <span class="token operator">-</span>Path <span class="token string">"..\data\output_schedule.json"</span>  <span class="token punctuation">|</span>  <span class="token function">ConvertFrom-Json</span><span class="token punctuation">)</span> <span class="token punctuation">|</span>  <span class="token function">Where-Object</span> <span class="token punctuation">{</span> <span class="token variable">$_</span><span class="token punctuation">.</span>semester  <span class="token operator">-ge</span>  5 <span class="token punctuation">}</span> <span class="token punctuation">|</span>  <span class="token function">Select-Object</span> code<span class="token punctuation">,</span> semester<span class="token punctuation">,</span> career<span class="token punctuation">,</span> is_eligible

</code></pre>
<ol start="2">
<li><strong>Verificar elegibilidad de una materia específica de semestre 5 (<code>CE1107</code>):</strong></li>
</ol>
<pre class=" language-powershell"><code class="prism  language-powershell">
<span class="token punctuation">(</span><span class="token function">Get-Content</span>  <span class="token operator">-</span>Raw <span class="token operator">-</span>Path <span class="token string">"..\data\output_schedule.json"</span>  <span class="token punctuation">|</span>  <span class="token function">ConvertFrom-Json</span><span class="token punctuation">)</span> <span class="token punctuation">|</span>  <span class="token function">Where-Object</span> <span class="token punctuation">{</span> <span class="token variable">$_</span><span class="token punctuation">.</span>code  <span class="token operator">-eq</span>  <span class="token string">"CE1107"</span> <span class="token punctuation">}</span> <span class="token punctuation">|</span>  <span class="token function">Select-Object</span> code<span class="token punctuation">,</span> name<span class="token punctuation">,</span> semester<span class="token punctuation">,</span> career<span class="token punctuation">,</span> is_eligible<span class="token punctuation">,</span> is_approved

</code></pre>
<ol start="3">
<li><strong>Auditar distribución de cursos por número de semestre:</strong></li>
</ol>
<pre class=" language-powershell"><code class="prism  language-powershell">
<span class="token punctuation">(</span><span class="token function">Get-Content</span>  <span class="token operator">-</span>Raw <span class="token operator">-</span>Path <span class="token string">"..\data\output_schedule.json"</span>  <span class="token punctuation">|</span>  <span class="token function">ConvertFrom-Json</span><span class="token punctuation">)</span> <span class="token punctuation">|</span>  <span class="token function">Group-Object</span> semester <span class="token punctuation">|</span>  <span class="token function">Select-Object</span> Name<span class="token punctuation">,</span> Count <span class="token punctuation">|</span>  <span class="token function">Sort-Object</span> Name

</code></pre>
<ol start="4">
<li><strong>Contar la cantidad total de cursos procesados en el catálogo:</strong></li>
</ol>
<pre class=" language-powershell"><code class="prism  language-powershell">
<span class="token punctuation">(</span><span class="token function">Get-Content</span>  <span class="token operator">-</span>Raw <span class="token operator">-</span>Path <span class="token string">"..\data\output_schedule.json"</span>  <span class="token punctuation">|</span>  <span class="token function">ConvertFrom-Json</span><span class="token punctuation">)</span><span class="token punctuation">.</span>Count

</code></pre>
<h3 id="en-linux--macos-bash--jq">En Linux / macOS (Bash + <code>jq</code>)</h3>
<ol>
<li><strong>Listar cursos de semestres 5 y 6:</strong></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash">
jq <span class="token string">'.[] | select(.semester &gt;= 5) | {code, semester, career, is_eligible}'</span> <span class="token punctuation">..</span>/data/output_schedule.json

</code></pre>
<ol start="2">
<li><strong>Inspeccionar estado detallado de <code>CE1107</code>:</strong></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash">
jq <span class="token string">'.[] | select(.code == "CE1107") | {code, name, semester, is_eligible, is_approved}'</span> <span class="token punctuation">..</span>/data/output_schedule.json

</code></pre>
<ol start="3">
<li><strong>Conteo total de asignaturas registradas:</strong></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash">
jq <span class="token string">'length'</span> <span class="token punctuation">..</span>/data/output_schedule.json

</code></pre>
<hr>
<h2 id="manejo-defensivo-y-casos-límite">Manejo Defensivo y Casos Límite</h2>
<ul>
<li>
<p><strong>Aislamiento por Carrera en Detección de Choques:</strong> En <code>schedule_checker.c</code>, dos grupos con horarios idénticos no se marcan en colisión si pertenecen a carreras distintas, garantizando coherencia para estudiantes que cursan planes independientes.</p>
</li>
<li>
<p><strong>Independencia del Semestre al Evaluar Choques:</strong> El sistema no asume que un estudiante solo cursa materias de un único bloque lectivo. Estudiantes con asignaturas de rezago y adelanto son evaluados de forma global.</p>
</li>
<li>
<p><strong>Prevención de Ciclos de Correquisitos:</strong> La comprobación de correquisitos en <code>prereq_checker.c</code> valida la matriculabilidad de la materia par sin permitir recursión infinita.</p>
</li>
<li>
<p><strong>Tolerancia Cero ante Datos Corruptos:</strong> El módulo <code>validator.c</code> detiene la ejecución inmediatamente si detecta auto-dependencias, referencias a cursos inexistentes o inconsistencias en los intervalos de tiempo militar, evitando la propagación de datos corruptos hacia la fase en Racket.</p>
</li>
</ul>
</div>
</body>

</html>
