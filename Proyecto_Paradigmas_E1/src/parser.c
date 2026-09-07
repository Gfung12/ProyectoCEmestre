#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "../include/struct_definitions.h"
#include "../include/parser.h"

//Función auxiliar para leer un archivo completo y volcarlo en un búfer de memoria dinámico
static char* read_file_to_string(const char *filepath) {
    //Abrimos el archivo en modo lectura binaria ("rb")
    FILE *file = fopen(filepath, "rb");
    if (!file) return NULL;

    //Calculamos el tamaño total del archivo moviendo el cursor al final
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET); //Regresamos el cursor al inicio

    //Reservamos memoria para todo el contenido + el carácter nulo de cierre ('\0')
    char *buffer = (char *)malloc(length + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }

    //Leemos el contenido del archivo hacia el búfer
    size_t bytes_read = fread(buffer, 1, length, file);
    buffer[bytes_read] = '\0'; //Aseguramos el fin de cadena
    fclose(file);

    return buffer;
}

//Función auxiliar para extraer el valor de una llave de tipo texto (string) en formato JSON
static void get_json_string_val(const char *json, const char *key, char *out, size_t max_len) {
    out[0] = '\0';
    char pattern[64];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key); //Armamos el patrón de búsqueda ej. "code"
    
    //Buscamos la posición de la llave dentro del texto JSON
    char *pos = strstr(json, pattern);
    if (!pos) return;

    //Buscamos los dos puntos ':' que separan la llave del valor
    pos = strchr(pos + strlen(pattern), ':');
    if (!pos) return;

    //Buscamos la comilla de apertura del valor de texto
    pos = strchr(pos, '"');
    if (!pos) return;

    pos++; //Saltamos la comilla inicial
    char *end = strchr(pos, '"'); //Buscamos la comilla de cierre
    if (!end) return;

    //Calculamos la longitud y copiamos la cadena de manera segura
    size_t len = end - pos;
    if (len >= max_len) len = max_len - 1;
    strncpy(out, pos, len);
    out[len] = '\0';
}

//Función auxiliar para extraer el valor de una llave numérica entera (int) del JSON
static int get_json_int_val(const char *json, const char *key) {
    char pattern[64];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key);
    
    char *pos = strstr(json, pattern);
    if (!pos) return 0;

    pos = strchr(pos + strlen(pattern), ':');
    if (!pos) return 0;

    pos++;
    //Avanzamos el puntero hasta encontrar un número válido o signo negativo
    while (*pos && !isdigit((unsigned char)*pos) && *pos != '-') pos++;
    return atoi(pos); //Convertimos el texto numérico a entero
}

//Función auxiliar para extraer arreglos de cadenas de texto (ej. prerrequisitos, correquisitos)
static void get_json_array_strings(const char *json, const char *key, char out_arr[][MAX_CODE_LEN], int *out_count, int max_items) {
    *out_count = 0;
    char pattern[64];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key);

    char *pos = strstr(json, pattern);
    if (!pos) return;

    //Buscamos el inicio del arreglo corchete '['
    pos = strchr(pos + strlen(pattern), '[');
    if (!pos) return;

    char *end_bracket = strchr(pos, ']'); //Fin del arreglo
    if (!end_bracket) return;

    char *ptr = pos + 1;
    //Iteramos dentro del arreglo extrayendo cada elemento entre comillas
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

