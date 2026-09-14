#ifndef PARSER_H
#define PARSER_H

#include <stdbool.h>
#include "struct_definitions.h"

//Carga los cursos del plan de estudios desde un archivo JSON hacia el catálogo
bool load_catalog(const char *filename, Catalog *catalog);

//Carga la lista de códigos aprobados por el estudiante
bool load_student_history(const char *filename, StudentHistory *history);

//Libera la memoria asignada al catálogo
void free_catalog(Catalog *catalog);

#endif