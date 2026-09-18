//
// Created by damoz on 18/9/2026.
//

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include "../include/struct_definitions.h"
#include "../include/validator.h"

// 1. Revisa que el código solo tenga caracteres alfanuméricos válidos
// Rechaza si tiene comas, puntos, espacios intermedios, etc.
bool is_valid_code_format(const char *code) {
    if (!code || strlen(code) == 0) return false;

    for (int i = 0; code[i] != '\0'; i++) {
        unsigned char c = (unsigned char)code[i];
        // Si no es ni letra ni dígito, es un caracter no deseado (coma, punto, espacio, etc.)
        if (!isalnum(c)) {
            return false;
        }
    }
    return true;
}

// 2. Limpia el código: quita espacios a los bordes y pasa todo a MAYÚSCULAS
void sanitize_code(char *code) {
    if (!code) return;

    // Quitar espacios al inicio
    char *start = code;
    while (isspace((unsigned char)*start)) {
        start++;
    }

    // Si toda la cadena eran espacios
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

// Función auxiliar privada (solo sirve en este archivo)
// Busca secuencialmente si un código X existe como materia oficial en el catálogo
static bool course_exists_in_catalog(const char *code, const Catalog *catalog) {
    for (int i = 0; i < catalog->course_count; i++) {
        if (strcmp(catalog->courses[i].code, code) == 0) {
            return true; // El código sí pertenece a una materia real
        }
    }
    return false; // El código es un invento
}

bool validate_catalog(const Catalog *catalog) {
    if (!catalog || catalog->course_count == 0) {
        printf("Error fatal: El catálogo está vacío o nulo.\n");
        return false;
    }

    bool all_good = true;

    for (int i = 0; i < catalog->course_count; i++) {
        Course *c = &catalog->courses[i];

        // Primero saneamos (quitamos espacios de bordes y pasamos a mayúsculas)
        sanitize_code(c->code);

        // Ahora verificamos que no tenga comas, puntos o símbolos raros
        if (!is_valid_code_format(c->code)) {
            printf("Error: El código de curso '%s' tiene formato inválido (contiene espacios internos, puntos, comas o símbolos).\n", c->code);
            all_good = false;
        }

        // Lo mismo para cada uno de sus prerrequisitos
        for (int j = 0; j < c->prereq_count; j++) {
            sanitize_code(c->prerequisites[j]);
            if (!is_valid_code_format(c->prerequisites[j])) {
                printf("Error [%s]: El prerrequisito '%s' tiene caracteres inválidos.\n", c->code, c->prerequisites[j]);
                all_good = false;
            }
        }

        // Lo mismo para cada uno de sus correquisitos
        for (int j = 0; j < c->coreq_count; j++) {
            sanitize_code(c->corequisites[j]);
            if (!is_valid_code_format(c->corequisites[j])) {
                printf("Error [%s]: El correquisito '%s' tiene caracteres inválidos.\n", c->code, c->corequisites[j]);
                all_good = false;
            }
        }
    }

    return all_good; // Retorna true solo si sobrevivió a todas las pruebas sin tirar errores
}