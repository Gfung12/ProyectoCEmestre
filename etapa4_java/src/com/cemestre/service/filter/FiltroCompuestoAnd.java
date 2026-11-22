package com.cemestre.service.filter;

import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class FiltroCompuestoAnd implements FiltroCombinacion {
    private final List<FiltroCombinacion> filtros;

    public FiltroCompuestoAnd(List<FiltroCombinacion> filtros) {
        if (filtros == null || filtros.isEmpty()) {
            throw new IllegalArgumentException("Debe indicar al menos un filtro para AND.");
        }
        for (FiltroCombinacion f : filtros) {
            if (f == null) {
                throw new IllegalArgumentException("Ningún subfiltro puede ser nulo.");
            }
        }
        this.filtros = new ArrayList<>(filtros);
    }

    public FiltroCompuestoAnd(FiltroCombinacion... filtros) {
        this(filtros == null ? null : Arrays.asList(filtros));
    }

    public List<FiltroCombinacion> getFiltros() {
        return Collections.unmodifiableList(filtros);
    }

    @Override
    public boolean cumple(CombinacionEval combinacion) {
        if (combinacion == null) {
            return false;
        }
        for (FiltroCombinacion filtro : filtros) {
            if (!filtro.cumple(combinacion)) {
                return false;
            }
        }
        return true;
    }
}