package com.cemestre.service;

import com.cemestre.model.CombinacionEval;
import com.cemestre.service.filter.FiltroCombinacion;
import com.cemestre.service.filter.FiltroEstadoPoliticas;

import java.util.ArrayList;
import java.util.List;

public class FiltroService {

    public List<CombinacionEval> filtrar(List<CombinacionEval> combinaciones, FiltroCombinacion filtro) {
        if (combinaciones == null || filtro == null) {
            return new ArrayList<>();
        }
        return filtro.aplicar(combinaciones);
    }

    public List<CombinacionEval> filtrarAprobadas(List<CombinacionEval> combinaciones) {
        return filtrar(combinaciones, new FiltroEstadoPoliticas(true));
    }

    public List<CombinacionEval> filtrarRechazadas(List<CombinacionEval> combinaciones) {
        return filtrar(combinaciones, new FiltroEstadoPoliticas(false));
    }

    public List<CombinacionEval> filtrarPorEstado(List<CombinacionEval> combinaciones, boolean soloAprobadas) {
        return filtrar(combinaciones, new FiltroEstadoPoliticas(soloAprobadas));
    }
}