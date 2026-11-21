package com.cemestre.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class CursoEval {
    private final String codigo;
    private final String nombre;
    private final int grupo;
    private final int creditos;
    private final List<BloqueHorario> bloques;

    public CursoEval(String codigo, String nombre, int grupo, int creditos, List<BloqueHorario> bloques) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.grupo = grupo;
        this.creditos = creditos;
        this.bloques = bloques == null ? new ArrayList<>() : new ArrayList<>(bloques);
    }

    public String getCodigo() {
        return codigo;
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
}