//Función para parsear la estructura anidada de grupos y bloques de horarios de un curso
static void parse_groups_and_schedules(const char *json_course, Course *course) {
    course->group_count = 0;
    
    char *groups_pos = strstr(json_course, "\"groups\"");
    if (!groups_pos) return;

    char *g_ptr = strchr(groups_pos, '[');
    if (!g_ptr) return;

    char *curr_g = strstr(g_ptr, "\"group_number\"");
    //Recorremos cada grupo disponible para el curso
    while (curr_g != NULL && course->group_count < MAX_GROUPS) {
        Group *g = &course->groups[course->group_count];
        g->group_number = get_json_int_val(curr_g, "group_number");
        g->schedule_count = 0;

        char *sched_pos = strstr(curr_g, "\"schedules\"");
        char *next_g = strstr(curr_g + 14, "\"group_number\"");

        if (sched_pos && (!next_g || sched_pos < next_g)) {
            char *s_ptr = strchr(sched_pos, '[');
            if (s_ptr && (!next_g || s_ptr < next_g)) {
                char *curr_s = strstr(s_ptr, "\"day\"");
                
                //Recorremos los bloques de horario asignados al grupo actual
                while (curr_s != NULL && (!next_g || curr_s < next_g) && g->schedule_count < MAX_SCHEDULES_PER_GROUP) {
                    char *end_schedules = strchr(s_ptr, ']');
                    if (end_schedules && curr_s > end_schedules) break;

                    ScheduleBlock *s = &g->schedules[g->schedule_count];
                    s->day = get_json_int_val(curr_s, "day");
                    s->start_time = get_json_int_val(curr_s, "start_time");
                    s->end_time = get_json_int_val(curr_s, "end_time");
                    g->schedule_count++;

                    curr_s = strstr(curr_s + 5, "\"day\"");
                }
            }
        }

        course->group_count++;
        curr_g = next_g;
    }
}

//Función principal para cargar y deserializar todo el catálogo de cursos desde un archivo JSON
bool load_catalog(const char *filename, Catalog *catalog) {
    if (!catalog) return false;
    catalog->course_count = 0;

    //Leemos el archivo JSON a una cadena en memoria
    char *json_data = read_file_to_string(filename);
    if (!json_data) return false;

    char *cursor = json_data;
    //Analizamos el archivo buscando los objetos correspondientes a cada curso
    while (catalog->course_count < MAX_COURSES) {
        char *brace_start = strchr(cursor, '{');
        if (!brace_start) break;

        //Algoritmo de conteo de llaves para delimitar correctamente cada objeto JSON de curso
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
        *obj_end = '\0'; //Temporalmente cerramos la cadena en el objeto actual

        Course *c = &catalog->courses[catalog->course_count];
        memset(c, 0, sizeof(Course)); //Limpiamos memoria del curso por seguridad

        //Extraemos cada propiedad del curso usando los helpers definidos arriba
        get_json_string_val(brace_start, "code", c->code, sizeof(c->code));
        get_json_string_val(brace_start, "name", c->name, sizeof(c->name));
        get_json_string_val(brace_start, "career", c->career, sizeof(c->career));
        c->credits = get_json_int_val(brace_start, "credits");
        c->semester = get_json_int_val(brace_start, "semester");

        get_json_array_strings(brace_start, "prerequisites", c->prerequisites, &c->prereq_count, MAX_PREREQUISITES);
        get_json_array_strings(brace_start, "corequisites", c->corequisites, &c->coreq_count, MAX_COREQUISITES);

        parse_groups_and_schedules(brace_start, c);

        catalog->course_count++;

        *obj_end = backup; //Restauramos el caracter original del JSON
        cursor = obj_end + 1; //Movemos el cursor al siguiente curso
    }

    free(json_data); //Liberamos el búfer general del archivo
    return true;
}

//Función para cargar el historial académico del estudiante desde un archivo JSON
bool load_student_history(const char *filename, StudentHistory *history) {
    if (!history) return false;

    char *json_data = read_file_to_string(filename);
    if (!json_data) return false;

    history->approved_count = 0;
    
    //Buscamos el inicio del arreglo de cursos aprobados '['
    char *array_start = strchr(json_data, '[');
    if (!array_start) {
        free(json_data);
        return false;
    }

    char *ptr = array_start;
    //Extraemos cada código de materia aprobado encerrado entre comillas dobles
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

//Función para liberar los recursos del catálogo (en este caso resetea el contador)
void free_catalog(Catalog *catalog) {
    if (catalog) {
        catalog->course_count = 0;
    }
}