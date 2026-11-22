package com.cemestre.service.filter;

import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@FunctionalInterface
public interface FiltroCombinacion {
    boolean cumple(CombinacionEval combinacion);

    default List<CombinacionEval> aplicar(List<CombinacionEval> combinaciones) {
        if (combinaciones == null) {
            return new ArrayList<>();
        }
        return combinaciones.stream()
                .filter(this::cumple)
                .collect(Collectors.toList());
    }

    default FiltroCombinacion and(FiltroCombinacion otro) {
        if (otro == null) {
            throw new IllegalArgumentException("El filtro secundario no puede ser nulo.");
        }
        return new FiltroCompuestoAnd(List.of(this, otro));
    }

    default FiltroCombinacion or(FiltroCombinacion otro) {
        if (otro == null) {
            throw new IllegalArgumentException("El filtro secundario no puede ser nulo.");
        }
        return new FiltroCompuestoOr(List.of(this, otro));
    }
}