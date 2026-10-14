#ifndef SCHEDULE_CHECKER_H
#define SCHEDULE_CHECKER_H

#include "struct_definitions.h"

//Comprueba si dos grupos distintos coinciden en día y hora
bool groups_overlap(const Group *g1, const Group *g2);

//Recorre todo el catálogo para detectar y marcar los choques de horario por curso
void check_schedule_clashes(Catalog *catalog);

#endif