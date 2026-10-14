#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include "../include/struct_definitions.h"
#include "../include/validator.h"

// -------------------------------------------------------------
// FUNCIONES AUXILIARES PRIVADAS
// -------------------------------------------------------------

// Limpia espacios en blanco iniciales/finales y pasa las letras a MAYUSCULAS
static void sanitize_code(char *code) {
    if (!code) return;

    char *start = code;
    while (isspace((unsigned char)*start)) {
        start++;
    }

    if (*start == '\0') {
        code[0] = '\0';
        return;
    }

    char *end = start + strlen(start) - 1;
    while (end > start && isspace((unsigned char)*end)) {
        end--;
    }
    *(end + 1) = '\0';

    int i = 0;
    while (start <= end) {
        code[i] = (char)toupper((unsigned char)*start);
        i++;
        start++;
    }
    code[i] = '\0';
}

// Verifica que el codigo solo tenga letras y numeros (sin espacios, comas ni signos)
static bool is_valid_code_format(const char *code) {
    if (!code || strlen(code) == 0) return false;

    for (int i = 0; code[i] != '\0'; i++) {
        if (!isalnum((unsigned char)code[i])) {
            return false;
        }
    }
    return true;
}

// Busca si un codigo existe como curso registrado dentro del catalogo
static bool course_exists_in_catalog(const char *code, const Catalog *catalog) {
    for (int i = 0; i < catalog->course_count; i++) {
        if (strcmp(catalog->courses[i].code, code) == 0) {
            return true;
        }
    }
    return false;
}

// Verifica si una hora militar es sintacticamente valida (0000 a 2359)
static bool is_valid_military_time(int time) {
    if (time < 0 || time > 2359) return false;
    int minutes = time % 100;
    int hours = time / 100;
    return (hours <= 23 && minutes <= 59);
}

// Verifica traslapes entre dos bloques de horario
static bool blocks_clash(const ScheduleBlock *b1, const ScheduleBlock *b2) {
    if (b1->day != b2->day) return false;
    return (b1->start_time < b2->end_time && b2->start_time < b1->end_time);
}

// -------------------------------------------------------------
// VALIDACION DEL CATALOGO
// -------------------------------------------------------------

