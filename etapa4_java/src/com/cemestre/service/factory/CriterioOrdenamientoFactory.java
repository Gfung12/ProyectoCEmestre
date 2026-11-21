package com.cemestre.service.factory;

import com.cemestre.service.strategy.CriterioOrdenamiento;
import com.cemestre.service.strategy.OrdenHoraPromedioInicio;
import com.cemestre.service.strategy.OrdenMayorCreditos;
import com.cemestre.service.strategy.OrdenMenosDias;
import com.cemestre.service.strategy.OrdenMenosHuecos;
import com.cemestre.service.strategy.TipoCriterio;

public class CriterioOrdenamientoFactory {

    public static CriterioOrdenamiento crearCriterio(TipoCriterio tipo) {
        if (tipo == null) {
            throw new IllegalArgumentException("El criterio de ordenamiento no puede ser nulo.");
        }
        return switch (tipo) {
            case MENOS_DIAS -> new OrdenMenosDias();
            case MENOS_HUECOS -> new OrdenMenosHuecos();
            case HORA_PROMEDIO_INICIO -> new OrdenHoraPromedioInicio();
            case MAYOR_CREDITOS -> new OrdenMayorCreditos();
        };
    }
}