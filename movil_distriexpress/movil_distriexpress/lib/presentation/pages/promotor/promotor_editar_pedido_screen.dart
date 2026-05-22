import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/api_config.dart';

class PromotorEditarPedidoScreen extends StatefulWidget {
  final PedidoModel pedido;

  const PromotorEditarPedidoScreen({required this.pedido, super.key});

  @override
  State<PromotorEditarPedidoScreen> createState() => _PromotorEditarPedidoScreenState();
}

class _PromotorEditarPedidoScreenState extends State<PromotorEditarPedidoScreen> {
  late List<ItemPedido> items;
  late List<ProductoModel> productosDisponibles;
  String _searchQuery = '';
  bool _isLoading = false;
  final fmt = NumberFormat('#,###', 'es_CO');
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    // Copiar items para poder editarlos
    items = widget.pedido.items.map((item) {
      return ItemPedido(
        producto: item.producto,
        cantidad: item.cantidad,
      );
    }).toList();
    
    // Obtener productos disponibles
    final state = context.read<AppState>();
    productosDisponibles = state.productos;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get iva => subtotal * 0.19;
  double get total => subtotal + iva;

  List<ProductoModel> get productosFilterados {
    if (_searchQuery.isEmpty) return productosDisponibles;
    return productosDisponibles
        .where((p) => p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _agregarProducto(ProductoModel producto) {
    setState(() {
      final indexExistente = items.indexWhere((i) => i.producto.id == producto.id);
      if (indexExistente >= 0) {
        items[indexExistente].cantidad++;
      } else {
        items.add(ItemPedido(producto: producto, cantidad: 1));
      }
    });
  }

  void _eliminarProducto(int index) {
    setState(() => items.removeAt(index));
  }

  void _cambiarCantidad(int index, int cantidad) {
    if (cantidad <= 0) {
      _eliminarProducto(index);
    } else {
      setState(() => items[index].cantidad = cantidad);
    }
  }

  Future<void> _guardarCambios() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El pedido debe tener al menos un producto')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final state = context.read<AppState>();
      
      // Actualizar el pedido con los nuevos items y la hora actual
      widget.pedido.items = items;
      widget.pedido.fechaModificacion = DateTime.now();
      
      // Preparar datos para enviar al backend
      final itemsData = items.map((item) => {
        'producto_id': item.producto.id,
        'cantidad': item.cantidad,
      }).toList();

      // Intentar sincronizar con el backend (pero no bloquear si falla)
      try {
        final dio = state.getDio();
        await dio.patch(
          '${ApiConfig.pedidos}/${widget.pedido.id}',
          data: { 'items': itemsData },
        );
        // ✅ Sincronización exitosa - refrescar desde el servidor
        await state.fetchPedidos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido guardado y sincronizado ✓')),
          );
        }
      } catch (e) {
        // Si es un pedido local (404), solo guardamos localmente
        if (e.toString().contains('404')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cambios guardados localmente (pedido de prueba)'),
              ),
            );
          }
        } else {
          // Para otros errores, mostrar el error pero no bloquear
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cambios guardados localmente. Sync: ${e.toString()}')),
            );
          }
        }
      }
      
      // Notificar cambios para que se actualice la UI
      state.notifyListeners();
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Pedido',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Cliente info
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.store_rounded, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.pedido.cliente.nombre,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        Text(widget.pedido.cliente.zona,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1, color: AppTheme.border)),

              // Search bar
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Items actuales del pedido
              if (items.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Items del Pedido',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ItemPedidoCard(
                        key: ValueKey(items[i].producto.id),
                        item: items[i],
                        fmt: fmt,
                        onCantidadChanged: (cantidad) => _cambiarCantidad(i, cantidad),
                        onEliminar: () => _eliminarProducto(i),
                      ),
                      childCount: items.length,
                    ),
                  ),
                ),
              ],

              // Grid de productos disponibles
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Agregar Productos',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final producto = productosFilterados[index];
                      final estaEnPedido = items.any((i) => i.producto.id == producto.id);
                      
                      return _ProductoCard(
                        producto: producto,
                        estaEnPedido: estaEnPedido,
                        onAgregar: () => _agregarProducto(producto),
                      );
                    },
                    childCount: productosFilterados.length,
                  ),
                ),
              ),

              // Totales
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(children: [
                    _FilaTotal(label: 'Subtotal:', value: '\$${fmt.format(subtotal)}'),
                    const SizedBox(height: 8),
                    _FilaTotal(label: 'IVA 19%:', value: '\$${fmt.format(iva)}'),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 12),
                    _FilaTotal(
                      label: 'Total:',
                      value: '\$${fmt.format(total)}',
                      bold: true,
                      valueColor: AppTheme.success,
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Botón guardar
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Producto Card ──────────────────────────────────────────────────────────────

class _ProductoCard extends StatelessWidget {
  final ProductoModel producto;
  final bool estaEnPedido;
  final VoidCallback onAgregar;

  const _ProductoCard({
    required this.producto,
    required this.estaEnPedido,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_CO');
    
    return GestureDetector(
      onTap: onAgregar,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: estaEnPedido ? AppTheme.primary : AppTheme.border,
            width: estaEnPedido ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: producto.imagen != null && producto.imagen!.isNotEmpty
                    ? Image.network(
                        producto.imagen!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _ImagePlaceholder(nombre: producto.nombre),
                      )
                    : _ImagePlaceholder(nombre: producto.nombre),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${fmt.format(producto.precio)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                        if (estaEnPedido)
                          const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image Placeholder ──────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  final String nombre;

  const _ImagePlaceholder({required this.nombre});

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.primaryLight,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_outlined, color: AppTheme.primary, size: 32),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Item Card ──────────────────────────────────────────────────────────────────

class _ItemPedidoCard extends StatelessWidget {
  final ItemPedido item;
  final NumberFormat fmt;
  final Function(int) onCantidadChanged;
  final VoidCallback onEliminar;

  const _ItemPedidoCard({
    required Key key,
    required this.item,
    required this.fmt,
    required this.onCantidadChanged,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${fmt.format(item.producto.precio)} c/u',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cantidad
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => onCantidadChanged(item.cantidad - 1),
                  icon: const Icon(Icons.remove, size: 16),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.cantidad}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => onCantidadChanged(item.cantidad + 1),
                  icon: const Icon(Icons.add, size: 16),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Subtotal
          Text(
            '\$${fmt.format(item.subtotal)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 8),
          // Eliminar
          IconButton(
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _FilaTotal({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(
            fontSize: bold ? 13 : 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: AppTheme.textSecondary,
          )),
      Text(value,
          style: TextStyle(
            fontSize: bold ? 14 : 11,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimary,
          )),
    ],
  );
}

