package com.cemestre.ui;

import javax.swing.SwingUtilities;
import javax.swing.UIManager;

public class AppMain {

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception ignored) {
                // Usa el LookAndFeel por defecto si el del sistema no está disponible
            }
            VentanaPrincipalUI ventana = new VentanaPrincipalUI();
            ventana.setVisible(true);
        });
    }
}