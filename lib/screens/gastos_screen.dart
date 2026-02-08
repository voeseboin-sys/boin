import 'package:flutter/material.dart' hide ErrorWidget;
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
    // Nota: gastosByMesProvider ahora espera un DateTime
    final gastosAsync = ref.watch(gastosByMesProvider(mesSeleccionado));

    if (!auth.isDueno) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gastos')),
        body: const Center(child: Text('Acceso restringido')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Gastos'),
        actions: [
           IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarFormularioGasto(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
           Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Mes: ${mesSeleccionado.toMonthYearString()}"),
           ),
           Expanded(
             child: gastosAsync.when(
              data: (gastos) => _buildListaGastos(context, ref, gastos),
              loading: () => const LoadingWidget(),
              error: (error, _) => ErrorWidget(
                message: 'Error: $error',
                onRetry: () => ref.invalidate(gastosByMesProvider(mesSeleccionado)),
              ),
          ),
           ),
        ],
      ),
    );
  }

  Widget _buildListaGastos(BuildContext context, WidgetRef ref, List<Gasto> gastos) {
    if (gastos.isEmpty) return const EmptyStateWidget(title: 'No hay gastos', message: 'Agrega uno nuevo');

    return ListView.builder(
      itemCount: gastos.length,
      itemBuilder: (context, index) {
        final gasto = gastos[index];
        return Slidable(
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: gasto.tipo == TipoGasto.fabrica ? Colors.orange[100] : Colors.blue[100],
              child: Icon(
                gasto.tipo == TipoGasto.fabrica ? Icons.factory : Icons.person,
                color: gasto.tipo == TipoGasto.fabrica ? Colors.orange : Colors.blue,
              ),
            ),
            title: Text(gasto.descripcion),
            subtitle: Text(gasto.fecha.toFormattedString()),
            trailing: Text(
              gasto.monto.toCurrency(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  Future<void> _mostrarFormularioGasto(BuildContext context, WidgetRef ref) async {
    final descripcionController = TextEditingController();
    final montoController = TextEditingController();
    TipoGasto tipo = TipoGasto.fabrica;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descripcionController, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 10),
              TextField(
                controller: montoController, 
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButton<TipoGasto>(
                value: tipo,
                isExpanded: true,
                onChanged: (val) => setState(() => tipo = val!),
                items: const [
                  DropdownMenuItem(value: TipoGasto.fabrica, child: Text('Fábrica')),
                  DropdownMenuItem(value: TipoGasto.personal, child: Text('Personal')),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final monto = double.tryParse(montoController.text) ?? 0;
                if (monto > 0 && descripcionController.text.isNotEmpty) {
                  // CORRECCIÓN: Usamos el nombre nuevo del método 'agregarGasto'
                  await ref.read(gastoNotifierProvider.notifier).agregarGasto(
                    descripcion: descripcionController.text,
                    monto: monto,
                    tipo: tipo,
                    fecha: DateTime.now(),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref, Gasto gasto) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar',
      message: '¿Borrar este gasto?',
      confirmColor: AppTheme.error,
    );
    if (confirm) {
      await ref.read(gastoNotifierProvider.notifier).eliminarGasto(gasto.id);
    }
  }
}
