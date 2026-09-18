//
// Created by damoz on 18/9/2026.
//

#ifndef PROYECTOCEMESTRE_VALIDATOR_H
#define PROYECTOCEMESTRE_VALIDATOR_H

#include <stdbool.h>
#include "struct_definitions.h"

// Función que revisa todo el catálogo buscando inconsistencias del usuario
bool validate_catalog(Catalog *catalog);

#endif //PROYECTOCEMESTRE_VALIDATOR_H
