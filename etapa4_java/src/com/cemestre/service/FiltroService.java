package com.cemestre.service;

import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class FiltroService {

    public List<CombinacionEval> filtrarAprobadas(List<CombinacionEval> combinaciones) {
        if (combinaciones == null) return new ArrayList<>();
        return combinaciones.stream()
                .filter(CombinacionEval::isCumplePoliticas)
                .collect(Collectors.toList());
    }

    public List<CombinacionEval> filtrarRechazadas(List<CombinacionEval> combinaciones) {
        if (combinaciones == null) return new ArrayList<>();
        return combinaciones.stream()
                .filter(c -> !c.isCumplePoliticas())
                .collect(Collectors.toList());
    }

    public List<CombinacionEval> filtrarPorEstado(List<CombinacionEval> combinaciones, boolean soloAprobadas) {
        return soloAprobadas ? filtrarAprobadas(combinaciones) : filtrarRechazadas(combinaciones);
    }
}