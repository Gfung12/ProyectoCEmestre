package com.cemestre.service;

import com.cemestre.model.CombinacionEval;
import com.cemestre.service.factory.CriterioOrdenamientoFactory;
import com.cemestre.service.strategy.CriterioOrdenamiento;
import com.cemestre.service.strategy.TipoCriterio;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class OrdenamientoService {
    private CriterioOrdenamiento criterioActual;

    public OrdenamientoService(CriterioOrdenamiento criterioInicial) {
        this.criterioActual = criterioInicial;
    }

    public OrdenamientoService(TipoCriterio tipoInicial) {
        this.criterioActual = CriterioOrdenamientoFactory.crearCriterio(tipoInicial);
    }

    public void setCriterio(CriterioOrdenamiento nuevoCriterio) {
        if (nuevoCriterio == null) {
            throw new IllegalArgumentException("El criterio no puede ser nulo.");
        }
        this.criterioActual = nuevoCriterio;
    }

    public void setCriterio(TipoCriterio tipo) {
        this.criterioActual = CriterioOrdenamientoFactory.crearCriterio(tipo);
    }

    public CriterioOrdenamiento getCriterioActual() {
        return criterioActual;
    }

    public List<CombinacionEval> ordenar(List<CombinacionEval> combinaciones) {
        if (combinaciones == null || combinaciones.isEmpty()) {
            return new ArrayList<>();
        }
        return criterioActual.ordenar(combinaciones);
    }

    public Map<String, List<CombinacionEval>> agruparRechazadasPorRazon(List<CombinacionEval> combinaciones) {
        if (combinaciones == null) return new LinkedHashMap<>();

        Map<String, List<CombinacionEval>> agrupadas = combinaciones.stream()
                .filter(c -> !c.isCumplePoliticas())
                .collect(Collectors.groupingBy(c -> {
                    String r = c.getRazon();
                    return (r == null || r.isBlank()) ? "Sin razón especificada" : r.trim();
                }));

        return agrupadas.entrySet().stream()
                .sorted((e1, e2) -> Integer.compare(e2.getValue().size(), e1.getValue().size()))
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        Map.Entry::getValue,
                        (a, b) -> a,
                        LinkedHashMap::new
                ));
    }
}