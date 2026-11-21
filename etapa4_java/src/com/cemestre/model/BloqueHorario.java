package com.cemestre.model;

public class BloqueHorario {
    private final String dia;
    private final int horaInicioMin;
    private final int horaFinMin;

    public BloqueHorario(String dia, int horaInicioMin, int horaFinMin) {
        this.dia = dia.trim().toUpperCase();
        this.horaInicioMin = horaInicioMin;
        this.horaFinMin = horaFinMin;
    }

    public BloqueHorario(String dia, String horaInicio, String horaFin) {
        this(dia, convertirAMinutos(horaInicio), convertirAMinutos(horaFin));
    }

    private static int convertirAMinutos(String hhmm) {
        String[] partes = hhmm.trim().split(":");
        return Integer.parseInt(partes[0]) * 60 + Integer.parseInt(partes[1]);
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
}