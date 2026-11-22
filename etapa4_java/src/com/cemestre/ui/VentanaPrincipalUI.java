package com.cemestre.ui;

import com.cemestre.io.CatalogoHorarioLoader;
import com.cemestre.io.CatalogoHorarioLoader.InfoGrupoCatalogo;
import com.cemestre.io.ResultadoPoliticasLoader;
import com.cemestre.model.BloqueHorario;
import com.cemestre.model.CombinacionEval;
import com.cemestre.model.CursoEval;
import com.cemestre.service.FiltroService;
import com.cemestre.service.OrdenamientoService;
import com.cemestre.service.filter.FiltroCodigoCurso;
import com.cemestre.service.filter.FiltroCombinacion;
import com.cemestre.service.filter.FiltroEstadoPoliticas;
import com.cemestre.service.strategy.TipoCriterio;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.io.File;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class VentanaPrincipalUI extends JFrame {

    private static final List<String> DIAS_SEMANA = List.of(
            "LUNES", "MARTES", "MIERCOLES", "JUEVES", "VIERNES", "SABADO"
    );

    private final CatalogoHorarioLoader catalogoLoader = new CatalogoHorarioLoader();
    private final ResultadoPoliticasLoader politicasLoader = new ResultadoPoliticasLoader();
    private final FiltroService filtroService = new FiltroService();
    private final OrdenamientoService ordenamientoService = new OrdenamientoService(TipoCriterio.MENOS_HUECOS);

    private List<CombinacionEval> combinacionesOriginales = new ArrayList<>();
    private List<CombinacionEval> combinacionesMostradas = new ArrayList<>();

    private Path rutaCatalogoActual;
    private Path rutaPoliticasActual;

    private JComboBox<TipoCriterio> comboCriterio;
    private JComboBox<String> comboEstado;
    private JTextField txtFiltroCodigo;
    private JLabel lblResumenComb;
    private JLabel lblRazonEstado;
    private JLabel lblArchivosCargados;

    private DefaultTableModel modeloTablaCombinaciones;
    private JTable tablaCombinaciones;
    private JPanel panelHorarioSemanal;

    public VentanaPrincipalUI() {
        super("CEmestre - Constructor de Horarios (Etapa 4)");
        inicializarComponentes();
        intentarCargaInicialAutomatica();
    }

    private void inicializarComponentes() {
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1280, 780);
        setMinimumSize(new Dimension(1024, 650));
        setLocationRelativeTo(null);
        setLayout(new BorderLayout(10, 10));

        JPanel contenedorPrincipal = new JPanel(new BorderLayout(10, 10));
        contenedorPrincipal.setBorder(new EmptyBorder(10, 10, 10, 10));
        setContentPane(contenedorPrincipal);

        contenedorPrincipal.add(crearPanelSuperior(), BorderLayout.NORTH);
        contenedorPrincipal.add(crearPanelCentralDividido(), BorderLayout.CENTER);
        contenedorPrincipal.add(crearPanelInferiorEstado(), BorderLayout.SOUTH);
    }

    private JPanel crearPanelSuperior() {
        JPanel panelTop = new JPanel(new BorderLayout(8, 8));

        JPanel filaArchivosYOrden = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 4));
        JButton btnCargarPoliticas = new JButton("Cargar resultado_politicas.json");
        JButton btnCargarCatalogo = new JButton("Cargar output_schedule.json");
        JButton btnRecargar = new JButton("Recargar");

        btnCargarPoliticas.addActionListener(e -> seleccionarArchivoPoliticas());
        btnCargarCatalogo.addActionListener(e -> seleccionarArchivoCatalogo());
        btnRecargar.addActionListener(e -> cargarDatos(rutaPoliticasActual, rutaCatalogoActual));

        comboCriterio = new JComboBox<>(TipoCriterio.values());
        comboCriterio.setSelectedItem(TipoCriterio.MENOS_HUECOS);
        comboCriterio.addActionListener(e -> aplicarOrdenYFiltros());

        filaArchivosYOrden.add(btnCargarPoliticas);
        filaArchivosYOrden.add(btnCargarCatalogo);
        filaArchivosYOrden.add(btnRecargar);
        filaArchivosYOrden.add(new JSeparator(SwingConstants.VERTICAL));
        filaArchivosYOrden.add(new JLabel("Ordenar por:"));
        filaArchivosYOrden.add(comboCriterio);

        JPanel filaFiltros = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 4));
        comboEstado = new JComboBox<>(new String[]{"TODAS", "VALIDAS", "RECHAZADAS"});
        comboEstado.addActionListener(e -> aplicarOrdenYFiltros());

        txtFiltroCodigo = new JTextField(10);
        txtFiltroCodigo.setToolTipText("Ej: CE1107");
        JButton btnBuscar = new JButton("Filtrar");
        JButton btnLimpiar = new JButton("Limpiar");

        btnBuscar.addActionListener(e -> aplicarOrdenYFiltros());
        txtFiltroCodigo.addActionListener(e -> aplicarOrdenYFiltros());
        btnLimpiar.addActionListener(e -> {
            comboEstado.setSelectedItem("TODAS");
            txtFiltroCodigo.setText("");
            aplicarOrdenYFiltros();
        });

        filaFiltros.add(new JLabel("Estado:"));
        filaFiltros.add(comboEstado);
        filaFiltros.add(new JLabel("Código curso:"));
        filaFiltros.add(txtFiltroCodigo);
        filaFiltros.add(btnBuscar);
        filaFiltros.add(btnLimpiar);

        panelTop.add(filaArchivosYOrden, BorderLayout.NORTH);
        panelTop.add(filaFiltros, BorderLayout.SOUTH);
        return panelTop;
    }

    private JSplitPane crearPanelCentralDividido() {
        String[] columnas = {"ID", "Estado", "Créditos", "Razón / Detalle"};
        modeloTablaCombinaciones = new DefaultTableModel(columnas, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        tablaCombinaciones = new JTable(modeloTablaCombinaciones);
        tablaCombinaciones.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tablaCombinaciones.setRowHeight(26);
        tablaCombinaciones.getColumnModel().getColumn(0).setMaxWidth(55);
        tablaCombinaciones.getColumnModel().getColumn(1).setMaxWidth(95);
        tablaCombinaciones.getColumnModel().getColumn(2).setMaxWidth(75);

        tablaCombinaciones.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                                                           boolean isSelected, boolean hasFocus,
                                                           int row, int column) {
                Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                if (!isSelected && row >= 0 && row < combinacionesMostradas.size()) {
                    CombinacionEval comb = combinacionesMostradas.get(row);
                    if (comb.isCumplePoliticas()) {
                        c.setBackground(new Color(232, 248, 238));
                        c.setForeground(new Color(20, 70, 35));
                    } else {
                        c.setBackground(new Color(253, 235, 235));
                        c.setForeground(new Color(120, 25, 25));
                    }
                } else if (isSelected) {
                    c.setBackground(table.getSelectionBackground());
                    c.setForeground(table.getSelectionForeground());
                }
                return c;
            }
        });

        tablaCombinaciones.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                actualizarVistaSeleccionada();
            }
        });

        JScrollPane scrollTabla = new JScrollPane(tablaCombinaciones);
        scrollTabla.setBorder(BorderFactory.createTitledBorder("Combinaciones evaluadas"));
        scrollTabla.setPreferredSize(new Dimension(370, 500));

        JPanel panelDerecho = new JPanel(new BorderLayout(6, 6));
        panelDerecho.setBorder(BorderFactory.createTitledBorder("Horario semanal de la combinación elegida"));

        JPanel cabeceraHorario = new JPanel(new BorderLayout(6, 4));
        lblResumenComb = new JLabel("Selecciona una combinación para ver su horario.");
        lblResumenComb.setFont(lblResumenComb.getFont().deriveFont(Font.BOLD, 13f));
        lblRazonEstado = new JLabel(" ");
        cabeceraHorario.add(lblResumenComb, BorderLayout.NORTH);
        cabeceraHorario.add(lblRazonEstado, BorderLayout.SOUTH);

        panelHorarioSemanal = new JPanel();
        JScrollPane scrollHorario = new JScrollPane(panelHorarioSemanal);

        panelDerecho.add(cabeceraHorario, BorderLayout.NORTH);
        panelDerecho.add(scrollHorario, BorderLayout.CENTER);

        JSplitPane split = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, scrollTabla, panelDerecho);
        split.setDividerLocation(380);
        return split;
    }

    private JPanel crearPanelInferiorEstado() {
        JPanel panelBottom = new JPanel(new BorderLayout());
        panelBottom.setBorder(new EmptyBorder(4, 2, 0, 2));
        lblArchivosCargados = new JLabel("Sin archivos cargados.");
        panelBottom.add(lblArchivosCargados, BorderLayout.WEST);
        return panelBottom;
    }

    private void intentarCargaInicialAutomatica() {
        List<String> candidatosPoliticas = List.of(
                "data/resultado_politicas.json",
                "../data/resultado_politicas.json",
                "D:/ProyectoCEmestre/data/resultado_politicas.json"
        );
        List<String> candidatosCatalogo = List.of(
                "data/output_schedule.json",
                "../data/output_schedule.json",
                "D:/ProyectoCEmestre/data/output_schedule.json"
        );

        Path pol = buscarPrimerArchivoExistente(candidatosPoliticas);
        Path cat = buscarPrimerArchivoExistente(candidatosCatalogo);

        if (pol != null && cat != null) {
            cargarDatos(pol, cat);
        }
    }

    private Path buscarPrimerArchivoExistente(List<String> rutas) {
        for (String r : rutas) {
            File f = new File(r);
            if (f.exists() && f.isFile()) {
                return f.toPath();
            }
        }
        return null;
    }

    private void seleccionarArchivoPoliticas() {
        JFileChooser chooser = new JFileChooser();
        chooser.setDialogTitle("Seleccionar resultado_politicas.json");
        if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            Path elegida = chooser.getSelectedFile().toPath();
            if (rutaCatalogoActual == null) {
                Path catAuto = buscarPrimerArchivoExistente(List.of(
                        elegida.getParent() != null ? elegida.getParent().resolve("output_schedule.json").toString() : "",
                        "data/output_schedule.json",
                        "../data/output_schedule.json"
                ));
                if (catAuto != null) {
                    cargarDatos(elegida, catAuto);
                    return;
                }
            }
            rutaPoliticasActual = elegida;
            if (rutaCatalogoActual != null) {
                cargarDatos(rutaPoliticasActual, rutaCatalogoActual);
            } else {
                lblArchivosCargados.setText("Políticas seleccionadas: " + elegida + " | Falta catálogo output_schedule.json");
            }
        }
    }

    private void seleccionarArchivoCatalogo() {
        JFileChooser chooser = new JFileChooser();
        chooser.setDialogTitle("Seleccionar output_schedule.json");
        if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            Path elegida = chooser.getSelectedFile().toPath();
            rutaCatalogoActual = elegida;
            if (rutaPoliticasActual != null) {
                cargarDatos(rutaPoliticasActual, rutaCatalogoActual);
            } else {
                lblArchivosCargados.setText("Catálogo seleccionado: " + elegida + " | Falta resultado_politicas.json");
            }
        }
    }

    public void cargarDatos(Path rutaPoliticas, Path rutaCatalogo) {
        if (rutaPoliticas == null || rutaCatalogo == null) {
            JOptionPane.showMessageDialog(
                    this,
                    "Debes indicar tanto resultado_politicas.json como output_schedule.json.",
                    "Archivos faltantes",
                    JOptionPane.WARNING_MESSAGE
            );
            return;
        }

        try {
            Map<String, InfoGrupoCatalogo> mapaGrupos = catalogoLoader.cargarMapaGrupos(rutaCatalogo);
            List<CombinacionEval> cargadas = politicasLoader.cargarYUnificar(rutaPoliticas, mapaGrupos);

            this.rutaPoliticasActual = rutaPoliticas;
            this.rutaCatalogoActual = rutaCatalogo;
            this.combinacionesOriginales = new ArrayList<>(cargadas);

            lblArchivosCargados.setText(
                    "Políticas: " + rutaPoliticas.getFileName() +
                            " | Catálogo: " + rutaCatalogo.getFileName() +
                            " | Total combinaciones: " + combinacionesOriginales.size()
            );

            aplicarOrdenYFiltros();
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(
                    this,
                    "Error al cargar o unificar los datos:\n" + ex.getMessage(),
                    "Error de carga",
                    JOptionPane.ERROR_MESSAGE
            );
        }
    }

    private void aplicarOrdenYFiltros() {
        TipoCriterio criterioElegido = (TipoCriterio) comboCriterio.getSelectedItem();
        if (criterioElegido != null) {
            ordenamientoService.setCriterio(criterioElegido);
        }

        FiltroCombinacion filtroActivo = null;

        String estadoSel = (String) comboEstado.getSelectedItem();
        if ("VALIDAS".equals(estadoSel)) {
            filtroActivo = new FiltroEstadoPoliticas(true);
        } else if ("RECHAZADAS".equals(estadoSel)) {
            filtroActivo = new FiltroEstadoPoliticas(false);
        }

        String codigoTexto = txtFiltroCodigo.getText() != null ? txtFiltroCodigo.getText().trim() : "";
        if (!codigoTexto.isEmpty()) {
            FiltroCombinacion filtroCodigo = new FiltroCodigoCurso(codigoTexto);
            filtroActivo = (filtroActivo == null) ? filtroCodigo : filtroActivo.and(filtroCodigo);
        }

        List<CombinacionEval> filtradas = (filtroActivo == null)
                ? new ArrayList<>(combinacionesOriginales)
                : filtroService.filtrar(combinacionesOriginales, filtroActivo);

        this.combinacionesMostradas = ordenamientoService.ordenar(filtradas);
        refrescarTablaCombinaciones();
    }

    private String formatearRazon(CombinacionEval comb) {
        String r = comb.getRazon();
        if (r == null || r.isBlank()) {
            return comb.isCumplePoliticas() ? "Ninguna" : "Sin razón especificada";
        }
        return r.trim();
    }

    private void refrescarTablaCombinaciones() {
        modeloTablaCombinaciones.setRowCount(0);
        for (CombinacionEval c : combinacionesMostradas) {
            String estadoStr = c.isCumplePoliticas() ? "VÁLIDA" : "RECHAZADA";
            modeloTablaCombinaciones.addRow(new Object[]{
                    c.getIdCombinacion(),
                    estadoStr,
                    c.obtenerTotalCreditos(),
                    formatearRazon(c)
            });
        }

        if (!combinacionesMostradas.isEmpty()) {
            tablaCombinaciones.setRowSelectionInterval(0, 0);
            actualizarVistaSeleccionada();
        } else {
            lblResumenComb.setText("No hay combinaciones que coincidan con el filtro.");
            lblRazonEstado.setText(" ");
            renderizarHorarioVacio();
        }
    }

    private void actualizarVistaSeleccionada() {
        int fila = tablaCombinaciones.getSelectedRow();
        if (fila < 0 || fila >= combinacionesMostradas.size()) {
            return;
        }
        CombinacionEval seleccionada = combinacionesMostradas.get(fila);
        String estadoTexto = seleccionada.isCumplePoliticas() ? "VÁLIDA" : "RECHAZADA";

        lblResumenComb.setText(
                "Combinación #" + seleccionada.getIdCombinacion() +
                        "  [" + estadoTexto + "]  —  Total créditos: " + seleccionada.obtenerTotalCreditos()
        );
        lblRazonEstado.setText("Razón: " + formatearRazon(seleccionada));

        renderizarHorarioCombinacion(seleccionada);
    }

    private void renderizarHorarioVacio() {
        panelHorarioSemanal.removeAll();
        panelHorarioSemanal.setLayout(new BorderLayout());
        JLabel vacio = new JLabel("Sin horario para mostrar.", SwingConstants.CENTER);
        panelHorarioSemanal.add(vacio, BorderLayout.CENTER);
        panelHorarioSemanal.revalidate();
        panelHorarioSemanal.repaint();
    }

    private void renderizarHorarioCombinacion(CombinacionEval combinacion) {
        panelHorarioSemanal.removeAll();

        List<AsignacionBloque> asignaciones = new ArrayList<>();
        Map<String, Integer> inicioPorRango = new LinkedHashMap<>();

        for (CursoEval curso : combinacion.getCursos()) {
            for (BloqueHorario bloque : curso.getBloques()) {
                String diaNormalizado = normalizarDia(bloque.getDia());
                if (DIAS_SEMANA.contains(diaNormalizado)) {
                    String rango = bloque.getRangoFormateado();
                    inicioPorRango.putIfAbsent(rango, bloque.getHoraInicioMin());
                    asignaciones.add(new AsignacionBloque(curso, bloque, diaNormalizado, rango));
                }
            }
        }

        if (asignaciones.isEmpty()) {
            renderizarHorarioVacio();
            return;
        }

        List<String> filasHoras = new ArrayList<>(inicioPorRango.keySet());
        filasHoras.sort(Comparator.comparingInt(inicioPorRango::get));

        panelHorarioSemanal.setLayout(new GridLayout(filasHoras.size() + 1, DIAS_SEMANA.size() + 1, 4, 4));
        panelHorarioSemanal.setBorder(new EmptyBorder(6, 6, 6, 6));

        panelHorarioSemanal.add(crearCeldaEncabezado("Hora"));
        for (String dia : DIAS_SEMANA) {
            panelHorarioSemanal.add(crearCeldaEncabezado(dia));
        }

        for (String rango : filasHoras) {
            panelHorarioSemanal.add(crearCeldaEncabezado(rango));

            for (String dia : DIAS_SEMANA) {
                List<AsignacionBloque> enCelda = new ArrayList<>();
                for (AsignacionBloque ab : asignaciones) {
                    if (ab.dia.equals(dia) && ab.rango.equals(rango)) {
                        enCelda.add(ab);
                    }
                }

                if (enCelda.isEmpty()) {
                    JPanel celdaVacia = new JPanel();
                    celdaVacia.setBackground(new Color(248, 249, 250));
                    celdaVacia.setBorder(BorderFactory.createLineBorder(new Color(220, 224, 228)));
                    panelHorarioSemanal.add(celdaVacia);
                } else {
                    StringBuilder html = new StringBuilder("<html><div style='padding:3px;'>");
                    for (AsignacionBloque ab : enCelda) {
                        html.append("<b>").append(escaparHtml(ab.curso.getCodigo())).append("</b> ")
                                .append("(G").append(ab.curso.getGrupo()).append(")<br/>")
                                .append(escaparHtml(ab.curso.getNombre()));
                    }
                    html.append("</div></html>");

                    JPanel celdaCurso = new JPanel(new BorderLayout());
                    celdaCurso.setBackground(new Color(217, 234, 252));
                    celdaCurso.setBorder(BorderFactory.createLineBorder(new Color(90, 145, 210)));

                    JLabel lblCurso = new JLabel(html.toString());
                    lblCurso.setForeground(new Color(18, 42, 74));
                    lblCurso.setFont(lblCurso.getFont().deriveFont(11.5f));
                    celdaCurso.add(lblCurso, BorderLayout.CENTER);
                    panelHorarioSemanal.add(celdaCurso);
                }
            }
        }

        panelHorarioSemanal.revalidate();
        panelHorarioSemanal.repaint();
    }

    private JLabel crearCeldaEncabezado(String texto) {
        JLabel lbl = new JLabel(texto, SwingConstants.CENTER);
        lbl.setOpaque(true);
        lbl.setBackground(new Color(52, 73, 94));
        lbl.setForeground(Color.WHITE);
        lbl.setFont(lbl.getFont().deriveFont(Font.BOLD, 12f));
        lbl.setBorder(BorderFactory.createEmptyBorder(6, 4, 6, 4));
        return lbl;
    }

    private String normalizarDia(String dia) {
        if (dia == null) {
            return "";
        }
        return dia.trim().toUpperCase()
                .replace('Á', 'A')
                .replace('É', 'E')
                .replace('Í', 'I')
                .replace('Ó', 'O')
                .replace('Ú', 'U');
    }

    private String escaparHtml(String texto) {
        if (texto == null) {
            return "";
        }
        return texto.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }

    private record AsignacionBloque(
            CursoEval curso,
            BloqueHorario bloque,
            String dia,
            String rango
    ) { }
}