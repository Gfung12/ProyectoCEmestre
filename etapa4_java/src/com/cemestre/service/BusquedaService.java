package com.cemestre.service;

import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

public class BusquedaService {

    public List<CombinacionEval> buscarPorCodigoCurso(List<CombinacionEval> combinaciones, String codigoCurso) {
        if (combinaciones == null || codigoCurso == null || codigoCurso.isBlank()) {
            return new ArrayList<>();
        }
        String objetivo = codigoCurso.trim().toUpperCase();
        return combinaciones.stream()
                .filter(c -> c.getCursos().stream()
                        .anyMatch(curso -> curso.getCodigo() != null
                                && curso.getCodigo().trim().toUpperCase().equals(objetivo)))
                .collect(Collectors.toList());
    }

    public List<CombinacionEval> buscarPorEstado(List<CombinacionEval> combinaciones, boolean aprobadas) {
        if (combinaciones == null) return new ArrayList<>();
        return combinaciones.stream()
                .filter(c -> c.isCumplePoliticas() == aprobadas)
                .collect(Collectors.toList());
    }

    public List<CombinacionEval> buscarPorCodigoYEstado(List<CombinacionEval> combinaciones, String codigoCurso, boolean aprobadas) {
        return buscarPorCodigoCurso(buscarPorEstado(combinaciones, aprobadas), codigoCurso);
    }

    public Optional<CombinacionEval> buscarPorId(List<CombinacionEval> combinaciones, int idCombinacion) {
        if (combinaciones == null) return Optional.empty();
        return combinaciones.stream()
                .filter(c -> c.getIdCombinacion() == idCombinacion)
                .findFirst();
    }
}