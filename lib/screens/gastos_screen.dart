import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class GastosScreen extends ConsumerWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final mesSeleccionado = ref.watch(mesSeleccionadoProvider);
    final gastosAsync = ref.watch(gastosByMesProvider(mesSeleccionado));
    final metricasAsync = ref.watch(metricasProvider(mesSeleccionado));

    // Vendedores no deberían ver esta pantalla, pero por si acaso
    if (!auth.isDueno) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gastos')),
        body: const Center(
          child: Text(
            'No tienes permiso para ver esta sección',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Gastos'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.build), text: 'Fábrica'),
              Tab(icon: Icon(Icons.person), text: 'Personales'),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _seleccionarMes(context, ref),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(mesSeleccionado.toMonthYearString()),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Gastos de Fábrica
            _buildGastosTab(
              context,
              ref,
              TipoGasto.fabrica,
              gastosAsync,
              metricasAsync,
            ),
            // Gastos Personales
            _buildGastosTab(
              context,
              ref,
              TipoGasto.personal,
              gastosAsync,
              metricasAsync,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _mostrarFormularioGasto(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Gasto'),
        ),
      ),
    );
  }

  Widget _buildGastosTab(
    BuildContext context,
    WidgetRef ref,
    TipoGasto tipo,
    AsyncValue<List<Gasto>> gastosAsync,
    AsyncValue<MetricasDashboard> metricasAsync,
  ) {
    return Column(
      children: [
        // Resumen
        metricasAsync.when(
          data: (metricas) => _buildResumenGastos(metricas, tipo),
          loading: () => const ShimmerLoading(width: double.infinity, height: 100),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        // Lista
        Expanded(
          child: gastosAsync.when(
            data: (gastos) {
              final gastosFiltrados = gastos.where((g) => g.tipo == tipo).toList();
              return _buildListaGastos(context, ref, gastosFiltrados);
            },
            loading: () => const LoadingWidget(),
            error: (error, _) => ErrorWidget(
              message: 'Error al cargar gastos: $error',
              onRetry: () => ref.invalidate(gastosProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenGastos(MetricasDashboard metricas, TipoGasto tipo) {
    final total = tipo == TipoGasto.fabrica 
        ? metricas.gastosFabricaMes 
        : metricas.gastosPersonalesMes;
    final color = tipo == TipoGasto.fabrica ? AppTheme.accentOrange : AppTheme.accentRed;
    final icon = tipo == TipoGasto.fabrica ? Icons.build : Icons.person;
    final titulo = tipo == TipoGasto.fabrica ? 'Gastos de Fábrica' : 'Gastos Personales';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gs. ${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
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

  Widget _buildListaGastos(
    BuildContext context,
    WidgetRef ref,
    List<Gasto> gastos,
  ) {
    if (gastos.isEmpty) {
      return EmptyStateWidget(
        title: 'No hay gastos registrados',
        subtitle: 'Registra tus gastos del mes',
        icon: Icons.receipt_long_outlined,
        onAction: () => _mostrarFormularioGasto(context, ref),
        actionLabel: 'Nuevo Gasto',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: gastos.length,
      itemBuilder: (context, index) {
        final gasto = gastos[index];
        return _buildGastoCard(context, ref, gasto);
      },
    );
  }

  Widget _buildGastoCard(
    BuildContext context,
    WidgetRef ref,
    Gasto gasto,
  ) {
    final color = gasto.tipo == TipoGasto.fabrica 
        ? AppTheme.accentOrange 
        : AppTheme.accentRed;
    final icon = gasto.tipo == TipoGasto.fabrica 
        ? Icons.build 
        : Icons.person;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _confirmarEliminar(context, ref, gasto),
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Eliminar',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gasto.descripcion,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              gasto.nombreCategoria,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            gasto.fechaFormateada,
                            style: const TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (gasto.notas != null && gasto.notas!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          gasto.notas!,
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  gasto.montoFormateado,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarFormularioGasto(BuildContext context, WidgetRef ref) async {
    TipoGasto tipo = TipoGasto.fabrica;
    String categoria = 'materiaPrima';
    final descripcionController = TextEditingController();
    final montoController = TextEditingController();
    final notasController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final categorias = tipo == TipoGasto.fabrica
              ? AppConstants.categoriasGastoFabrica
              : AppConstants.categoriasGastoPersonal;

          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Nuevo Gasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tipo de gasto
                  SegmentedButton<TipoGasto>(
                    segments: const [
                      ButtonSegment(
                        value: TipoGasto.fabrica,
                        label: Text('Fábrica'),
                        icon: Icon(Icons.build),
                      ),
                      ButtonSegment(
                        value: TipoGasto.personal,
                        label: Text('Personal'),
                        icon: Icon(Icons.person),
                      ),
                    ],
                    selected: {tipo},
                    onSelectionChanged: (selected) {
                      setState(() {
                        tipo = selected.first;
                        categoria = tipo == TipoGasto.fabrica 
                            ? 'materiaPrima' 
                            : 'salario';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Categoría
                  DropdownButtonFormField<String>(
                    value: categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                    ),
                    items: categorias.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => categoria = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Descripción
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción *',
                      hintText: 'Ej: Compra de materiales',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Monto
                  TextField(
                    controller: montoController,
                    decoration: const InputDecoration(
                      labelText: 'Monto *',
                      prefixText: 'Gs. ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  
                  // Notas
                  TextField(
                    controller: notasController,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: descripcionController.text.isNotEmpty &&
                          montoController.text.isNotEmpty
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final monto = double.tryParse(montoController.text) ?? 0;
      
      if (monto <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto debe ser mayor a cero'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      await ref.read(gastoNotifierProvider.notifier).registrarGasto(
        descripcion: descripcionController.text.trim(),
        monto: monto,
        tipo: tipo,
        categoria: categoria,
        notas: notasController.text.isEmpty ? null : notasController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto registrado correctamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    }

    descripcionController.dispose();
    montoController.dispose();
    notasController.dispose();
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Gasto gasto,
  ) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar Gasto',
      message: '¿Estás seguro de eliminar este gasto?',
      confirmColor: AppTheme.error,
    );

    if (confirm) {
      await ref.read(gastoNotifierProvider.notifier).eliminarGasto(gasto.id);
    }
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
}
