import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';
import 'database.dart';

class PdfService {
  final AppDatabase _db;

  PdfService(this._db);

  Future<void> generarExtractoMensual(DateTime mes) async {
    final pdf = pw.Document();
    
    // Obtener datos
    final metricas = await _db.getMetricasDashboard(mes);
    final ventas = await _db.getVentasByMes(mes);
    final produccion = await _db.getProduccionByMes(mes);
    final gastos = await _db.getGastosByMes(mes);
    
    // Colores del tema
    final colorPrimario = PdfColor.fromHex('2ecc71');
    final colorSecundario = PdfColor.fromHex('27ae60');
    final colorTexto = PdfColor.fromHex('2c3e50');
    final colorTextoClaro = PdfColor.fromHex('7f8c8d');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(context, mes, colorPrimario),
        footer: (context) => _buildFooter(context, colorTextoClaro),
        build: (context) => [
          _buildResumenEjecutivo(metricas, colorPrimario, colorSecundario, colorTexto),
          pw.SizedBox(height: 24),
          _buildSeccionVentas(ventas, colorPrimario, colorTexto),
          pw.SizedBox(height: 24),
          _buildSeccionProduccion(produccion, colorSecundario, colorTexto),
          pw.SizedBox(height: 24),
          _buildSeccionGastos(gastos, colorTexto, colorTextoClaro),
        ],
      ),
    );

    // Guardar y compartir
    final bytes = await pdf.save();
    await _compartirPdf(bytes, mes);
  }

  pw.Widget _buildHeader(pw.Context context, DateTime mes, PdfColor colorPrimario) {
    final mesNombre = _getNombreMes(mes.month);
    
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: colorPrimario, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EXTRACTO MENSUAL',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
              pw.Text(
                '$mesNombre ${mes.year}',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColor.fromHex('7f8c8d'),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: colorPrimario,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'FÁBRICA',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildResumenEjecutivo(
    MetricasDashboard metricas,
    PdfColor colorPrimario,
    PdfColor colorSecundario,
    PdfColor colorTexto,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RESUMEN EJECUTIVO',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: colorTexto,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('f8f9fa'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  _buildMetricaCard(
                    'Dinero Total',
                    metricas.dineroTotalFormateado,
                    colorPrimario,
                  ),
                  _buildMetricaCard(
                    'Ventas del Mes',
                    metricas.ventasMesFormateado,
                    colorSecundario,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  _buildMetricaCard(
                    'Gastos Fábrica',
                    metricas.gastosFabricaMesFormateado,
                    PdfColor.fromHex('e74c3c'),
                  ),
                  _buildMetricaCard(
                    'Utilidad',
                    metricas.utilidadMesFormateado,
                    metricas.utilidadMes >= 0 
                        ? colorPrimario 
                        : PdfColor.fromHex('e74c3c'),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  _buildMetricaCard(
                    'Unidades Producidas',
                    metricas.unidadesFabricadasMes.toString(),
                    PdfColor.fromHex('3498db'),
                  ),
                  _buildMetricaCard(
                    'Unidades Vendidas',
                    metricas.unidadesVendidasMes.toString(),
                    PdfColor.fromHex('9b59b6'),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: colorPrimario, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Costo de Producto: ',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: colorTexto,
                      ),
                    ),
                    pw.Text(
                      metricas.costoProductoMesFormateado,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      ),
                    ),
                    pw.Text(
                      ' por unidad',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromHex('7f8c8d'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMetricaCard(String titulo, String valor, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromHex('e0e0e0')),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('7f8c8d'),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSeccionVentas(
    List<Venta> ventas,
    PdfColor colorPrimario,
    PdfColor colorTexto,
  ) {
    final totalVentas = ventas.fold<double>(0, (sum, v) => sum + v.total);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: colorPrimario,
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'DETALLE DE VENTAS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: colorTexto,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              '${ventas.length} ventas - Gs. ${totalVentas.toStringAsFixed(0)}',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromHex('7f8c8d'),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('e0e0e0')),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('f8f9fa')),
              children: [
                _buildTableHeader('Fecha'),
                _buildTableHeader('Vendedor'),
                _buildTableHeader('Items'),
                _buildTableHeader('Total'),
              ],
            ),
            ...ventas.map((v) => pw.TableRow(
              children: [
                _buildTableCell(v.fechaFormateada),
                _buildTableCell(v.nombreVendedor),
                _buildTableCell(v.totalUnidades.toString()),
                _buildTableCell(v.totalFormateado, alignRight: true),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSeccionProduccion(
    List<ProduccionData> produccion,
    PdfColor colorSecundario,
    PdfColor colorTexto,
  ) {
    final totalUnidades = produccion.fold<int>(0, (sum, p) => sum + p.cantidad);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: colorSecundario,
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'REGISTRO DE PRODUCCIÓN',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: colorTexto,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              '${produccion.length} registros - $totalUnidades unidades',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromHex('7f8c8d'),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('e0e0e0')),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('f8f9fa')),
              children: [
                _buildTableHeader('Fecha'),
                _buildTableHeader('Producto'),
                _buildTableHeader('Cantidad'),
                _buildTableHeader('Costo Unit.'),
              ],
            ),
            ...produccion.map((p) => pw.TableRow(
              children: [
                _buildTableCell('${p.fecha.day.toString().padLeft(2, '0')}/${p.fecha.month.toString().padLeft(2, '0')}'),
                _buildTableCell(p.nombreProducto),
                _buildTableCell(p.cantidad.toString()),
                _buildTableCell(
                  p.costoUnitarioCalculado != null 
                      ? 'Gs. ${p.costoUnitarioCalculado!.toStringAsFixed(0)}'
                      : 'Pendiente',
                  alignRight: true,
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSeccionGastos(
    List<GastoData> gastos,
    PdfColor colorTexto,
    PdfColor colorTextoClaro,
  ) {
    final gastosFabrica = gastos.where((g) => g.tipo == 'fabrica').toList();
    final gastosPersonal = gastos.where((g) => g.tipo == 'personal').toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: PdfColor.fromHex('e74c3c'),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'DETALLE DE GASTOS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: colorTexto,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        
        // Gastos de Fábrica
        pw.Text(
          'Gastos de Fábrica',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('e74c3c'),
          ),
        ),
        pw.SizedBox(height: 4),
        if (gastosFabrica.isEmpty)
          pw.Text(
            'No hay gastos de fábrica registrados',
            style: pw.TextStyle(
              fontSize: 11,
              color: colorTextoClaro,
              fontStyle: pw.FontStyle.italic,
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('e0e0e0')),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('fff5f5')),
                children: [
                  _buildTableHeader('Fecha'),
                  _buildTableHeader('Descripción'),
                  _buildTableHeader('Monto'),
                ],
              ),
              ...gastosFabrica.map((g) => pw.TableRow(
                children: [
                  _buildTableCell('${g.fecha.day.toString().padLeft(2, '0')}/${g.fecha.month.toString().padLeft(2, '0')}'),
                  _buildTableCell(g.descripcion),
                  _buildTableCell('Gs. ${g.monto.toStringAsFixed(0)}', alignRight: true),
                ],
              )),
            ],
          ),
        
        pw.SizedBox(height: 12),
        
        // Gastos Personales
        pw.Text(
          'Gastos Personales',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('f39c12'),
          ),
        ),
        pw.SizedBox(height: 4),
        if (gastosPersonal.isEmpty)
          pw.Text(
            'No hay gastos personales registrados',
            style: pw.TextStyle(
              fontSize: 11,
              color: colorTextoClaro,
              fontStyle: pw.FontStyle.italic,
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('e0e0e0')),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('fffbeb')),
                children: [
                  _buildTableHeader('Fecha'),
                  _buildTableHeader('Descripción'),
                  _buildTableHeader('Monto'),
                ],
              ),
              ...gastosPersonal.map((g) => pw.TableRow(
                children: [
                  _buildTableCell('${g.fecha.day.toString().padLeft(2, '0')}/${g.fecha.month.toString().padLeft(2, '0')}'),
                  _buildTableCell(g.descripcion),
                  _buildTableCell('Gs. ${g.monto.toStringAsFixed(0)}', alignRight: true),
                ],
              )),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('2c3e50'),
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColor.fromHex('2c3e50'),
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, PdfColor colorTextoClaro) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromHex('e0e0e0')),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado el ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
            style: pw.TextStyle(
              fontSize: 9,
              color: colorTextoClaro,
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: colorTextoClaro,
            ),
          ),
        ],
      ),
    );
  }

  String _getNombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  Future<void> _compartirPdf(Uint8List bytes, DateTime mes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/extracto_${mes.year}_${mes.month.toString().padLeft(2, '0')}.pdf');
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Extracto Mensual - ${_getNombreMes(mes.month)} ${mes.year}',
    );
  }
}

// Extension para conversión de datos
extension on Gasto {
  GastoData get data => this as GastoData;
}
