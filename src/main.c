#include <stdio.h>
#include <stdbool.h>
#include "../include/struct_definitions.h"
#include "../include/parser.h"
#include "../include/prereq_checker.h"
#include "../include/schedule_checker.h"
#include "../include/exporter.h"
#include "../include/validator.h"

int main(void) {
    //Inicializamos las estructuras principales del catálogo y el historial
    Catalog catalog = {0};
    StudentHistory history = {0};

    //Cargar datos desde los archivos JSON de entrada
    if (!load_catalog("data/plan_estudios.json", &catalog)) {
        fprintf(stderr, "Error al cargar el catálogo de cursos.\n");
        return 1;
    }

    if (!load_student_history("data/historial_estudiante.json", &history)) {
        fprintf(stderr, "Error al cargar el historial del estudiante.\n");
        return 1;
    }

    // --- NUEVO: FASE DE VALIDACIÓN ANTIESTUPIDEZ ---
    if (!validate_catalog(&catalog)) {
        fprintf(stderr, "Fallo crítico: El plan de estudios contiene datos erróneos. Proceso abortado.\n");
        free_catalog(&catalog);
        return 1;
    }

    if (!validate_student_history(&history, &catalog)) {
        fprintf(stderr, "Fallo crítico: El historial del estudiante contiene datos erróneos. Proceso abortado.\n");
        free_catalog(&catalog);
        return 1;
    }
    // ----------------------------------------------

    //Procesar la elegibilidad de cada curso basándose en el historial
    for (int i = 0; i < catalog.course_count; i++) {
        Course *course = &catalog.courses[i];
        course->is_approved = is_course_approved(course->code, &history);
        course->is_eligible = can_take_course(course, &history, &catalog);
    }

    //Evaluar los choques de horario delegando en el módulo correspondiente
    check_schedule_clashes(&catalog);

    //Exportar los resultados procesados al archivo JSON de salida
    if (export_catalog_to_json("data/output_schedule.json", &catalog)) {
        printf("Proceso completado con éxito. Resultados guardados en data/output_schedule.json\n");
    } else {
        fprintf(stderr, "Error al generar el archivo de salida.\n");
        free_catalog(&catalog);
        return 1;
    }

    //Liberar la memoria dinámica asignada al catálogo
    free_catalog(&catalog);
    return 0;
}