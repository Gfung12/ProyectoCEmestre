//
// Created by damoz on 18/9/2026.
//

#include <stdio.h>
#include <string.h>
#include "../include/struct_definitions.h"
#include "../include/validator.h"

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
        const Course *c = &catalog->courses[i];

        // 1. Validar que el estudiante no haya dejado el código o nombre en blanco
        if (strlen(c->code) == 0) {
            printf("Error [Índice %d]: Hay un curso sin código asignado.\n", i);
            all_good = false;
        }

        // 2. Validar que los créditos tengan sentido lógico
        // Asumimos que un curso de la carrera no puede tener menos de 0 ni más de 10 créditos
        if (c->credits < 0 || c->credits > 10) {
            printf("Error [%s]: Cantidad de créditos inválida o estúpida (%d).\n", c->code, c->credits);
            all_good = false;
        }

        // 3. Cazar prerrequisitos fantasma
        for (int j = 0; j < c->prereq_count; j++) {
            if (!course_exists_in_catalog(c->prerequisites[j], catalog)) {
                printf("Error [%s]: Pide un prerrequisito fantasma (%s) que NO existe en el plan.\n", c->code, c->prerequisites[j]);
                all_good = false;
            }
        }

        // 4. Cazar correquisitos fantasma
        for (int j = 0; j < c->coreq_count; j++) {
            if (!course_exists_in_catalog(c->corequisites[j], catalog)) {
                printf("Error [%s]: Pide un correquisito fantasma (%s) que NO existe en el plan.\n", c->code, c->corequisites[j]);
                all_good = false;
            }
        }
    }

    return all_good; // Retorna true solo si sobrevivió a todas las pruebas sin tirar errores
}