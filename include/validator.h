//
// Created by damoz on 18/9/2026.
//

#ifndef PROYECTOCEMESTRE_VALIDATOR_H
#define PROYECTOCEMESTRE_VALIDATOR_H

#include <stdbool.h>
#include "struct_definitions.h"

// Sanea y valida el catálogo completo del plan de estudios
bool validate_catalog(Catalog *catalog);

// Valida que el historial del estudiante no tenga materias repetidas ni inventadas
bool validate_student_history(StudentHistory *history, const Catalog *catalog);

#endif //PROYECTOCEMESTRE_VALIDATOR_H
