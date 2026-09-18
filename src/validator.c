//
// Created by damoz on 18/9/2026.
//

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include "../include/struct_definitions.h"
#include "../include/validator.h"

// Revisa que el código solo tenga letras y números (sin comas, espacios, etc.)
bool is_valid_code_format(const char *code) {
    if (!code || strlen(code) == 0) return false;

    for (int i = 0; code[i] != '\0'; i++) {
        unsigned char c = (unsigned char)code[i];
        if (!isalnum(c)) {
            return false;
        }
    }
    return true;
}

// Limpia el código: quita espacios en blanco de extremos y pasa a MAYÚSCULAS
void sanitize_code(char *code) {
    if (!code) return;

    // Quitar espacios al inicio
    char *start = code;
    while (isspace((unsigned char)*start)) {
        start++;
    }

    if (*start == '\0') {
        code[0] = '\0';
        return;
    }

    // Quitar espacios al final
    char *end = start + strlen(start) - 1;
    while (end > start && isspace((unsigned char)*end)) {
        end--;
    }
    *(end + 1) = '\0';

    // Copiar hacia el inicio y pasar a mayúsculas
    int i = 0;
    while (start <= end) {
        code[i] = (char)toupper((unsigned char)*start);
        i++;
        start++;
    }
    code[i] = '\0';
}

// Busca secuencialmente si un código X existe en el catálogo
static bool course_exists_in_catalog(const char *code, const Catalog *catalog) {
    for (int i = 0; i < catalog->course_count; i++) {
        if (strcmp(catalog->courses[i].code, code) == 0) {
            return true;
        }
    }
    return false;
}

// OJO: Sin 'const' para permitir que sanitize_code arregle los strings en sitio
bool validate_catalog(Catalog *catalog) {
    if (!catalog || catalog->course_count == 0) {
        printf("Error fatal: El catálogo está vacío o nulo.\n");
        return false;
    }

    bool all_good = true;

    // PASADA 1: Sanitizar absolutamente todos los códigos primero
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

    // PASADA 2: Validar formatos y relaciones de negocio
    for (int i = 0; i < catalog->course_count; i++) {
        Course *c = &catalog->courses[i];

        // 1. Formato del código del curso
        if (!is_valid_code_format(c->code)) {
            printf("Error [Índice %d]: El código '%s' tiene formato inválido o caracteres prohibidos.\n", i, c->code);
            all_good = false;
        }

        // 2. Créditos lógicos
        if (c->credits < 0 || c->credits > 10) {
            printf("Error [%s]: Créditos inválidos (%d). Deben estar entre 0 y 10.\n", c->code, c->credits);
            all_good = false;
        }

        // 3. Semestre válido (0 a 4 según el alcance de la etapa)
        if (c->semester < 0 || c->semester > 4) {
            printf("Error [%s]: Semestre fuera del alcance del proyecto (%d).\n", c->code, c->semester);
            all_good = false;
        }

        // 4. Prerrequisitos válidos y existentes
        for (int j = 0; j < c->prereq_count; j++) {
            if (!is_valid_code_format(c->prerequisites[j])) {
                printf("Error [%s]: Prerrequisito '%s' con caracteres inválidos.\n", c->code, c->prerequisites[j]);
                all_good = false;
            } else if (!course_exists_in_catalog(c->prerequisites[j], catalog)) {
                printf("Error [%s]: Pide prerrequisito fantasma '%s' que no existe en el catálogo.\n", c->code, c->prerequisites[j]);
                all_good = false;
            }
        }

        // 5. Correquisitos válidos y existentes
        for (int j = 0; j < c->coreq_count; j++) {
            if (!is_valid_code_format(c->corequisites[j])) {
                printf("Error [%s]: Correquisito '%s' con caracteres inválidos.\n", c->code, c->corequisites[j]);
                all_good = false;
            } else if (!course_exists_in_catalog(c->corequisites[j], catalog)) {
                printf("Error [%s]: Pide correquisito fantasma '%s' que no existe en el catálogo.\n", c->code, c->corequisites[j]);
                all_good = false;
            }
        }
    }

    return all_good;
}