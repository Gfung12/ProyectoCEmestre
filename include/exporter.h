#ifndef EXPORTER_H
#define EXPORTER_H

#include <stdbool.h>
#include "struct_definitions.h"

//Exporta la estructura del catálogo a un archivo JSON con los flags calculados
bool export_catalog_to_json(const char *filename, const Catalog *catalog);

#endif