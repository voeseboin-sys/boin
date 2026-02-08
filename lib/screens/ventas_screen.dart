import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class VentasScreen extends ConsumerWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final mesSeleccionado = ref.watch(mesSeleccionadoProvider);
    final ventasAsync = ref.watch(ventasByMesProvider(mesSeleccionado));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ventas'),
        actions: [
          TextButton.icon(
            onPressed: () => _seleccionarMes(context, ref),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(mesSeleccionado.toMonthYearString()),
          ),
        ],
      ),
      body: ventasAsync.when(
        data: (ventas) => _buildListaVentas(context, ref, ventas, auth),
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorWidget(
          message: 'Error al cargar ventas: $error',
          onRetry: () => ref.invalidate(ventasProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/nueva-venta'),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva Venta'),
      ),
    );
  }

  Widget _buildListaVentas(
    BuildContext context,
    WidgetRef ref,
    List<Venta> ventas,
    AuthState auth,
  ) {
    if (ventas.isEmpty) {
      return EmptyStateWidget(
        title: 'No hay ventas este mes',
        subtitle: 'Registra tu primera venta',
        icon: Icons.receipt_long_outlined,
        onAction: () => Navigator.pushNamed(context, '/nueva-venta'),
        actionLabel: 'Nueva Venta',
      );
    }

    // Calcular totales
    final totalVentas = ventas.fold<double>(0, (sum, v) => sum + v.total);
    final totalItems = ventas.fold<int>(0, (sum, v) => sum + v.totalUnidades);

    return Column(
      children: [
        // Resumen
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total del Mes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gs. ${totalVentas.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ventas.length} ventas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de ventas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              return _buildVentaCard(context, ref, venta, auth);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVentaCard(
    BuildContext context,
    WidgetRef ref,
    Venta venta,
    AuthState auth,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        endActionPane: auth.isDueno
            ? ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _confirmarEliminar(context, ref, venta),
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Eliminar',
                  ),
                ],
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _mostrarDetalleVenta(context, venta),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt,
                          color: AppTheme.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venta.fechaFormateada,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              venta.nombreVendedor,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        venta.totalFormateado,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (venta.descuento > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Descuento: ${venta.descuentoFormateado}',
                        style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${venta.totalUnidades} productos',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${venta.items.length} items',
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleVenta(BuildContext context, Venta venta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppTheme.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Venta #${venta.id.substring(0, 8)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            venta.fechaFormateada,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Items
                const Text(
                  'Productos',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...venta.items.map((item) => _buildItemRow(item)),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Totales
                _buildTotalRow('Subtotal:', venta.subtotalFormateado),
                if (venta.descuento > 0)
                  _buildTotalRow('Descuento:', '-${venta.descuentoFormateado}', 
                      color: AppTheme.accentOrange),
                _buildTotalRow('Total:', venta.totalFormateado, 
                    isBold: true, color: AppTheme.primaryColor),
                
                if (venta.cliente != null && venta.cliente!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow('Cliente:', venta.cliente!),
                ],
                if (venta.notas != null && venta.notas!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Notas:', venta.notas!),
                ],
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemRow(VentaItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombreProducto,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${item.cantidad} x Gs. ${item.precioUnitario.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.tipoPrecio == TipoPrecio.mayorista
                  ? AppTheme.accentBlue.withOpacity(0.15)
                  : AppTheme.accentPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.tipoPrecio == TipoPrecio.mayorista ? 'Mayorista' : 'Minorista',
              style: TextStyle(
                color: item.tipoPrecio == TipoPrecio.mayorista
                    ? AppTheme.accentBlue
                    : AppTheme.accentPurple,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Gs. ${item.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, 
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.textPrimary,
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarMes(BuildContext context, WidgetRef ref) async {
    final mesActual = ref.read(mesSeleccionadoProvider);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: mesActual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      ref.read(mesSeleccionadoProvider.notifier).state = 
          DateTime(picked.year, picked.month);
    }
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Venta venta,
  ) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar Venta',
      message: '¿Estás seguro de eliminar esta venta? El stock será restaurado.',
      confirmColor: AppTheme.error,
    );

    if (confirm) {
      await ref.read(ventaNotifierProvider.notifier).eliminarVenta(venta.id);
    }
  }
}
