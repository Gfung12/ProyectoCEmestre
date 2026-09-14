#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "../include/struct_definitions.h"
#include "../include/schedule_checker.h"

bool blocks_overlap(const ScheduleBlock *b1, const ScheduleBlock *b2) {
    if (b1->day != b2->day) return false;
    return (b1->start_time < b2->end_time && b2->start_time < b1->end_time);
}

bool groups_overlap(const Group *g1, const Group *g2) {
    if (g1->schedule_count == 0 || g2->schedule_count == 0) return false;

    for (int i = 0; i < g1->schedule_count; i++) {
        for (int j = 0; j < g2->schedule_count; j++) {
            if (blocks_overlap(&g1->schedules[i], &g2->schedules[j])) {
                return true;
            }
        }
    }
    return false;
}

void check_schedule_clashes(Catalog *catalog) {
    //Resetear todos a false
    for (int i = 0; i < catalog->course_count; i++) {
        catalog->courses[i].has_any_schedule_clash = false;
    }

    //Comparar solo dentro de la misma carrera, entre elegibles y que sean del mismo semestre
    for (int i = 0; i < catalog->course_count; i++) {
        Course *c1 = &catalog->courses[i];

        if (!c1->is_eligible) continue;

        for (int j = 0; j < catalog->course_count; j++) {
            if (i == j) continue;

            Course *c2 = &catalog->courses[j];

            //Solo comparar si pertenecen a la misma carrera
            if (strcmp(c1->career, c2->career) != 0) continue;

            //Solo comparar si la otra materia también es elegible
            if (!c2->is_eligible) continue;

            //Solo comparar si la otra materia es del mismo semestre
            if (c1->semester != c2->semester) continue;

            //Evaluar solapamiento de grupos
            bool clash_found = false;
            for (int g1 = 0; g1 < c1->group_count; g1++) {
                for (int g2 = 0; g2 < c2->group_count; g2++) {
                    if (groups_overlap(&c1->groups[g1], &c2->groups[g2])) {
                        clash_found = true;
                        break;
                    }
                }
                if (clash_found) break;
            }

            if (clash_found) {
                c1->has_any_schedule_clash = true;
                break;
            }
        }
    }
}