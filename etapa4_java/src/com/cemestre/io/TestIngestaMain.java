package com.cemestre.io;

import com.cemestre.io.CatalogoHorarioLoader.InfoGrupoCatalogo;
import com.cemestre.model.BloqueHorario;
import com.cemestre.model.CombinacionEval;
import com.cemestre.model.CursoEval;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

public class TestIngestaMain {

    private static Path resolverRuta(String... candidatos) {
        for (String c : candidatos) {
            Path p = Path.of(c);
            if (Files.exists(p) && Files.isRegularFile(p)) {
                return p;
            }
        }
        return Path.of(candidatos[0]);
    }

    public static void main(String[] args) throws Exception {
        Path rutaCatalogo = resolverRuta(
                "data/output_schedule.json",
                "../data/output_schedule.json",
                "D:/ProyectoCEmestre/data/output_schedule.json"
        );
        Path rutaPoliticas = resolverRuta(
                "data/resultado_politicas.json",
                "../data/resultado_politicas.json",
                "D:/ProyectoCEmestre/data/resultado_politicas.json"
        );

        CatalogoHorarioLoader catalogoLoader = new CatalogoHorarioLoader();
        Map<String, InfoGrupoCatalogo> mapaGrupos = catalogoLoader.cargarMapaGrupos(rutaCatalogo);

        ResultadoPoliticasLoader politicasLoader = new ResultadoPoliticasLoader();
        List<CombinacionEval> combinaciones = politicasLoader.cargarYUnificar(rutaPoliticas, mapaGrupos);

        System.out.println("Grupos indexados desde C: " + mapaGrupos.size());
        System.out.println("Combinaciones cargadas desde Prolog: " + combinaciones.size());

        for (CombinacionEval comb : combinaciones) {
            System.out.println("--------------------------------------------------");
            System.out.println("ID: " + comb.getIdCombinacion()
                    + " | Cumple: " + comb.isCumplePoliticas()
                    + " | Créditos: " + comb.obtenerTotalCreditos()
                    + " | Razón: " + comb.getRazon());
            for (CursoEval curso : comb.getCursos()) {
                System.out.println("  - [" + curso.getCodigo() + "] " + curso.getNombre()
                        + " (Grupo " + curso.getGrupo() + ", " + curso.getCreditos() + " créd.)");
                for (BloqueHorario b : curso.getBloques()) {
                    System.out.println("      * " + b.getDia() + " "
                            + b.getHoraInicioMin() + " - " + b.getHoraFinMin() + " min");
                }
            }
        }
    }
}