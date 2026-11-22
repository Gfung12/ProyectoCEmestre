package com.cemestre.model;

import java.util.Collections;
import java.util.List;

public class BloqueHorario extends ElementoHorario {
    private final String dia;
    private final int horaInicioMin;
    private final int horaFinMin;

    public BloqueHorario(String dia, int horaInicioMin, int horaFinMin) {
        super(
                dia == null ? "BLOQUE" : "BLOQUE_" + dia.trim().toUpperCase(),
                formatearMinutos(horaInicioMin) + " - " + formatearMinutos(horaFinMin)
        );
        if (dia == null || dia.isBlank()) {
            throw new IllegalArgumentException("El día del bloque horario no puede ser nulo o vacío.");
        }
        if (horaInicioMin < 0 || horaFinMin < horaInicioMin) {
            throw new IllegalArgumentException("Rango de minutos inválido: " + horaInicioMin + " a " + horaFinMin);
        }
        this.dia = dia.trim().toUpperCase();
        this.horaInicioMin = horaInicioMin;
        this.horaFinMin = horaFinMin;
    }

    public BloqueHorario(String dia, String horaInicio, String horaFin) {
        this(dia, convertirAMinutos(horaInicio), convertirAMinutos(horaFin));
    }

    private static int convertirAMinutos(String hhmm) {
        if (hhmm == null || !hhmm.trim().contains(":")) {
            throw new IllegalArgumentException("Formato de hora inválido (esperado HH:MM): " + hhmm);
        }
        String[] partes = hhmm.trim().split(":");
        return Integer.parseInt(partes[0].trim()) * 60 + Integer.parseInt(partes[1].trim());
    }

    public static String formatearMinutos(int minutos) {
        int h = minutos / 60;
        int m = minutos % 60;
        return String.format("%02d:%02d", h, m);
    }

    public String getDia() {
        return dia;
    }

    public int getHoraInicioMin() {
        return horaInicioMin;
    }

    public int getHoraFinMin() {
        return horaFinMin;
    }

    public String getRangoFormateado() {
        return formatearMinutos(horaInicioMin) + " - " + formatearMinutos(horaFinMin);
    }

    @Override
    public int getCreditosAportados() {
        return 0;
    }

    @Override
    public List<BloqueHorario> getBloquesAsociados() {
        return Collections.singletonList(this);
    }

    @Override
    public String resumenPolimorfico() {
        return "[Bloque] " + dia + " " + getRangoFormateado() + " (" + horaInicioMin + "-" + horaFinMin + " min)";
    }
}