package com.cemestre.model;

import java.util.List;

public abstract class ElementoHorario {
    private final String codigo;
    private final String descripcion;

    protected ElementoHorario(String codigo, String descripcion) {
        this.codigo = codigo == null ? "" : codigo.trim().toUpperCase();
        this.descripcion = descripcion == null ? "" : descripcion.trim();
    }

    public String getCodigo() {
        return codigo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public abstract int getCreditosAportados();

    public abstract List<BloqueHorario> getBloquesAsociados();

    public abstract String resumenPolimorfico();
}