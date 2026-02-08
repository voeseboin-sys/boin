import 'package:flutter/material.dart';
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
  final _clienteController = TextEditingController();
  final _notasController = TextEditingController();
  final _descuentoController = TextEditingController(text: '0');

  @override
  void dispose() {
    _clienteController.dispose();
    _notasController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoVentaProvider);
    final productosAsync = ref.watch(productosProvider);
    final descuento = ref.watch(descuentoVentaProvider);

    final subtotal = carrito.fold<double>(0, (sum, item) => sum + item.subtotal);
    final total = subtotal - descuento;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        actions: [
          if (carrito.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(carritoVentaProvider.notifier).limpiar(),
              child: const Text('Limpiar'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selector de productos
          Expanded(
            flex: 2,
            child: productosAsync.when(
              data: (productos) => _buildProductosGrid(productos),
              loading: () => const LoadingWidget(),
              error: (_, __) => const ErrorWidget(message: 'Error al cargar productos'),
            ),
          ),
          
          // Carrito
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Items del carrito
                if (carrito.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: carrito.length,
                      itemBuilder: (context, index) {
                        final item = carrito[index];
                        return _buildCarritoItem(item);
                      },
                    ),
                  ),
                
                // Totales
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'Gs. ${subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Descuento
                      Row(
                        children: [
                          const Text(
                            'Descuento:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _descuentoController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                prefixText: 'Gs. ',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                final desc = double.tryParse(value) ?? 0;
                                ref.read(descuentoVentaProvider.notifier).state = desc;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gs. ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Botón confirmar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: carrito.isEmpty ? null : () => _confirmarVenta(total, subtotal),
                      child: const Text(
                        'Confirmar Venta',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosGrid(List<Producto> productos) {
    final productosConStock = productos.where((p) => p.stock > 0).toList();

    if (productosConStock.isEmpty) {
      return const EmptyStateWidget(
        title: 'No hay productos con stock',
        subtitle: 'Agrega productos o registra producción',
        icon: Icons.inventory_2_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: productosConStock.length,
      itemBuilder: (context, index) {
        final producto = productosConStock[index];
        return _buildProductoCard(producto);
      },
    );
  }

  Widget _buildProductoCard(Producto producto) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.surfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${producto.stock} disponibles',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'May: ${producto.precioMayoristaFormateado}',
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Min: ${producto.precioMinoristaFormateado}',
                    style: const TextStyle(
                      color: AppTheme.accentPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botones de precio
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _agregarAlCarrito(producto, TipoPrecio.mayorista),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'MAYORISTA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _agregarAlCarrito(producto, TipoPrecio.minorista),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'MINORISTA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.accentPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoItem(VentaItem item) {
    return ListTile(
      dense: true,
      title: Text(
        item.nombreProducto,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${item.cantidad} x Gs. ${item.precioUnitario.toStringAsFixed(0)}',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gs. ${item.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: AppTheme.error),
            onPressed: () {
              ref.read(carritoVentaProvider.notifier).eliminarItem(item.id);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _agregarAlCarrito(Producto producto, TipoPrecio tipoPrecio) {
    // Verificar stock
    final carrito = ref.read(carritoVentaProvider);
    final itemExistente = carrito.firstWhere(
      (i) => i.productoId == producto.id && i.tipoPrecio == tipoPrecio,
      orElse: () => const VentaItem(
        id: '',
        productoId: '',
        nombreProducto: '',
        cantidad: 0,
        precioUnitario: 0,
        tipoPrecio: TipoPrecio.minorista,
        subtotal: 0,
      ),
    );
    
    final cantidadEnCarrito = itemExistente.id.isNotEmpty ? itemExistente.cantidad : 0;
    
    if (cantidadEnCarrito >= producto.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay suficiente stock'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    ref.read(carritoVentaProvider.notifier).agregarItem(
      producto: producto,
      cantidad: 1,
      tipoPrecio: tipoPrecio,
    );
  }

  Future<void> _confirmarVenta(double total, double subtotal) async {
    final carrito = ref.read(carritoVentaProvider);
    final descuento = ref.read(descuentoVentaProvider);

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Confirmar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(
                labelText: 'Cliente (opcional)',
                hintText: 'Nombre del cliente',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Notas adicionales',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items:'),
                      Text('${carrito.length}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('Gs. ${subtotal.toStringAsFixed(0)}'),
                    ],
                  ),
                  if (descuento > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Descuento:'),
                        Text('-Gs. ${descuento.toStringAsFixed(0)}'),
                      ],
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Gs. ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(ventaNotifierProvider.notifier).registrarVenta(
        items: carrito,
        subtotal: subtotal,
        descuento: descuento,
        total: total,
        cliente: _clienteController.text.isEmpty ? null : _clienteController.text,
        notas: _notasController.text.isEmpty ? null : _notasController.text,
      );

      // Limpiar carrito
      ref.read(carritoVentaProvider.notifier).limpiar();
      ref.read(descuentoVentaProvider.notifier).state = 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta registrada correctamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