bool validate_catalog(Catalog *catalog) {
    if (!catalog || catalog->course_count == 0) {
        fprintf(stderr, "Error fatal: El catalogo esta vacio o no se pudo cargar.\n");
        return false;
    }

    bool all_good = true;

    // PASADA 1: Sanitizacion masiva de todos los codigos para estandarizar
    for (int i = 0; i < catalog->course_count; i++) {
        Course *c = &catalog->courses[i];
        sanitize_code(c->code);

        for (int j = 0; j < c->prereq_count; j++) {
            sanitize_code(c->prerequisites[j]);
        }
        for (int j = 0; j < c->coreq_count; j++) {
            sanitize_code(c->corequisites[j]);
        }
    }

    // PASADA 2: Validar cursos duplicados en la misma carrera
    for (int i = 0; i < catalog->course_count; i++) {
        for (int j = i + 1; j < catalog->course_count; j++) {
            // Un curso es duplicado solo si coinciden el codigo Y la carrera
            if (strcmp(catalog->courses[i].code, catalog->courses[j].code) == 0 &&
                strcmp(catalog->courses[i].career, catalog->courses[j].career) == 0) {

                fprintf(stderr, "Error: El curso '%s' de '%s' esta duplicado en el catalogo.\n",
                        catalog->courses[i].code, catalog->courses[i].career);
                all_good = false;
                }
        }
    }

    // PASADA 3: Validaciones logicas y de negocio por curso
    for (int i = 0; i < catalog->course_count; i++) {
        Course *c = &catalog->courses[i];

        // 1. Formato y presencia del codigo
        if (!is_valid_code_format(c->code)) {
            fprintf(stderr, "Error [Indice %d]: Codigo de curso '%s' vacio o con caracteres prohibidos.\n", i, c->code);
            all_good = false;
        }

        // 2. Creditos validos (0 a 10)
        if (c->credits < 0 || c->credits > 10) {
            fprintf(stderr, "Error [%s]: Cantidad de creditos invalida (%d).\n", c->code, c->credits);
            all_good = false;
        }

        // 3. Semestre valido (primeros 4 semestres del plan, semestres 0 al 4)
        if (c->semester < 0 || c->semester > 4) {
            fprintf(stderr, "Error [%s]: Semestre fuera del alcance del proyecto (%d).\n", c->code, c->semester);
            all_good = false;
        }

        // 4. Validacion de prerrequisitos
        for (int j = 0; j < c->prereq_count; j++) {
            const char *prereq = c->prerequisites[j];

            if (!is_valid_code_format(prereq)) {
                fprintf(stderr, "Error [%s]: Prerrequisito '%s' tiene formato invalido.\n", c->code, prereq);
                all_good = false;
            } else if (!course_exists_in_catalog(prereq, catalog)) {
                fprintf(stderr, "Error [%s]: Pide prerrequisito fantasma '%s' que no existe en el catalogo.\n", c->code, prereq);
                all_good = false;
            }

            // Auto-requisito
            if (strcmp(c->code, prereq) == 0) {
                fprintf(stderr, "Error [%s]: El curso se pide a si mismo como prerrequisito.\n", c->code);
                all_good = false;
            }

            // Duplicados en la misma lista de prerrequisitos
            for (int k = j + 1; k < c->prereq_count; k++) {
                if (strcmp(prereq, c->prerequisites[k]) == 0) {
                    fprintf(stderr, "Error [%s]: El prerrequisito '%s' esta repetido en la lista.\n", c->code, prereq);
                    all_good = false;
                }
            }
        }

        // 5. Validacion de correquisitos
        for (int j = 0; j < c->coreq_count; j++) {
            const char *coreq = c->corequisites[j];

            if (!is_valid_code_format(coreq)) {
                fprintf(stderr, "Error [%s]: Correquisito '%s' tiene formato invalido.\n", c->code, coreq);
                all_good = false;
            } else if (!course_exists_in_catalog(coreq, catalog)) {
                fprintf(stderr, "Error [%s]: Pide correquisito fantasma '%s' que no existe en el catalogo.\n", c->code, coreq);
                all_good = false;
            }

            // Auto-requisito
            if (strcmp(c->code, coreq) == 0) {
                fprintf(stderr, "Error [%s]: El curso se pide a si mismo como correquisito.\n", c->code);
                all_good = false;
            }

            // Duplicados en la misma lista de correquisitos
            for (int k = j + 1; k < c->coreq_count; k++) {
                if (strcmp(coreq, c->corequisites[k]) == 0) {
                    fprintf(stderr, "Error [%s]: El correquisito '%s' esta repetido en la lista.\n", c->code, coreq);
                    all_good = false;
                }
            }

            // Conflicto: No puede ser prerrequisito y correquisito a la vez
            for (int p = 0; p < c->prereq_count; p++) {
                if (strcmp(coreq, c->prerequisites[p]) == 0) {
                    fprintf(stderr, "Error [%s]: La materia '%s' esta definida como prerrequisito y correquisito a la vez.\n", c->code, coreq);
                    all_good = false;
                }
            }
        }

        // 6. Validacion de grupos y horarios
        if (c->group_count == 0) {
            fprintf(stderr, "Advertencia [%s]: El curso no tiene grupos asignados.\n", c->code);
        }

        for (int g = 0; g < c->group_count; g++) {
            Group *grp = &c->groups[g];

            for (int s = 0; s < grp->schedule_count; s++) {
                ScheduleBlock *blk = &grp->schedules[s];

                // Dia valido (1: Lunes a 6: Sabado)
                if (blk->day < DAY_MONDAY || blk->day > DAY_SATURDAY) {
                    fprintf(stderr, "Error [%s, Grupo %d]: Dia de la semana invalido (%d).\n", c->code, grp->group_number, blk->day);
                    all_good = false;
                }

                // Sintaxis de horas militares
                if (!is_valid_military_time(blk->start_time) || !is_valid_military_time(blk->end_time)) {
                    fprintf(stderr, "Error [%s, Grupo %d]: Hora militar ilogica (Inicio: %d, Fin: %d).\n", c->code, grp->group_number, blk->start_time, blk->end_time);
                    all_good = false;
                }

                // Secuencia cronologica
                if (blk->start_time >= blk->end_time) {
                    fprintf(stderr, "Error [%s, Grupo %d]: La hora de inicio (%d) debe ser menor a la hora de fin (%d).\n", c->code, grp->group_number, blk->start_time, blk->end_time);
                    all_good = false;
                }

                // Choque interno dentro del mismo grupo
                for (int s2 = s + 1; s2 < grp->schedule_count; s2++) {
                    if (blocks_clash(blk, &grp->schedules[s2])) {
                        fprintf(stderr, "Error [%s, Grupo %d]: Conflicto interno, dos bloques del mismo grupo chocan entre si el dia %d.\n", c->code, grp->group_number, blk->day);
                        all_good = false;
                    }
                }
            }
        }
    }

    return all_good;
}

// -------------------------------------------------------------
// VALIDACION DEL HISTORIAL DEL ESTUDIANTE
// -------------------------------------------------------------

bool validate_student_history(StudentHistory *history, const Catalog *catalog) {
    if (!history || !catalog) return false;

    bool all_good = true;

    // Sanitizar historial del estudiante
    for (int i = 0; i < history->approved_count; i++) {
        sanitize_code(history->approved_courses[i]);
    }

    // Validar materias del historial
    for (int i = 0; i < history->approved_count; i++) {
        const char *code = history->approved_courses[i];

        if (!is_valid_code_format(code)) {
            fprintf(stderr, "Error [Historial]: Codigo '%s' tiene formato invalido.\n", code);
            all_good = false;
        } else if (!course_exists_in_catalog(code, catalog)) {
            fprintf(stderr, "Error [Historial]: El curso aprobado '%s' no existe en el plan de estudios.\n", code);
            all_good = false;
        }

        // Detectar materias aprobadas duplicadas
        for (int j = i + 1; j < history->approved_count; j++) {
            if (strcmp(code, history->approved_courses[j]) == 0) {
                fprintf(stderr, "Error [Historial]: El curso '%s' aparece reportado como aprobado mas de una vez.\n", code);
                all_good = false;
            }
        }
    }

    return all_good;
}