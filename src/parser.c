#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "../include/struct_definitions.h"
#include "../include/parser.h"

// 1. Lee el archivo completo y lo guarda en la memoria dinámica
static char* read_file_to_string(const char *filepath) {
    FILE *file = fopen(filepath, "rb");
    if (!file) return NULL;

    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);

    // Blindaje: Si el archivo está vacío, no reservamos memoria
    if (length <= 0) {
        fclose(file);
        return NULL;
    }

    char *buffer = (char *)malloc(length + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }

    size_t bytes_read = fread(buffer, 1, length, file);
    buffer[bytes_read] = '\0'; // Candado final de seguridad
    fclose(file);
    return buffer;
}

// 2. Extrae un texto (string) de forma segura
static void get_json_string_val(const char *json, const char *key, char *out, size_t max_len) {
    out[0] = '\0'; // Limpiamos la salida por defecto

    char pattern[64];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key);

    char *pos = strstr(json, pattern);
    if (!pos) return; // Blindaje: Si no encuentra la llave, aborta seguro

    pos = strchr(pos + strlen(pattern), ':');
    if (!pos) return;

    pos = strchr(pos, '"');
    if (!pos) return;
    pos++; // Saltamos la primera comilla

    char *end = strchr(pos, '"');
    if (!end) return;

    // Blindaje: Evitamos desbordamiento de búfer limitando la longitud
    size_t len = end - pos;
    if (len >= max_len) len = max_len - 1;

    strncpy(out, pos, len);
    out[len] = '\0'; // Candado manual obligatorio
}

// 3. Extrae un número entero de forma segura
static int get_json_int_val(const char *json, const char *key) {
    char pattern[64];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key);

    char *pos = strstr(json, pattern);
    if (!pos) return 0;

    pos = strchr(pos + strlen(pattern), ':');
    if (!pos) return 0;
    pos++;

    while (*pos && !isdigit((unsigned char)*pos) && *pos != '-') pos++;

    // Si llegamos a algo que no es número, devolvemos 0
    if (!isdigit((unsigned char)*pos) && *pos != '-') return 0;

    return atoi(pos);
}

// 4. Extrae arreglos de textos (prerrequisitos y correquisitos)
static void get_json_array_strings(const char *json, const char *key, char out_arr[][MAX_CODE_LEN], int *out_count, int max_items) {
    *out_count = 0;
    char pattern[64];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key);

    char *pos = strstr(json, pattern);
    if (!pos) return;

    pos = strchr(pos + strlen(pattern), '[');
    if (!pos) return;

    char *end_bracket = strchr(pos, ']');
    if (!end_bracket) return;

    char *ptr = pos + 1;
    // Blindaje: *out_count < max_items evita pasarnos de MAX_PREREQUISITES o MAX_COREQUISITES
    while (ptr < end_bracket && *out_count < max_items) {
        ptr = strchr(ptr, '"');
        if (!ptr || ptr >= end_bracket) break;
        ptr++;

        char *end_quote = strchr(ptr, '"');
        if (!end_quote || end_quote >= end_bracket) break;

        size_t len = end_quote - ptr;
        if (len > 0 && len < MAX_CODE_LEN) {
            strncpy(out_arr[*out_count], ptr, len);
            out_arr[*out_count][len] = '\0';
            (*out_count)++;
        }
        ptr = end_quote + 1;
    }
}

