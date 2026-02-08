import 'package:flutter/material.dart' hide ErrorWidget; // <--- TRUCO IMPORTANTE
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/core.dart';
import '../providers/providers.dart';
// Eliminado import de services para borrar rastro del PDF
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
          
          // Cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _confirmarLogout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(metricasProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${auth.usuario?.nombre ?? "Usuario"}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Tarjetas de Resumen
              metricasAsync.when(
                data: (metricas) => Column(
                  children: [
                    _buildSummaryCards(metricas),
                    const SizedBox(height: 24),
                    _buildChartsSection(metricas),
                  ],
                ),
                loading: () => const ShimmerLoading(width: double.infinity, height: 200),
                error: (error, _) => ErrorWidget( // Ahora usa tu widget personalizado
                  message: 'Error al cargar métricas: $error',
                  onRetry: () => ref.invalidate(metricasProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(MetricasDashboard m) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Ventas Netas',
                value: m.ventasTotales.toCurrency(),
                icon: Icons.attach_money,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Utilidad',
                value: m.utilidadNeta.toCurrency(),
                icon: Icons.trending_up,
                color: m.utilidadNeta >= 0 ? AppTheme.primaryColor : AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Gastos',
                value: m.gastosTotales.toCurrency(),
                icon: Icons.money_off,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Producción',
                value: '${m.cantidadProduccion} u.',
                icon: Icons.inventory_2,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsSection(MetricasDashboard m) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución Financiera',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Center(
                child: m.ventasTotales == 0 
                  ? const Text('Sin datos para graficar')
                  : const Icon(Icons.pie_chart, size: 100, color: Colors.grey),
              ),
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
    );
    if (picked != null) {
      ref.read(mesSeleccionadoProvider.notifier).state = DateTime(picked.year, picked.month);
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
