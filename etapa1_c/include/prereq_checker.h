#ifndef PREREQ_CHECKER_H
#define PREREQ_CHECKER_H

#include <stdbool.h>
#include "struct_definitions.h"

//Verifica si un curso ya fue aprobado por el estudiante
bool is_course_approved(const char *code, const StudentHistory *history);

//Verifica si el estudiante cumple con todos los prerrequisitos de un curso
bool can_take_course(const Course *course, const StudentHistory *history, const Catalog *catalog);

#endif