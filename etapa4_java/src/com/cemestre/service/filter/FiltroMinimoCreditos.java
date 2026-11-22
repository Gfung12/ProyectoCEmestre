package com.cemestre.service.filter;

import com.cemestre.model.CombinacionEval;

public class FiltroMinimoCreditos implements FiltroCombinacion {
    private final int minimoCreditos;

    public FiltroMinimoCreditos(int minimoCreditos) {
        if (minimoCreditos < 0) {
            throw new IllegalArgumentException("El mínimo de créditos no puede ser negativo.");
        }
        this.minimoCreditos = minimoCreditos;
    }

    public int getMinimoCreditos() {
        return minimoCreditos;
    }

    @Override
    public boolean cumple(CombinacionEval combinacion) {
        return combinacion != null && combinacion.obtenerTotalCreditos() >= minimoCreditos;
    }
}