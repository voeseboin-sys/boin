import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class ProduccionScreen extends ConsumerWidget {
  const ProduccionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final mesSeleccionado = ref.watch(mesSeleccionadoProvider);
    final produccionAsync = ref.watch(produccionByMesProvider(mesSeleccionado));
    final metricasAsync = ref.watch(metricasProvider(mesSeleccionado));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Producción'),
        actions: [
          TextButton.icon(
            onPressed: () => _seleccionarMes(context, ref),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(mesSeleccionado.toMonthYearString()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen
          metricasAsync.when(
            data: (metricas) => _buildResumenProduccion(metricas),
            loading: () => const ShimmerLoading(width: double.infinity, height: 120),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Lista
          Expanded(
            child: produccionAsync.when(
              data: (produccion) => _buildListaProduccion(context, ref, produccion, auth),
              loading: () => const LoadingWidget(),
              error: (error, _) => ErrorWidget(
                message: 'Error al cargar producción: $error',
                onRetry: () => ref.invalidate(produccionProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioProduccion(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }

  Widget _buildResumenProduccion(MetricasDashboard metricas) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentPurple, Color(0xFF8e44ad)],
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
                  'Unidades Producidas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${metricas.unidadesFabricadasMes}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Costo unitario: ${metricas.costoProductoMesFormateado}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.precision_manufacturing,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProduccion(
    BuildContext context,
    WidgetRef ref,
    List<Produccion> produccion,
    AuthState auth,
  ) {
    if (produccion.isEmpty) {
      return EmptyStateWidget(
        title: 'No hay producción registrada',
        subtitle: 'Registra la producción de este mes',
        icon: Icons.precision_manufacturing_outlined,
        onAction: () => _mostrarFormularioProduccion(context, ref),
        actionLabel: 'Registrar Producción',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: produccion.length,
      itemBuilder: (context, index) {
        final prod = produccion[index];
        return _buildProduccionCard(context, ref, prod, auth);
      },
    );
  }

  Widget _buildProduccionCard(
    BuildContext context,
    WidgetRef ref,
    Produccion produccion,
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
                    onPressed: (_) => _confirmarEliminar(context, ref, produccion),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.accentPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produccion.nombreProducto,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        produccion.fechaFormateada,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (produccion.notas != null && produccion.notas!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          produccion.notas!,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${produccion.cantidad}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (produccion.costoUnitarioCalculado != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        produccion.costoUnitarioFormateado,
                        style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarFormularioProduccion(BuildContext context, WidgetRef ref) async {
    final productosAsync = await ref.read(productosProvider.future);
    
    if (productosAsync.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debe crear productos'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    Producto? productoSeleccionado;
    final cantidadController = TextEditingController();
    final notasController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Registrar Producción'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selector de producto
                  DropdownButtonFormField<Producto>(
                    value: productoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Producto *',
                    ),
                    items: productosAsync.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        productoSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Cantidad
                  TextField(
                    controller: cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad *',
                      hintText: 'Ej: 100',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  
                  // Notas
                  TextField(
                    controller: notasController,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      hintText: 'Observaciones',
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
                onPressed: productoSeleccionado != null && 
                          cantidadController.text.isNotEmpty
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Registrar'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && productoSeleccionado != null) {
      final cantidad = int.tryParse(cantidadController.text) ?? 0;
      
      if (cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cantidad debe ser mayor a cero'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      await ref.read(produccionNotifierProvider.notifier).registrarProduccion(
        productoId: productoSeleccionado!.id,
        nombreProducto: productoSeleccionado!.nombre,
        cantidad: cantidad,
        notas: notasController.text.isEmpty ? null : notasController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producción registrada correctamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    }

    cantidadController.dispose();
    notasController.dispose();
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Produccion produccion,
  ) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar Registro',
      message: '¿Estás seguro de eliminar este registro de producción?',
      confirmColor: AppTheme.error,
    );

    if (confirm) {
      await ref.read(produccionNotifierProvider.notifier).eliminarProduccion(produccion.id);
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
