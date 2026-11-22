package com.cemestre.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class CursoEval extends ElementoHorario {
    private final String nombre;
    private final int grupo;
    private final int creditos;
    private final List<BloqueHorario> bloques;

    public CursoEval(String codigo, String nombre, int grupo, int creditos, List<BloqueHorario> bloques) {
        super(codigo, nombre);
        if (creditos < 0) {
            throw new IllegalArgumentException("Los créditos no pueden ser negativos: " + creditos);
        }
        this.nombre = (nombre == null || nombre.isBlank()) ? getCodigo() : nombre.trim();
        this.grupo = grupo;
        this.creditos = creditos;
        this.bloques = bloques == null ? new ArrayList<>() : new ArrayList<>(bloques);
    }

    public String getNombre() {
        return nombre;
    }

    public int getGrupo() {
        return grupo;
    }

    public int getCreditos() {
        return creditos;
    }

    public List<BloqueHorario> getBloques() {
        return Collections.unmodifiableList(bloques);
    }

    public List<ElementoHorario> getElementosHorario() {
        return Collections.unmodifiableList(new ArrayList<>(bloques));
    }

    @Override
    public int getCreditosAportados() {
        return creditos;
    }

    @Override
    public List<BloqueHorario> getBloquesAsociados() {
        return Collections.unmodifiableList(bloques);
    }

    @Override
    public String resumenPolimorfico() {
        return "[Curso] [" + getCodigo() + "] " + nombre + " (Grupo " + grupo + ", " + creditos + " créd.)";
    }
}