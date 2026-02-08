import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class NuevaVentaScreen extends ConsumerStatefulWidget {
  const NuevaVentaScreen({super.key});
  @override
  ConsumerState<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends ConsumerState<NuevaVentaScreen> {
  // Nota: Por ahora la base de datos simple no guarda cliente, lo dejamos visual
  final _clienteController = TextEditingController(); 

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    final productosAsync = ref.watch(productosProvider);
    final total = ref.read(carritoProvider.notifier).total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        actions: [
          if (carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => ref.read(carritoProvider.notifier).limpiarCarrito(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Buscador de productos
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: productosAsync.when(
              data: (productos) => DropdownButtonFormField<Producto>(
                decoration: const InputDecoration(labelText: 'Agregar Producto al Carrito'),
                items: productos.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text("${p.nombre} (Stock: ${p.stock})"),
                )).toList(),
                onChanged: (producto) {
                  if (producto != null) {
                    // Agregamos 1 unidad por defecto
                    ref.read(carritoProvider.notifier).agregarItem(producto, 1, producto.precioMinorista);
                  }
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_,__) => const SizedBox(),
            ),
          ),
          
          // Lista del Carrito
          Expanded(
            child: carrito.isEmpty 
              ? const Center(child: Text("Carrito vacío"))
              : ListView.builder(
                  itemCount: carrito.length,
                  itemBuilder: (context, index) {
                    final item = carrito[index];
                    return ListTile(
                      title: Text(item.nombreProducto),
                      subtitle: Text("${item.cantidad} x ${item.precioUnitario.toCurrency()}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => ref.read(carritoProvider.notifier).quitarItem(item.productoId),
                      ),
                    );
                  },
                ),
          ),
          
          // Botón Finalizar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: ${total.toCurrency()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: carrito.isEmpty ? null : _procesarVenta,
                  child: const Text("CONFIRMAR VENTA"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _procesarVenta() async {
    // Llamamos al provider que guarda todo
    await ref.read(ventaActionProvider.notifier).confirmarVenta();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Venta Exitosa!")));
      Navigator.pop(context);
    }
  }
}
