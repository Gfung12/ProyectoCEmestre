package com.cemestre.service.filter;

import com.cemestre.model.CombinacionEval;

public class FiltroEstadoPoliticas implements FiltroCombinacion {
    private final boolean soloAprobadas;

    public FiltroEstadoPoliticas(boolean soloAprobadas) {
        this.soloAprobadas = soloAprobadas;
    }

    public boolean isSoloAprobadas() {
        return soloAprobadas;
    }

    @Override
    public boolean cumple(CombinacionEval combinacion) {
        return combinacion != null && combinacion.isCumplePoliticas() == soloAprobadas;
    }
}