package com.cemestre.service.strategy;

import com.cemestre.model.CombinacionEval;
import java.util.List;

public interface CriterioOrdenamiento {
    List<CombinacionEval> ordenar(List<CombinacionEval> combinaciones);
    String getNombre();
}