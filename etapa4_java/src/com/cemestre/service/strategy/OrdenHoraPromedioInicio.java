package com.cemestre.service.strategy;

import com.cemestre.model.BloqueHorario;
import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class OrdenHoraPromedioInicio implements CriterioOrdenamiento {

    @Override
    public List<CombinacionEval> ordenar(List<CombinacionEval> combinaciones) {
        List<CombinacionEval> copia = new ArrayList<>(combinaciones);
        copia.sort(Comparator.comparingDouble(this::calcularPromedioInicio)
                .thenComparingInt(CombinacionEval::getIdCombinacion));
        return copia;
    }

    public double calcularPromedioInicio(CombinacionEval combinacion) {
        List<BloqueHorario> bloques = combinacion.obtenerTodosLosBloques();
        if (bloques.isEmpty()) return Double.MAX_VALUE;

        double suma = 0;
        for (BloqueHorario bloque : bloques) {
            suma += bloque.getHoraInicioMin();
        }
        return suma / bloques.size();
    }

    @Override
    public String getNombre() {
        return "Hora promedio de inicio (menor a mayor)";
    }
}