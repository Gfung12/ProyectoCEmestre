package com.cemestre.service.strategy;

import com.cemestre.model.BloqueHorario;
import com.cemestre.model.CombinacionEval;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class OrdenMenosHuecos implements CriterioOrdenamiento {

    @Override
    public List<CombinacionEval> ordenar(List<CombinacionEval> combinaciones) {
        List<CombinacionEval> copia = new ArrayList<>(combinaciones);
        copia.sort(Comparator.comparingInt(this::calcularTotalHuecosMin)
                .thenComparingInt(CombinacionEval::getIdCombinacion));
        return copia;
    }

    public int calcularTotalHuecosMin(CombinacionEval combinacion) {
        Map<String, List<BloqueHorario>> porDia = new HashMap<>();
        for (BloqueHorario bloque : combinacion.obtenerTodosLosBloques()) {
            String diaNormalizado = normalizarDia(bloque.getDia());
            porDia.computeIfAbsent(diaNormalizado, k -> new ArrayList<>()).add(bloque);
        }

        int huecosTotales = 0;
        for (List<BloqueHorario> bloquesDia : porDia.values()) {
            bloquesDia.sort(Comparator.comparingInt(BloqueHorario::getHoraInicioMin));
            for (int i = 0; i < bloquesDia.size() - 1; i++) {
                int finActual = bloquesDia.get(i).getHoraFinMin();
                int inicioSiguiente = bloquesDia.get(i + 1).getHoraInicioMin();
                if (inicioSiguiente > finActual) {
                    huecosTotales += (inicioSiguiente - finActual);
                }
            }
        }
        return huecosTotales;
    }

    private String normalizarDia(String dia) {
        if (dia == null) {
            return "";
        }
        return dia.trim().toUpperCase()
                .replace('Á', 'A')
                .replace('É', 'E')
                .replace('Í', 'I')
                .replace('Ó', 'O')
                .replace('Ú', 'U');
    }

    @Override
    public String getNombre() {
        return "Menos huecos";
    }
}