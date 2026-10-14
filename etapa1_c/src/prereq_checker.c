#include <stdio.h>
#include <string.h>
#include "../include/struct_definitions.h"
#include "../include/prereq_checker.h"
//Se debe de tomar en cuenta que si el código del curso no está de la misma forma escrito, se toma como no aprobado
bool is_course_approved(const char *code, const StudentHistory *history) {
    if (!code || !history) return false;

    for (int i = 0; i < history->approved_count; i++) {
        if (strcmp(history->approved_courses[i], code) == 0) {
            return true;
        }
    }
    return false;
}

bool can_take_course(const Course *course, const StudentHistory *history, const Catalog *catalog) { // ACA FALTABA EL CATALOGO
    if (!course || !history || !catalog) return false;

    //Si el estudiante ya aprobó la materia, no necesita volver a llevarla
    if (is_course_approved(course->code, history)) {
        return false;
    }

    //Verificar que TODOS los prerrequisitos estén aprobados
    for (int i = 0; i < course->prereq_count; i++) {
        if (!is_course_approved(course->prerequisites[i], history)) {
            return false;
        }
    }

    //Verifica si el curso necesita corequisitos y si se tiene del mismo
    for (int i = 0; i < course->coreq_count; i++) {
        const char *coreq_code = course->corequisites[i];

        if (is_course_approved(coreq_code, history)) {
            continue;
        }

        bool can_take_coreq = false; // el curso no se ha aprobado

        // revisar si el correquisito es matriculable
        for (int j = 0; j < catalog->course_count; j++) {
            if (strcmp(catalog->courses[j].code, coreq_code) == 0) {
                can_take_coreq = true;

                
                for (int k = 0; k < catalog->courses[j].prereq_count; k++) {
                    if (!is_course_approved(catalog->courses[j].prerequisites[k], history)) {
                        can_take_coreq = false; // ACA FALTABA ESTO para botar la bandera
                        break;
                    }
                }
                break; // Ya encontramos el curso, salimos del ciclo j
            }
        }//fin de  J

        // ESTO ESTABA ADENTRO DEL CICLO J, TIENE QUE IR AFUERA
        if (!can_take_coreq) {
            return false; // Lo pateamos, no puede llevar la materia principal.
        }

    } // FIN DEL CICLO I (Esta llave faltaba)

    return true;
}