#include <stdio.h>
#include <stdbool.h>
#include "../include/struct_definitions.h"
#include "../include/exporter.h"

//Función para exportar la información del catálogo de cursos a un archivo JSON
bool export_catalog_to_json(const char *filename, const Catalog *catalog) {
    //Validamos que el nombre del archivo y el catálogo no sean nulos
    if (!filename || !catalog) return false;

    //Abrimos el archivo en modo escritura ("w")
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Error al crear el archivo JSON de salida");
        return false;
    }

    //Iniciamos el arreglo JSON principal que contendrá todos los cursos
    fprintf(file, "[\n");

    //Recorremos cada curso del catálogo
    for (int i = 0; i < catalog->course_count; i++) {
        const Course *c = &catalog->courses[i];

        //Escribimos los atributos principales de cada curso en formato JSON

        // Abrimos el "folder" del curso
        fprintf(file, "  {\n");

        // Imprimimos strings
        fprintf(file, "    \"code\": \"%s\",\n", c->code);
        fprintf(file, "    \"name\": \"%s\",\n", c->name);
        fprintf(file, "    \"career\": \"%s\",\n", c->career);

        // Imprimimos números
        fprintf(file, "    \"credits\": %d,\n", c->credits);
        fprintf(file, "    \"semester\": %d,\n", c->semester);
        
        //Convertimos los booleanos de C a literales "true" o "false" para JSON
        fprintf(file, "    \"is_eligible\": %s,\n", c->is_eligible ? "true" : "false");
        fprintf(file, "    \"has_any_schedule_clash\": %s\n", c->has_any_schedule_clash ? "true" : "false");

        // Arreglos de requisitos
        fprintf(file, "    \"prerequisites\": [");
        for (int p = 0; p < c->prereq_count; p++) {
            fprintf(file, "\"%s\"", c->prerequisites[p]);
            // Si aún no es el último requisito ponemos coma
            if (p < c->prereq_count - 1) fprintf(file, ", ");
        }
        fprintf(file, "]\n"); // Cerramos el arreglo de requisitos

        // Arreglos de correquisitos
        fprintf(file, "    \"corequisites\": [");
        for(int q = 0; q < c->coreq_count; q++) {
            fprintf(file, "\"%s\"", c->corequisites[q]);
            if (q < c->coreq_count - 1) fprintf(file, ", ");
        }
        fprintf(file, "],\n"); // Cerramos el arreglo de correquisitos

        // Arreglos de grupos
        fprintf(file, "    \"groups\": [\n");
        for (int g = 0; g < c->group_count; g++) {
            const Group *grp = &c->groups[g];

            // Abrimos el sobre de un grupo específico
            fprintf(file, "      {\n");
            fprintf(file, "        \"group_number\": %d,\n", grp->group_number);
            fprintf(file, "        \"has_clash\": %s,\n", grp->has_clash ? "true" : "false");

            // Arreglos de horarios dentro del grupo
            fprintf(file, "        \"schedules\": [\n");
            for (int s = 0; s < grp->schedule_count; s++) {
                const ScheduleBlock *sch = &grp->schedules[s];

                // Imprimimos el bloque de horario
                fprintf(file, "          {\"day\": %d, \"start_time\": %d, \"end_time\": %d}",
                        sch->day, sch->start_time, sch->end_time);

                // Si no es el último horario, agregamos coma
                if (s < grp->schedule_count - 1) {
                    fprintf(file, ",\n");
                } else {
                    fprintf(file, "\n");
                }
            }
            fprintf(file, "        ]\n"); // Cerramos los horarios del grupo

            // Cerramos el sobre del grupo. Si no es el último grupo, agregamos coma
            fprintf(file, "      }%s\n", (g < c->group_count - 1) ? "," : "");
        }
        fprintf(file, "    ]\n"); // Cerramos la caja de todos los grupos

        //Cerramos el objeto del curso, añadiendo una coma si no es el último elemento
        fprintf(file, "  }%s\n", (i < catalog->course_count - 1) ? "," : "");
    }
    //Cerramos el arreglo JSON principal
    fprintf(file, "]\n");

    //Cerramos el archivo y retornamos éxito
    fclose(file);
    return true;
}