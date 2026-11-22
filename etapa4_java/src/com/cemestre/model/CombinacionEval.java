package com.cemestre.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class CombinacionEval {
    private final int idCombinacion;
    private final boolean cumplePoliticas;
    private final String razon;
    private final List<CursoEval> cursos;

    public CombinacionEval(int idCombinacion, boolean cumplePoliticas, String razon, List<CursoEval> cursos) {
        this.idCombinacion = idCombinacion;
        this.cumplePoliticas = cumplePoliticas;
        this.razon = razon == null ? "" : razon;
        this.cursos = cursos == null ? new ArrayList<>() : new ArrayList<>(cursos);
    }

    public int getIdCombinacion() {
        return idCombinacion;
    }

    public boolean isCumplePoliticas() {
        return cumplePoliticas;
    }

    public String getRazon() {
        return razon;
    }

    public List<CursoEval> getCursos() {
        return Collections.unmodifiableList(cursos);
    }

    public List<ElementoHorario> getElementosComoBase() {
        return Collections.unmodifiableList(new ArrayList<>(cursos));
    }

    public List<BloqueHorario> obtenerTodosLosBloques() {
        List<BloqueHorario> todos = new ArrayList<>();
        for (ElementoHorario elemento : getElementosComoBase()) {
            todos.addAll(elemento.getBloquesAsociados());
        }
        return todos;
    }

    public int obtenerTotalCreditos() {
        int total = 0;
        for (ElementoHorario elemento : getElementosComoBase()) {
            total += elemento.getCreditosAportados();
        }
        return total;
    }
}