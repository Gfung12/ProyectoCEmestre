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

    printf("Revisando la integridad de los datos del plan de estudios...\n");
    if (!validate_catalog(&catalog)) {
        fprintf(stderr, "La validación falló. Arregle las erorres en el JSON antes de continuar.\n");
        free_catalog(&catalog);
        return 1;
    }
    printf("Datos validados correctamente. Todo en orden.\n");

    if (!load_student_history("data/historial_estudiante.json", &history)) {
        fprintf(stderr, "Error al cargar el historial del estudiante.\n");
        return 1;
    }

    //Procesar la elegibilidad de cada curso basándose en el historial
    for (int i = 0; i < catalog.course_count; i++) {
        Course *course = &catalog.courses[i];
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