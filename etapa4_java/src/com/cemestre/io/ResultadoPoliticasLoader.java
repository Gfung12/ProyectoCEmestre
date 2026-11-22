package com.cemestre.io;

import com.cemestre.io.CatalogoHorarioLoader.InfoGrupoCatalogo;
import com.cemestre.model.BloqueHorario;
import com.cemestre.model.CombinacionEval;
import com.cemestre.model.CursoEval;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

public class ResultadoPoliticasLoader {

    public List<CombinacionEval> cargarYUnificar(Path rutaPoliticasJson,
                                                 Map<String, InfoGrupoCatalogo> catalogoGrupos) throws IOException {
        String contenido = Files.readString(rutaPoliticasJson, StandardCharsets.UTF_8);
        JSONArray arr = new JSONArray(contenido);
        List<CombinacionEval> resultado = new ArrayList<>();

        for (int i = 0; i < arr.length(); i++) {
            JSONObject obj = arr.getJSONObject(i);
            int id = obj.optInt("id_combinacion", i + 1);
            boolean cumple = obj.optBoolean("cumple_politicas", false);
            String razon = obj.optString("razon", "");

            JSONArray cursosJson = obj.optJSONArray("cursos");
            List<CursoEval> cursosEval = new ArrayList<>();

            if (cursosJson != null) {
                for (int j = 0; j < cursosJson.length(); j++) {
                    JSONObject cObj = cursosJson.getJSONObject(j);
                    String codigo = cObj.optString("codigo", "").trim().toUpperCase();
                    int grupo = cObj.optInt("grupo", 0);

                    InfoGrupoCatalogo info = catalogoGrupos != null
                            ? catalogoGrupos.get(CatalogoHorarioLoader.construirClave(codigo, grupo))
                            : null;

                    if (info != null) {
                        cursosEval.add(new CursoEval(
                                info.getCodigoCurso(),
                                info.getNombreCurso(),
                                info.getGrupo(),
                                info.getCreditos(),
                                info.getBloques()
                        ));
                    } else {
                        cursosEval.add(new CursoEval(
                                codigo,
                                codigo,
                                grupo,
                                0,
                                Collections.<BloqueHorario>emptyList()
                        ));
                    }
                }
            }

            resultado.add(new CombinacionEval(id, cumple, razon, cursosEval));
        }
        return resultado;
    }
}