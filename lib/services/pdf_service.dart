import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfService {
  
  Future<void> generarReporteMensual({
    required DateTime mes,
    required MetricasDashboard metricas,
    required List<Gasto> gastos,
    required List<Venta> ventas, // Usamos tu modelo Venta (UI)
  }) async {
    final pdf = pw.Document();
    final formatoMoneda = NumberFormat.currency(locale: 'es_PY', symbol: 'Gs', decimalDigits: 0);
    final formatoFecha = DateFormat('dd/MM/yyyy');

    // Título del reporte
    final titulo = "Reporte Mensual - ${DateFormat('MMMM yyyy', 'es_ES').format(mes).toUpperCase()}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // --- CABECERA ---
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GESTIÓN FÁBRICA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(titulo, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // --- RESUMEN FINANCIERO ---
            pw.Text("Resumen Financiero", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Concepto', 'Monto'],
              data: [
                ['Ingresos Totales (Ventas)', formatoMoneda.format(metricas.ventasTotales)],
                ['Gastos Totales', formatoMoneda.format(metricas.gastosTotales)],
                ['Utilidad Neta', formatoMoneda.format(metricas.utilidadNeta)],
                ['Margen de Ganancia', '${metricas.margenContribucion.toStringAsFixed(1)}%'],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            ),
            pw.SizedBox(height: 30),

            // --- DETALLE DE GASTOS ---
            pw.Text("Detalle de Gastos", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            gastos.isEmpty 
              ? pw.Text("No hay gastos registrados este mes.")
              : pw.Table.fromTextArray(
                  headers: ['Fecha', 'Descripción', 'Tipo', 'Monto'],
                  data: gastos.map((g) => [
                    formatoFecha.format(g.fecha),
                    g.descripcion,
                    g.tipo == TipoGasto.fabrica ? 'Fábrica' : 'Personal',
                    formatoMoneda.format(g.monto),
                  ]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
                ),
                
             pw.SizedBox(height: 30),
             
             // --- PIE DE PÁGINA ---
             pw.Divider(),
             pw.Align(
               alignment: pw.Alignment.centerRight,
               child: pw.Text("Reporte generado el ${formatoFecha.format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
             ),
          ];
        },
      ),
    );

    // Muestra la vista previa y permite imprimir/compartir
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${DateFormat('MM_yyyy').format(mes)}.pdf',
    );
  }
}
