#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "../include/struct_definitions.h"
#include "../include/schedule_checker.h"

// Aquí nos dice si dos HORARIOS chocan.
bool blocks_overlap(const ScheduleBlock *b1, const ScheduleBlock *b2) {
    if (b1->day != b2->day) return false; // Primero si los días son diferentes entonces es imposible que choquen

    /* - La primera empieza antes de que el segundo termine.
     * - La segunda empieza antes de que el primero termine. */
    return (b1->start_time < b2->end_time && b2->start_time < b1->end_time);
}

// Acá nos dice si algún DÍA del grupo 1 choca con algún DÍA del grupo 2
bool groups_overlap(const Group *g1, const Group *g2) {
    if (g1->schedule_count == 0 || g2->schedule_count == 0) return false; // Verificamos si alguno de los grupos tengan algún horario

    /* Comparamos el primer día del grupo 1 y se compara con todos los días del grupo 2,
     * luego el segundo día del grupo 1 con todos los días del grupo 2, y repetimos */
    for (int i = 0; i < g1->schedule_count; i++) {
        for (int j = 0; j < g2->schedule_count; j++) {
            if (blocks_overlap(&g1->schedules[i], &g2->schedules[j])) {
                return true; // Un choque retornamos true
            }
        }
    }
    return false;
}

// Recorre el catálogo para marcar choques por grupo y por curso
void check_schedule_clashes(Catalog *catalog) {
    // 1. Inicializar todos los flags de colisión en falso
    for (int i = 0; i < catalog->course_count; i++) {
        catalog->courses[i].has_any_schedule_clash = false;
        for (int g = 0; g < catalog->courses[i].group_count; g++) {
            catalog->courses[i].groups[g].has_clash = false;
        }
    }

    // 2. Iterar sobre todos los cursos elegibles (c1)
    for (int i = 0; i < catalog->course_count; i++) {
        Course *c1 = &catalog->courses[i];
        if (!c1->is_eligible) continue; // Solo evaluamos cursos que el estudiante puede llevar

        // Evaluar cada grupo de c1 individualmente
        for (int g1 = 0; g1 < c1->group_count; g1++) {
            Group *group1 = &c1->groups[g1];

            // Comparar contra todos los demás cursos elegibles (c2)
            for (int j = 0; j < catalog->course_count; j++) {
                if (i == j) continue; // Evitar auto-comparación

                Course *c2 = &catalog->courses[j];

                // Solo nos importan los c2 que el estudiante pueda llevar y que sea de la misma carrera 
                if (!c2->is_eligible) continue;
                if (strcmp(c1->career, c2->career) != 0) continue; // Solo misma carrera

                // Evaluar contra los grupos de c2
                for (int g2 = 0; g2 < c2->group_count; g2++) {
                    Group *group2 = &c2->groups[g2];

                    if (groups_overlap(group1, group2)) {
                        group1->has_clash = true;
                        break; // group1 ya tiene choque, no hace falta seguir comparándolo con otros grupos de c2
                    }
                }

                if (group1->has_clash) {
                    break; // group1 ya está marcado, pasamos al siguiente grupo de c1
                }
            }
        }

        // 3. Verificar si TODOS los grupos de c1 resultaron con choques
        if (c1->group_count > 0) {
            bool all_groups_clash = true;
            for (int g1 = 0; g1 < c1->group_count; g1++) {
                if (!c1->groups[g1].has_clash) {
                    all_groups_clash = false;
                    break; // Al menos un grupo está libre
                }
            }

            // Si no hay escapatoria, el curso entero choca
            if (all_groups_clash) {
                c1->has_any_schedule_clash = true;
            }
        }
    }
}