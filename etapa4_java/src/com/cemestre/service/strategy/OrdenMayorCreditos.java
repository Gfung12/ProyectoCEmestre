package com.cemestre.service.strategy;

import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class OrdenMayorCreditos implements CriterioOrdenamiento {

    @Override
    public List<CombinacionEval> ordenar(List<CombinacionEval> combinaciones) {
        List<CombinacionEval> copia = new ArrayList<>(combinaciones);
        copia.sort(Comparator.comparingInt(CombinacionEval::obtenerTotalCreditos).reversed()
                .thenComparingInt(CombinacionEval::getIdCombinacion));
        return copia;
    }

    @Override
    public String getNombre() {
        return "Mayor cantidad de créditos";
    }
}