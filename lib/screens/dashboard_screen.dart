import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final mesSeleccionado = ref.watch(mesSeleccionadoProvider);
    final metricasAsync = ref.watch(metricasProvider(mesSeleccionado));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Selector de mes
          TextButton.icon(
            onPressed: () => _seleccionarMes(context, ref),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              mesSeleccionado.toMonthYearString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          
          // Exportar PDF (solo dueño)
          if (auth.isDueno)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Exportar PDF',
              onPressed: () => _exportarPDF(context, ref, mesSeleccionado),
            ),
          
          // Cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarLogout(context, ref),
          ),
        ],
      ),
      body: metricasAsync.when(
        data: (metricas) => _buildDashboard(context, ref, metricas, auth),
        loading: () => const LoadingWidget(message: 'Cargando métricas...'),
        error: (error, _) => ErrorWidget(
          message: 'Error al cargar métricas: $error',
          onRetry: () => ref.invalidate(metricasProvider),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    MetricasDashboard metricas,
    AuthState auth,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(metricasProvider);
        ref.invalidate(ventasProvider);
        ref.invalidate(productosProvider);
      },
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${auth.usuario?.nombre ?? 'Usuario'}!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.isDueno ? 'Dueño' : 'Vendedor',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: auth.isDueno 
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : AppTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    auth.isDueno ? 'ADMIN' : 'STAFF',
                    style: TextStyle(
                      color: auth.isDueno ? AppTheme.primaryColor : AppTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Dinero Total (solo dueño)
            if (auth.isDueno) ...[
              _buildDineroTotalCard(metricas.dineroTotal),
              const SizedBox(height: 24),
            ],
            
            // Métricas del mes
            Text(
              'Métricas del Mes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Grid de métricas
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                MetricCard(
                  title: 'Ventas del Mes',
                  value: metricas.ventasMesFormateado,
                  icon: Icons.trending_up,
                  color: AppTheme.success,
                ),
                MetricCard(
                  title: 'Gastos Fábrica',
                  value: metricas.gastosFabricaMesFormateado,
                  icon: Icons.build,
                  color: AppTheme.accentOrange,
                ),
                if (auth.isDueno)
                  MetricCard(
                    title: 'Gastos Personales',
                    value: metricas.gastosPersonalesMesFormateado,
                    icon: Icons.person_outline,
                    color: AppTheme.accentRed,
                  ),
                MetricCard(
                  title: 'Utilidad',
                  value: metricas.utilidadMesFormateado,
                  icon: Icons.account_balance_wallet,
                  color: metricas.utilidadMes >= 0 
                      ? AppTheme.primaryColor 
                      : AppTheme.error,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Costo de producto
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Costo de Producto',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metricas.costoProductoMesFormateado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'por unidad producida',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Producción y ventas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Producidas',
                    metricas.unidadesFabricadasMes.toString(),
                    Icons.precision_manufacturing,
                    AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Vendidas',
                    metricas.unidadesVendidasMes.toString(),
                    Icons.shopping_cart,
                    AppTheme.accentPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Accesos rápidos
            Text(
              'Accesos Rápidos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildQuickAccessGrid(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildDineroTotalCard(double dineroTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dinero Total Acumulado',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gs. ${dineroTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, AuthState auth) {
    final items = <_QuickAccessItem>[];
    
    // Accesos comunes
    items.add(_QuickAccessItem(
      label: 'Ventas',
      icon: Icons.point_of_sale,
      color: AppTheme.success,
      onTap: () => Navigator.pushNamed(context, '/ventas'),
    ));
    
    items.add(_QuickAccessItem(
      label: 'Stock',
      icon: Icons.inventory_2,
      color: AppTheme.accentBlue,
      onTap: () => Navigator.pushNamed(context, '/productos'),
    ));
    
    items.add(_QuickAccessItem(
      label: 'Producción',
      icon: Icons.precision_manufacturing,
      color: AppTheme.accentPurple,
      onTap: () => Navigator.pushNamed(context, '/produccion'),
    ));
    
    // Accesos solo para dueño
    if (auth.isDueno) {
      items.add(_QuickAccessItem(
        label: 'Gastos',
        icon: Icons.receipt_long,
        color: AppTheme.accentOrange,
        onTap: () => Navigator.pushNamed(context, '/gastos'),
      ));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items.map((item) => _buildQuickAccessButton(item)).toList(),
    );
  }

  Widget _buildQuickAccessButton(_QuickAccessItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: item.color,
              size: 14,
            ),
          ],
        ),
      ),
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
      helpText: 'Seleccionar mes',
      fieldLabelText: 'Mes/Año',
      selectableDayPredicate: (date) => false,
    );
    
    if (picked != null) {
      ref.read(mesSeleccionadoProvider.notifier).state = 
          DateTime(picked.year, picked.month);
    }
  }

  Future<void> _exportarPDF(BuildContext context, WidgetRef ref, DateTime mes) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Generando PDF...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );

    try {
      final db = ref.read(databaseProvider);
      final pdfService = PdfService(db);
      await pdfService.generarExtractoMensual(mes);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generado correctamente'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmarLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Cerrar Sesión',
      confirmColor: AppTheme.error,
      icon: Icons.logout,
    );

    if (confirm) {
      ref.read(authProvider.notifier).logout();
    }
  }
}

class _QuickAccessItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