// 5. Parsea la estructura anidada y riesgosa de grupos y horarios
static void parse_groups_and_schedules(const char *json_course, Course *course) {
    course->group_count = 0;

    char *groups_pos = strstr(json_course, "\"groups\"");
    if (!groups_pos) return;

    char *g_ptr = strchr(groups_pos, '[');
    if (!g_ptr) return;

    char *curr_g = strstr(g_ptr, "{");
    // Blindaje: Respetar MAX_GROUPS
    while (curr_g != NULL && course->group_count < MAX_GROUPS) {
        // Encontrar dónde termina este grupo específico (contando llaves para ser robustos)
        int depth = 0;
        char *end_g = NULL;
        for (char *p = curr_g; *p != '\0'; p++) {
            if (*p == '{') depth++;
            else if (*p == '}') {
                depth--;
                if (depth == 0) {
                    end_g = p;
                    break;
                }
            }
        }
        if (!end_g) break;

        // Aislar temporalmente el texto de este grupo
        char backup_g = *end_g;
        *end_g = '\0';

        Group *g = &course->groups[course->group_count];
        g->group_number = get_json_int_val(curr_g, "group_number");
        g->schedule_count = 0;

        char *sched_pos = strstr(curr_g, "\"schedules\"");
        if (sched_pos) {
            char *s_ptr = strchr(sched_pos, '[');
            if (s_ptr) {
                char *curr_s = strstr(s_ptr, "{");
                // Blindaje: Respetar MAX_SCHEDULES_PER_GROUP
                while (curr_s != NULL && g->schedule_count < MAX_SCHEDULES_PER_GROUP) {
                    ScheduleBlock *s = &g->schedules[g->schedule_count];
                    s->day = get_json_int_val(curr_s, "day");
                    s->start_time = get_json_int_val(curr_s, "start_time");
                    s->end_time = get_json_int_val(curr_s, "end_time");
                    g->schedule_count++;

                    curr_s = strchr(curr_s + 1, '{'); // Siguiente horario
                }
            }
        }

        course->group_count++;
        *end_g = backup_g; // Restaurar el JSON original
        curr_g = strchr(end_g + 1, '{'); // Buscar el siguiente grupo
    }
}

// 6. Función principal para cargar el catálogo
bool load_catalog(const char *filename, Catalog *catalog) {
    if (!catalog) return false;
    catalog->course_count = 0;

    char *json_data = read_file_to_string(filename);
    if (!json_data) return false;

    char *cursor = json_data;
    // Blindaje: Detener la lectura si llegamos a MAX_COURSES
    while (catalog->course_count < MAX_COURSES) {
        char *brace_start = strchr(cursor, '{');
        if (!brace_start) break;

        int depth = 0;
        char *obj_end = NULL;
        for (char *p = brace_start; *p != '\0'; p++) {
            if (*p == '{') depth++;
            else if (*p == '}') {
                depth--;
                if (depth == 0) {
                    obj_end = p;
                    break;
                }
            }
        }

        if (!obj_end) break;

        char backup = *obj_end;
        *obj_end = '\0';

        Course *c = &catalog->courses[catalog->course_count];
        memset(c, 0, sizeof(Course));

        get_json_string_val(brace_start, "code", c->code, sizeof(c->code));
        get_json_string_val(brace_start, "name", c->name, sizeof(c->name));
        get_json_string_val(brace_start, "career", c->career, sizeof(c->career));
        c->credits = get_json_int_val(brace_start, "credits");
        c->semester = get_json_int_val(brace_start, "semester");

        get_json_array_strings(brace_start, "prerequisites", c->prerequisites, &c->prereq_count, MAX_PREREQUISITES);
        get_json_array_strings(brace_start, "corequisites", c->corequisites, &c->coreq_count, MAX_COREQUISITES);

        parse_groups_and_schedules(brace_start, c);

        catalog->course_count++;
        *obj_end = backup;
        cursor = obj_end + 1;
    }

    free(json_data);
    return true;
}

// 7. Carga el historial del estudiante
bool load_student_history(const char *filename, StudentHistory *history) {
    if (!history) return false;
    char *json_data = read_file_to_string(filename);
    if (!json_data) return false;

    history->approved_count = 0;

    char *array_start = strchr(json_data, '[');
    if (!array_start) {
        free(json_data);
        return false;
    }

    char *ptr = array_start;
    // Blindaje: Detenernos al alcanzar MAX_APPROVED_COURSES
    while ((ptr = strchr(ptr, '"')) != NULL && history->approved_count < MAX_APPROVED_COURSES) {
        ptr++;
        char *end = strchr(ptr, '"');
        if (!end) break;

        size_t len = end - ptr;
        if (len > 0 && len < MAX_CODE_LEN) {
            strncpy(history->approved_courses[history->approved_count], ptr, len);
            history->approved_courses[history->approved_count][len] = '\0';
            history->approved_count++;
        }
        ptr = end + 1;
    }

    free(json_data);
    return true;
}

// 8. Limpieza de memoria
void free_catalog(Catalog *catalog) {
    if (catalog) {
        catalog->course_count = 0;
    }
}