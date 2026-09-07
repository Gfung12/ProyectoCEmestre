#ifndef STRUCT_DEFINITIONS_H
#define STRUCT_DEFINITIONS_H

#include <stdbool.h>
#include "config.h"

//Estructura para representar un bloque de horario
typedef struct {
    int day; //1: Lunes, 2: Martes, 3: Miércoles, 4: Jueves, 5: Viernes, 6: Sábado
    int start_time; //Formato militar (ej: 700 para 07:00, 1300 para 13:00)
    int end_time; //Formato militar
} ScheduleBlock;

//Estructura para representar un grupo de un curso
typedef struct {
    int group_number;
    ScheduleBlock schedules[MAX_SCHEDULES_PER_GROUP];
    int schedule_count;
    bool has_clash; //Flag si este grupo choca con algún otro grupo
} Group;

//Estructura para representar un curso del plan de estudios
typedef struct {
    char code[MAX_CODE_LEN];
    char name[MAX_STRING_LEN];
    int credits;
    int semester;
    char career[MAX_STRING_LEN]; //"Computadores" o "Biotecnología"
    
    //Listas de códigos para requisitos y correquisitos
    char prerequisites[MAX_PREREQUISITES][MAX_CODE_LEN];
    int prereq_count;
    
    char corequisites[MAX_COREQUISITES][MAX_CODE_LEN];
    int coreq_count;
    
    //Grupos asignados al curso
    Group groups[MAX_GROUPS];
    int group_count;
    
    //Flags exigidos para la salida
    bool has_any_schedule_clash; //True si el curso choca con al menos otro curso/grupo
    bool is_eligible; //True si el estudiante cumple sus requisitos
} Course;

//Estructura para el catálogo completo de la carrera
typedef struct {
    Course courses[MAX_COURSES];
    int course_count;
} Catalog;

//Estructura para el historial académico del estudiante
typedef struct {
    char approved_courses[MAX_APPROVED_COURSES][MAX_CODE_LEN];
    int approved_count;
} StudentHistory;

#endif