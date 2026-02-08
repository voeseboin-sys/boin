import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class ProductosScreen extends ConsumerWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final productosAsync = ref.watch(productosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock de Productos'),
        actions: [
          if (auth.isDueno)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _mostrarFormularioProducto(context, ref),
            ),
        ],
      ),
      body: productosAsync.when(
        data: (productos) => _buildListaProductos(context, ref, productos, auth),
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorWidget(
          message: 'Error: $error',
          onRetry: () => ref.invalidate(productosProvider),
        ),
      ),
    );
  }

  Widget _buildListaProductos(BuildContext context, WidgetRef ref, List<Producto> productos, AuthState auth) {
    if (productos.isEmpty) return const EmptyStateWidget(title: 'Sin productos', message: 'Agrega el primero');

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        return Card(
          child: ListTile(
            title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Stock: ${producto.stock} | Mayorista: ${producto.precioMayorista.toCurrency()}'),
            trailing: auth.isDueno 
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminar(context, ref, producto),
                )
              : null,
            onTap: auth.isDueno ? () => _mostrarFormularioProducto(context, ref, producto: producto) : null,
          ),
        );
      },
    );
  }

  Future<void> _mostrarFormularioProducto(BuildContext context, WidgetRef ref, {Producto? producto}) async {
    final isEdit = producto != null;
    final nombreCtrl = TextEditingController(text: producto?.nombre);
    final costoCtrl = TextEditingController(text: "0"); // Por ahora 0 o lo que venga
    final precioMayCtrl = TextEditingController(text: producto?.precioMayorista.toString());
    final precioMinCtrl = TextEditingController(text: producto?.precioMinorista.toString());
    final stockCtrl = TextEditingController(text: producto?.stock.toString() ?? '0');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              if (!isEdit)
                TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock Inicial'), keyboardType: TextInputType.number),
              TextField(controller: precioMayCtrl, decoration: const InputDecoration(labelText: 'Precio Mayorista'), keyboardType: TextInputType.number),
              TextField(controller: precioMinCtrl, decoration: const InputDecoration(labelText: 'Precio Minorista'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (isEdit) {
                 await ref.read(productoNotifierProvider.notifier).actualizarProducto(
                  id: producto!.id,
                  nombre: nombreCtrl.text,
                  costo: 0, 
                  precioMayorista: double.tryParse(precioMayCtrl.text) ?? 0,
                  precioMinorista: double.tryParse(precioMinCtrl.text) ?? 0,
                );
              } else {
                await ref.read(productoNotifierProvider.notifier).crearProducto(
                  nombre: nombreCtrl.text,
                  costo: 0,
                  precioMayorista: double.tryParse(precioMayCtrl.text) ?? 0,
                  precioMinorista: double.tryParse(precioMinCtrl.text) ?? 0,
                  stockInicial: int.tryParse(stockCtrl.text) ?? 0,
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref, Producto p) async {
    final confirm = await ConfirmDialog.show(context: context, title: 'Eliminar', message: '¿Borrar ${p.nombre}?');
    if (confirm) {
      await ref.read(productoNotifierProvider.notifier).eliminarProducto(p.id);
    }
  }
}
