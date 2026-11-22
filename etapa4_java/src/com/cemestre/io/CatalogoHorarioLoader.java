package com.cemestre.io;

import com.cemestre.model.BloqueHorario;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CatalogoHorarioLoader {

    public static class InfoGrupoCatalogo {
        private final String codigoCurso;
        private final String nombreCurso;
        private final int grupo;
        private final int creditos;
        private final String carrera;
        private final String area;
        private final List<BloqueHorario> bloques;

        public InfoGrupoCatalogo(String codigoCurso, String nombreCurso, int grupo,
                                 int creditos, String carrera, String area,
                                 List<BloqueHorario> bloques) {
            this.codigoCurso = codigoCurso;
            this.nombreCurso = nombreCurso;
            this.grupo = grupo;
            this.creditos = creditos;
            this.carrera = carrera;
            this.area = area;
            this.bloques = bloques;
        }

        public String getCodigoCurso() { return codigoCurso; }
        public String getNombreCurso() { return nombreCurso; }
        public int getGrupo() { return grupo; }
        public int getCreditos() { return creditos; }
        public String getCarrera() { return carrera; }
        public String getArea() { return area; }
        public List<BloqueHorario> getBloques() { return bloques; }
    }

    public Map<String, InfoGrupoCatalogo> cargarMapaGrupos(Path rutaCatalogoJson) throws IOException {
        String contenido = Files.readString(rutaCatalogoJson, StandardCharsets.UTF_8);
        JSONArray cursosArr = new JSONArray(contenido);
        Map<String, InfoGrupoCatalogo> mapa = new HashMap<>();

        for (int i = 0; i < cursosArr.length(); i++) {
            JSONObject cursoObj = cursosArr.getJSONObject(i);
            String code = cursoObj.optString("code", "").trim().toUpperCase();
            String name = cursoObj.optString("name", code);
            String career = cursoObj.optString("career", "");
            String area = cursoObj.optString("area", "");
            int credits = cursoObj.optInt("credits", 0);

            JSONArray groupsArr = cursoObj.optJSONArray("groups");
            if (groupsArr == null) continue;

            for (int g = 0; g < groupsArr.length(); g++) {
                JSONObject groupObj = groupsArr.getJSONObject(g);
                int groupNumber = groupObj.optInt("group_number", 0);
                List<BloqueHorario> bloques = parsearBloques(groupObj.optJSONArray("schedules"));

                String clave = construirClave(code, groupNumber);
                mapa.put(clave, new InfoGrupoCatalogo(
                        code, name, groupNumber, credits, career, area, bloques
                ));
            }
        }
        return mapa;
    }

    private List<BloqueHorario> parsearBloques(JSONArray schedulesArr) {
        List<BloqueHorario> bloques = new ArrayList<>();
        if (schedulesArr == null) return bloques;

        for (int s = 0; s < schedulesArr.length(); s++) {
            JSONObject sch = schedulesArr.getJSONObject(s);
            int diaNum = sch.optInt("day", 0);
            int startMil = sch.optInt("start_time", 0);
            int endMil = sch.optInt("end_time", 0);

            String diaStr = mapearDia(diaNum);
            int inicioMin = militarAMinutos(startMil);
            int finMin = militarAMinutos(endMil);
            bloques.add(new BloqueHorario(diaStr, inicioMin, finMin));
        }
        return bloques;
    }

    public static String construirClave(String codigoCurso, int grupo) {
        return (codigoCurso == null ? "" : codigoCurso.trim().toUpperCase()) + "#" + grupo;
    }

    private int militarAMinutos(int horaMilitar) {
        int horas = horaMilitar / 100;
        int minutos = horaMilitar % 100;
        return horas * 60 + minutos;
    }

    private String mapearDia(int dia) {
        return switch (dia) {
            case 1 -> "LUNES";
            case 2 -> "MARTES";
            case 3 -> "MIERCOLES";
            case 4 -> "JUEVES";
            case 5 -> "VIERNES";
            case 6 -> "SABADO";
            default -> "DIA_" + dia;
        };
    }
}