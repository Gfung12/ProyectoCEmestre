package com.cemestre.service.strategy;

import com.cemestre.model.BloqueHorario;
import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class OrdenMenosDias implements CriterioOrdenamiento {

    @Override
    public List<CombinacionEval> ordenar(List<CombinacionEval> combinaciones) {
        List<CombinacionEval> copia = new ArrayList<>(combinaciones);
        copia.sort(Comparator.comparingInt(this::contarDiasUnicos)
                .thenComparingInt(CombinacionEval::getIdCombinacion));
        return copia;
    }

    public int contarDiasUnicos(CombinacionEval combinacion) {
        Set<String> dias = new HashSet<>();
        for (BloqueHorario bloque : combinacion.obtenerTodosLosBloques()) {
            dias.add(bloque.getDia());
        }
        return dias.size();
    }

    @Override
    public String getNombre() {
        return "Menos días en el TEC";
    }
}