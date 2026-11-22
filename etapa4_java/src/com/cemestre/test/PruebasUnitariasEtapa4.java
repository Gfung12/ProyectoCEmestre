package com.cemestre.test;

import com.cemestre.io.CatalogoHorarioLoader;
import com.cemestre.io.CatalogoHorarioLoader.InfoGrupoCatalogo;
import com.cemestre.io.ResultadoPoliticasLoader;
import com.cemestre.model.BloqueHorario;
import com.cemestre.model.CombinacionEval;
import com.cemestre.model.CursoEval;
import com.cemestre.model.ElementoHorario;
import com.cemestre.service.BusquedaService;
import com.cemestre.service.FiltroService;
import com.cemestre.service.OrdenamientoService;
import com.cemestre.service.factory.CriterioOrdenamientoFactory;
import com.cemestre.service.filter.FiltroCodigoCurso;
import com.cemestre.service.filter.FiltroCombinacion;
import com.cemestre.service.filter.FiltroEstadoPoliticas;
import com.cemestre.service.filter.FiltroMinimoCreditos;
import com.cemestre.service.strategy.CriterioOrdenamiento;
import com.cemestre.service.strategy.OrdenHoraPromedioInicio;
import com.cemestre.service.strategy.OrdenMayorCreditos;
import com.cemestre.service.strategy.OrdenMenosDias;
import com.cemestre.service.strategy.OrdenMenosHuecos;
import com.cemestre.service.strategy.TipoCriterio;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public class PruebasUnitariasEtapa4 {

    private static int pasadas = 0;
    private static int fallidas = 0;

    public static void main(String[] args) throws Exception {
        probarCargaYUnificacionConArchivosTemporales();
        probarCursoNoEncontradoEnCatalogo();
        probarOrdenMayorCreditos();
        probarOrdenHoraPromedioInicio();
        probarOrdenMenosHuecos();
        probarOrdenMenosDias();
        probarBusquedaService();
        probarFactoryCriterioNulo();
        probarJerarquiaPolimorfica();
        probarFiltrosCompuestos();
        probarAgrupacionRechazadasYCasosBorde();

        System.out.println("\n==========================================");
        System.out.println("Resumen pruebas -> Pasadas: " + pasadas + " | Fallidas: " + fallidas);
        if (fallidas > 0) {
            System.exit(1);
        }
    }

    private static void probarCargaYUnificacionConArchivosTemporales() throws Exception {
        String jsonCatalogo = """
                [
                  {
                    "code": "CE1107",
                    "name": "Fundamentos De Arquitectura De Computadores",
                    "credits": 4,
                    "career": "Ingeniería en Computadores",
                    "area": "Computadores",
                    "groups": [
                      {
                        "group_number": 1,
                        "schedules": [
                          { "day": 2, "start_time": 1300, "end_time": 1450 }
                        ]
                      }
                    ]
                  },
                  {
                    "code": "MA1102",
                    "name": "Cálculo Diferencial E Integral",
                    "credits": 4,
                    "career": "Ingeniería en Computadores",
                    "area": "Matemáticas",
                    "groups": [
                      {
                        "group_number": 1,
                        "schedules": [
                          { "day": 1, "start_time": 1300, "end_time": 1650 }
                        ]
                      }
                    ]
                  }
                ]
                """;

        String jsonPoliticas = """
                [
                  {
                    "id_combinacion": 10,
                    "cumple_politicas": true,
                    "razon": "Ninguna",
                    "cursos": [
                      { "codigo": "ce1107", "grupo": 1 },
                      { "codigo": "MA1102", "grupo": 1 }
                    ]
                  }
                ]
                """;

        Path tmpCatalogo = Files.createTempFile("catalogo_test_", ".json");
        Path tmpPoliticas = Files.createTempFile("politicas_test_", ".json");

        try {
            Files.writeString(tmpCatalogo, jsonCatalogo);
            Files.writeString(tmpPoliticas, jsonPoliticas);

            CatalogoHorarioLoader catLoader = new CatalogoHorarioLoader();
            Map<String, InfoGrupoCatalogo> mapa = catLoader.cargarMapaGrupos(tmpCatalogo);

            assertTrue("Debe indexar 2 grupos", mapa.size() == 2);
            assertTrue("Clave CE1107#1 debe existir", mapa.containsKey("CE1107#1"));
            assertTrue("MARTES 13:00 - 14:50 debe parsearse a 780 - 890 min",
                    mapa.get("CE1107#1").getBloques().get(0).getDia().equals("MARTES")
                            && mapa.get("CE1107#1").getBloques().get(0).getHoraInicioMin() == 780
                            && mapa.get("CE1107#1").getBloques().get(0).getHoraFinMin() == 890);

            ResultadoPoliticasLoader polLoader = new ResultadoPoliticasLoader();
            List<CombinacionEval> combinaciones = polLoader.cargarYUnificar(tmpPoliticas, mapa);

            assertTrue("Debe cargar 1 combinación", combinaciones.size() == 1);
            CombinacionEval comb = combinaciones.get(0);
            assertTrue("Debe tener 8 créditos unificados", comb.obtenerTotalCreditos() == 8);
            assertTrue("Debe tener 2 bloques horarios", comb.obtenerTodosLosBloques().size() == 2);
        } finally {
            Files.deleteIfExists(tmpCatalogo);
            Files.deleteIfExists(tmpPoliticas);
        }
    }

    private static void probarCursoNoEncontradoEnCatalogo() throws Exception {
        String jsonPoliticas = """
                [
                  {
                    "id_combinacion": 99,
                    "cumple_politicas": false,
                    "razon": "Grupo inexistente",
                    "cursos": [
                      { "codigo": "XX9999", "grupo": 5 }
                    ]
                  }
                ]
                """;

        Path tmpPoliticas = Files.createTempFile("politicas_faltante_", ".json");
        try {
            Files.writeString(tmpPoliticas, jsonPoliticas);
            ResultadoPoliticasLoader loader = new ResultadoPoliticasLoader();
            List<CombinacionEval> res = loader.cargarYUnificar(tmpPoliticas, Map.of());

            assertTrue("Debe crear combinación aunque el grupo no esté en catálogo", res.size() == 1);
            assertTrue("Curso faltante debe tener 0 créditos y 0 bloques",
                    res.get(0).obtenerTotalCreditos() == 0 && res.get(0).obtenerTodosLosBloques().isEmpty());
        } finally {
            Files.deleteIfExists(tmpPoliticas);
        }
    }

    private static void probarOrdenMayorCreditos() {
        CombinacionEval cMenor = crearCombinacion(1, "A", 1, 4, "LUNES", 480, 540);
        CombinacionEval cMayor = crearCombinacion(2, "B", 1, 8, "MARTES", 480, 540);

        CriterioOrdenamiento estrategia = CriterioOrdenamientoFactory.crearCriterio(TipoCriterio.MAYOR_CREDITOS);
        assertTrue("Factory debe retornar OrdenMayorCreditos", estrategia instanceof OrdenMayorCreditos);

        List<CombinacionEval> ordenadas = estrategia.ordenar(List.of(cMenor, cMayor));
        assertTrue("Primero debe ir la de mayor créditos (ID 2)", ordenadas.get(0).getIdCombinacion() == 2);
    }

    private static void probarOrdenHoraPromedioInicio() {
        CombinacionEval cTarde = crearCombinacion(1, "A", 1, 4, "LUNES", 720, 800);
        CombinacionEval cTemprano = crearCombinacion(2, "B", 1, 4, "LUNES", 450, 530);

        CriterioOrdenamiento estrategia = CriterioOrdenamientoFactory.crearCriterio(TipoCriterio.HORA_PROMEDIO_INICIO);
        assertTrue("Factory debe retornar OrdenHoraPromedioInicio", estrategia instanceof OrdenHoraPromedioInicio);

        List<CombinacionEval> ordenadas = estrategia.ordenar(List.of(cTarde, cTemprano));
        assertTrue("Primero debe ir la que inicia más temprano (ID 2)", ordenadas.get(0).getIdCombinacion() == 2);
    }

    private static void probarOrdenMenosHuecos() {
        CombinacionEval cConHueco = new CombinacionEval(1, true, "Ninguna", List.of(
                new CursoEval("C1", "Curso 1", 1, 3, List.of(
                        new BloqueHorario("LUNES", 480, 600),
                        new BloqueHorario("LUNES", 720, 800)
                ))
        ));

        CombinacionEval cSinHueco = new CombinacionEval(2, true, "Ninguna", List.of(
                new CursoEval("C2", "Curso 2", 1, 3, List.of(
                        new BloqueHorario("LUNES", 480, 540),
                        new BloqueHorario("LUNES", 540, 600)
                ))
        ));

        CriterioOrdenamiento estrategia = CriterioOrdenamientoFactory.crearCriterio(TipoCriterio.MENOS_HUECOS);
        assertTrue("Factory debe retornar OrdenMenosHuecos", estrategia instanceof OrdenMenosHuecos);

        List<CombinacionEval> ordenadas = estrategia.ordenar(List.of(cConHueco, cSinHueco));
        assertTrue("Primero debe ir la combinación sin huecos (ID 2)", ordenadas.get(0).getIdCombinacion() == 2);
    }

    private static void probarOrdenMenosDias() {
        CombinacionEval cTresDias = new CombinacionEval(1, true, "Ninguna", List.of(
                new CursoEval("C1", "Curso 1", 1, 4, List.of(
                        new BloqueHorario("LUNES", 450, 680),
                        new BloqueHorario("MIERCOLES", 450, 680),
                        new BloqueHorario("VIERNES", 450, 680)
                ))
        ));

        CombinacionEval cUnDia = new CombinacionEval(2, true, "Ninguna", List.of(
                new CursoEval("C2", "Curso 2", 1, 4, List.of(
                        new BloqueHorario("MARTES", 780, 1010)
                ))
        ));

        CriterioOrdenamiento estrategia = CriterioOrdenamientoFactory.crearCriterio(TipoCriterio.MENOS_DIAS);
        assertTrue("Factory debe retornar OrdenMenosDias", estrategia instanceof OrdenMenosDias);

        List<CombinacionEval> ordenadas = estrategia.ordenar(List.of(cTresDias, cUnDia));
        assertTrue("Primero debe ir la combinación con menos días (ID 2)", ordenadas.get(0).getIdCombinacion() == 2);
    }

    private static void probarBusquedaService() {
        CombinacionEval c1 = new CombinacionEval(1, false, "Cursos incompatibles: CE1107 y CE1105", List.of(
                new CursoEval("CE1107", "Arquitectura", 1, 4, List.of(new BloqueHorario("MARTES", 780, 890))),
                new CursoEval("CE1105", "Modelado", 1, 3, List.of(new BloqueHorario("MARTES", 450, 680)))
        ));
        CombinacionEval c2 = new CombinacionEval(2, true, "Ninguna", List.of(
                new CursoEval("MA1102", "Cálculo", 1, 4, List.of(new BloqueHorario("LUNES", 780, 1010))),
                new CursoEval("CS1502", "Intro", 1, 1, List.of(new BloqueHorario("JUEVES", 450, 560)))
        ));

        BusquedaService busqueda = new BusquedaService();
        List<CombinacionEval> lista = List.of(c1, c2);

        assertTrue("Buscar por código ce1107 debe devolver ID 1",
                busqueda.buscarPorCodigoCurso(lista, "ce1107").size() == 1
                        && busqueda.buscarPorCodigoCurso(lista, "ce1107").get(0).getIdCombinacion() == 1);
        assertTrue("Buscar aprobadas debe devolver ID 2",
                busqueda.buscarPorEstado(lista, true).size() == 1
                        && busqueda.buscarPorEstado(lista, true).get(0).getIdCombinacion() == 2);
        assertTrue("Buscar código CE1107 y estado true debe ser vacío",
                busqueda.buscarPorCodigoYEstado(lista, "CE1107", true).isEmpty());

        Optional<CombinacionEval> encontrada = busqueda.buscarPorId(lista, 2);
        assertTrue("Buscar por ID 2 debe encontrar combinación", encontrada.isPresent() && encontrada.get().getIdCombinacion() == 2);
        assertTrue("Buscar por ID 99 debe retornar Optional.empty", busqueda.buscarPorId(lista, 99).isEmpty());
    }

    private static void probarFactoryCriterioNulo() {
        boolean lanzoExcepcion = false;
        try {
            CriterioOrdenamientoFactory.crearCriterio(null);
        } catch (IllegalArgumentException ex) {
            lanzoExcepcion = true;
        }
        assertTrue("crearCriterio(null) debe lanzar IllegalArgumentException", lanzoExcepcion);
    }

    private static void probarJerarquiaPolimorfica() {
        BloqueHorario bloque = new BloqueHorario("MARTES", 780, 890);
        assertTrue("Bloque formateado debe ser 13:00 - 14:50", "13:00 - 14:50".equals(bloque.getRangoFormateado()));
        assertTrue("Bloque aporta 0 créditos", bloque.getCreditosAportados() == 0);

        ElementoHorario elemCurso = new CursoEval("CE1107", "Arquitectura", 1, 4, List.of(bloque));
        assertTrue("Curso polimórfico aporta 4 créditos", elemCurso.getCreditosAportados() == 4);
        assertTrue("Curso polimórfico expone 1 bloque", elemCurso.getBloquesAsociados().size() == 1);
        assertTrue("Resumen polimórfico no debe ser vacío", !elemCurso.resumenPolimorfico().isBlank());
    }

    private static void probarFiltrosCompuestos() {
        CombinacionEval c1 = new CombinacionEval(1, true, "Ninguna", List.of(
                new CursoEval("CE1107", "Arquitectura", 1, 4, List.of(new BloqueHorario("MARTES", 780, 890))),
                new CursoEval("MA1102", "Cálculo", 1, 4, List.of(new BloqueHorario("LUNES", 780, 1010)))
        ));
        CombinacionEval c2 = new CombinacionEval(2, false, "Conflicto", List.of(
                new CursoEval("CE1107", "Arquitectura", 1, 4, List.of(new BloqueHorario("MARTES", 780, 890)))
        ));
        CombinacionEval c3 = new CombinacionEval(3, true, "Ninguna", List.of(
                new CursoEval("CS1502", "Intro", 1, 1, List.of(new BloqueHorario("JUEVES", 450, 560)))
        ));

        FiltroService filtroService = new FiltroService();
        FiltroCombinacion filtroAnd = new FiltroEstadoPoliticas(true)
                .and(new FiltroCodigoCurso("ce1107"))
                .and(new FiltroMinimoCreditos(8));

        List<CombinacionEval> resultadoAnd = filtroService.filtrar(List.of(c1, c2, c3), filtroAnd);
        assertTrue("Filtro AND debe devolver solo ID 1", resultadoAnd.size() == 1 && resultadoAnd.get(0).getIdCombinacion() == 1);

        FiltroCombinacion filtroOr = new FiltroCodigoCurso("MA1102").or(new FiltroCodigoCurso("CS1502"));
        List<CombinacionEval> resultadoOr = filtroService.filtrar(List.of(c1, c2, c3), filtroOr);
        assertTrue("Filtro OR debe devolver 2 combinaciones (ID 1 y ID 3)", resultadoOr.size() == 2);
    }

    private static void probarAgrupacionRechazadasYCasosBorde() {
        CombinacionEval r1 = new CombinacionEval(1, false, "Choque de horario", List.of());
        CombinacionEval r2 = new CombinacionEval(2, false, "Choque de horario", List.of());
        CombinacionEval r3 = new CombinacionEval(3, false, "", List.of());
        CombinacionEval v1 = new CombinacionEval(4, true, "Ninguna", List.of());

        OrdenamientoService ordenService = new OrdenamientoService(TipoCriterio.MENOS_DIAS);
        Map<String, List<CombinacionEval>> grupos = ordenService.agruparRechazadasPorRazon(List.of(r1, r2, r3, v1));

        assertTrue("Debe agrupar en 2 razones de rechazo", grupos.size() == 2);
        assertTrue("La razón más frecuente debe tener 2 elementos", grupos.get("Choque de horario").size() == 2);
        assertTrue("Razón vacía debe mapearse a 'Sin razón especificada'", grupos.containsKey("Sin razón especificada"));

        FiltroService filtroService = new FiltroService();
        assertTrue("FiltroService con filtro nulo debe retornar lista vacía",
                filtroService.filtrar(List.of(v1), null).isEmpty());
    }

    private static CombinacionEval crearCombinacion(int id, String codigo, int grupo, int creditos,
                                                      String dia, int inicio, int fin) {
        CursoEval curso = new CursoEval(
                codigo,
                "Curso " + codigo,
                grupo,
                creditos,
                List.of(new BloqueHorario(dia, inicio, fin))
        );
        return new CombinacionEval(id, true, "Ninguna", List.of(curso));
    }

    private static void assertTrue(String mensaje, boolean condicion) {
        if (condicion) {
            pasadas++;
            System.out.println("[OK]   " + mensaje);
        } else {
            fallidas++;
            System.err.println("[FAIL] " + mensaje);
        }
    }
}