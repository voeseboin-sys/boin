import 'package:flutter/material.dart';
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
          // Solo dueño puede agregar productos
          if (auth.isDueno)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nuevo Producto',
              onPressed: () => _mostrarFormularioProducto(context, ref),
            ),
        ],
      ),
      body: productosAsync.when(
        data: (productos) => _buildListaProductos(context, ref, productos, auth),
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorWidget(
          message: 'Error al cargar productos: $error',
          onRetry: () => ref.invalidate(productosProvider),
        ),
      ),
    );
  }

  Widget _buildListaProductos(
    BuildContext context,
    WidgetRef ref,
    List<Producto> productos,
    AuthState auth,
  ) {
    if (productos.isEmpty) {
      return EmptyStateWidget(
        title: 'No hay productos',
        subtitle: 'Comienza agregando tu primer producto',
        icon: Icons.inventory_2_outlined,
        onAction: auth.isDueno ? () => _mostrarFormularioProducto(context, ref) : null,
        actionLabel: 'Agregar Producto',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        return _buildProductoCard(context, ref, producto, auth);
      },
    );
  }

  Widget _buildProductoCard(
    BuildContext context,
    WidgetRef ref,
    Producto producto,
    AuthState auth,
  ) {
    final tieneStockBajo = producto.stock < 5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        // Solo dueño puede editar/eliminar
        endActionPane: auth.isDueno
            ? ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _mostrarFormularioProducto(
                      context, 
                      ref, 
                      producto: producto,
                    ),
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Editar',
                  ),
                  SlidableAction(
                    onPressed: (_) => _confirmarEliminar(context, ref, producto),
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
            border: Border.all(
              color: tieneStockBajo 
                  ? AppTheme.error.withOpacity(0.3) 
                  : AppTheme.surfaceVariant,
            ),
          ),
          child: InkWell(
            onTap: () => _mostrarDetalleProducto(context, producto),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tieneStockBajo
                              ? AppTheme.error.withOpacity(0.2)
                              : AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${producto.stock} uds.',
                          style: TextStyle(
                            color: tieneStockBajo
                                ? AppTheme.error
                                : AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (producto.descripcion != null && 
                      producto.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      producto.descripcion!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPrecioColumn(
                          'Mayorista',
                          producto.precioMayoristaFormateado,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.surfaceVariant,
                      ),
                      Expanded(
                        child: _buildPrecioColumn(
                          'Minorista',
                          producto.precioMinoristaFormateado,
                        ),
                      ),
                      if (auth.isDueno) ...[
                        Container(
                          width: 1,
                          height: 30,
                          color: AppTheme.surfaceVariant,
                        ),
                        Expanded(
                          child: _buildPrecioColumn(
                            'Costo',
                            producto.costoProduccionFormateado,
                            color: AppTheme.accentOrange,
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
      ),
    );
  }

  Widget _buildPrecioColumn(String label, String precio, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          precio,
          style: TextStyle(
            color: color ?? AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _mostrarDetalleProducto(BuildContext context, Producto producto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (producto.descripcion != null)
                        Text(
                          producto.descripcion!,
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
            _buildDetalleRow('Stock disponible:', '${producto.stock} unidades'),
            _buildDetalleRow('Precio Mayorista:', producto.precioMayoristaFormateado),
            _buildDetalleRow('Precio Minorista:', producto.precioMinoristaFormateado),
            _buildDetalleRow('Costo de producción:', producto.costoProduccionFormateado),
            _buildDetalleRow('Mes de fabricación:', producto.mesFabricacionFormateado),
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
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarFormularioProducto(
    BuildContext context,
    WidgetRef ref, {
    Producto? producto,
  }) async {
    final isEdit = producto != null;
    final nombreController = TextEditingController(text: producto?.nombre ?? '');
    final descripcionController = TextEditingController(text: producto?.descripcion ?? '');
    final precioMayController = TextEditingController(
      text: producto?.precioMayorista.toString() ?? '',
    );
    final precioMinController = TextEditingController(
      text: producto?.precioMinorista.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: producto?.stock.toString() ?? '0',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Producto A',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Descripción opcional',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: precioMayController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Mayorista *',
                        prefixText: 'Gs. ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: precioMinController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Minorista *',
                        prefixText: 'Gs. ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Inicial',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );

    if (result == true) {
      final nombre = nombreController.text.trim();
      final descripcion = descripcionController.text.trim();
      final precioMay = double.tryParse(precioMayController.text) ?? 0;
      final precioMin = double.tryParse(precioMinController.text) ?? 0;
      final stock = int.tryParse(stockController.text) ?? 0;

      if (nombre.isEmpty || precioMay <= 0 || precioMin <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor complete todos los campos obligatorios'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      if (isEdit) {
        await ref.read(productoNotifierProvider.notifier).actualizarProducto(
          id: producto.id,
          nombre: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
          precioMayorista: precioMay,
          precioMinorista: precioMin,
        );
      } else {
        await ref.read(productoNotifierProvider.notifier).crearProducto(
          nombre: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
          precioMayorista: precioMay,
          precioMinorista: precioMin,
          stockInicial: stock,
        );
      }
    }

    nombreController.dispose();
    descripcionController.dispose();
    precioMayController.dispose();
    precioMinController.dispose();
    stockController.dispose();
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Producto producto,
  ) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar Producto',
      message: '¿Estás seguro de eliminar "${producto.nombre}"?',
      confirmColor: AppTheme.error,
    );

    if (confirm) {
      await ref.read(productoNotifierProvider.notifier).eliminarProducto(producto.id);
    }
  }
}
