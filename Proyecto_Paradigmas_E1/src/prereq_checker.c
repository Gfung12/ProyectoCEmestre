#include <stdio.h>
#include <string.h>
#include "../include/struct_definitions.h"
#include "../include/prereq_checker.h"

bool is_course_approved(const char *code, const StudentHistory *history) {
    if (!code || !history) return false;

    for (int i = 0; i < history->approved_count; i++) {
        if (strcmp(history->approved_courses[i], code) == 0) {
            return true;
        }
    }
    return false;
}

bool can_take_course(const Course *course, const StudentHistory *history) {
    if (!course || !history) return false;

    //Si el estudiante ya aprobó la materia, no necesita volver a llevarla
    if (is_course_approved(course->code, history)) {
        return false;
    }

    //Verificar que TODOS los prerrequisitos estén aprobados
    for (int i = 0; i < course->prereq_count; i++) {
        if (!is_course_approved(course->prerequisites[i], history)) {
            return false;
        }
    }

    return true;
}