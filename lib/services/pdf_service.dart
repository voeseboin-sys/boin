import 'dart:typed_data';
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
    required List<Venta> ventas,
    required List<Produccion> produccion,
  }) async {
    final pdf = pw.Document();
    final formatoMoneda = NumberFormat.currency(locale: 'es_PY', symbol: 'Gs', decimalDigits: 0);
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final titulo = "Reporte - ${DateFormat('MMMM yyyy', 'es_ES').format(mes).toUpperCase()}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- ENCABEZADO ---
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('GESTIÓN FÁBRICA', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Reporte Mensual de Operaciones', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(titulo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // --- 1. RESUMEN FINANCIERO ---
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildResumenItem('Ingresos', metricas.ventasTotales, formatoMoneda, PdfColors.green700),
                  _buildResumenItem('Gastos', metricas.gastosTotales, formatoMoneda, PdfColors.red700),
                  _buildResumenItem('Utilidad', metricas.utilidadNeta, formatoMoneda, metricas.utilidadNeta >= 0 ? PdfColors.blue700 : PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // --- 2. DETALLE DE GASTOS ---
            pw.Text("Detalle de Gastos", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            gastos.isEmpty 
              ? pw.Text("No hay gastos registrados.", style: const pw.TextStyle(color: PdfColors.grey))
              : pw.Table.fromTextArray(
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headers: ['Fecha', 'Descripción', 'Tipo', 'Monto'],
                  data: gastos.map((g) => [
                    formatoFecha.format(g.fecha),
                    g.descripcion,
                    g.tipo == TipoGasto.fabrica ? 'Fábrica' : 'Personal',
                    formatoMoneda.format(g.monto),
                  ]).toList(),
                ),
            
            pw.SizedBox(height: 20),

            // --- 3. PRODUCCIÓN ---
            pw.Text("Producción del Mes", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            produccion.isEmpty
              ? pw.Text("No hay registros de producción.", style: const pw.TextStyle(color: PdfColors.grey))
              : pw.Table.fromTextArray(
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headers: ['Fecha', 'Producto', 'Cantidad'],
                  data: produccion.map((p) => [
                    formatoFecha.format(p.fecha),
                    p.nombreProducto, // Asegúrate que tu modelo Produccion tenga este campo o busca el nombre
                    "${p.cantidad} u.",
                  ]).toList(),
                ),

             // --- PIE DE PÁGINA ---
             pw.Spacer(),
             pw.Divider(),
             pw.Row(
               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
               children: [
                 pw.Text("Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                 pw.Text("Gestión Fábrica App", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
               ],
             ),
          ];
        },
      ),
    );

    // Abre el diálogo de impresión/compartir nativo
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${DateFormat('MM_yyyy').format(mes)}.pdf',
    );
  }

  pw.Widget _buildResumenItem(String label, double valor, NumberFormat fmt, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text(fmt.format(valor), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
