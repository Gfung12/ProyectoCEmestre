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

    //Iniciamos el arreglo JSON principal
    fprintf(file, "[\n");
    //Recorremos cada curso del catálogo
    for (int i = 0; i < catalog->course_count; i++) {
        const Course *c = &catalog->courses[i];

        //Escribimos los atributos principales de cada curso en formato JSON
        fprintf(file, "  {\n");
        fprintf(file, "    \"code\": \"%s\",\n", c->code);
        fprintf(file, "    \"name\": \"%s\",\n", c->name);
        fprintf(file, "    \"career\": \"%s\",\n", c->career);
        fprintf(file, "    \"credits\": %d,\n", c->credits);
        fprintf(file, "    \"semester\": %d,\n", c->semester);
        
        //Convertimos los booleanos de C a literales "true" o "false" para JSON
        fprintf(file, "    \"is_eligible\": %s,\n", c->is_eligible ? "true" : "false");
        fprintf(file, "    \"has_any_schedule_clash\": %s\n", c->has_any_schedule_clash ? "true" : "false");
        
        //Cerramos el objeto del curso, añadiendo una coma si no es el último elemento
        fprintf(file, "  }%s\n", (i < catalog->course_count - 1) ? "," : "");
    }
    //Cerramos el arreglo JSON principal
    fprintf(file, "]\n");

    //Cerramos el archivo y retornamos éxito
    fclose(file);
    return true;
}