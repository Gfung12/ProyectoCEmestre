package com.cemestre.service.filter;

import com.cemestre.model.CombinacionEval;
import com.cemestre.model.CursoEval;

public class FiltroCodigoCurso implements FiltroCombinacion {
    private final String codigoCurso;

    public FiltroCodigoCurso(String codigoCurso) {
        if (codigoCurso == null || codigoCurso.isBlank()) {
            throw new IllegalArgumentException("El código de curso no puede ser nulo o vacío.");
        }
        this.codigoCurso = codigoCurso.trim().toUpperCase();
    }

    public String getCodigoCurso() {
        return codigoCurso;
    }

    @Override
    public boolean cumple(CombinacionEval combinacion) {
        if (combinacion == null) {
            return false;
        }
        for (CursoEval curso : combinacion.getCursos()) {
            if (curso.getCodigo() != null && curso.getCodigo().trim().toUpperCase().equals(codigoCurso)) {
                return true;
            }
        }
        return false;
    }
}