import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/common_widgets.dart';
import 'abonos_screen.dart';

class RepartidorDetalleScreen extends StatefulWidget {
  final ClienteModel cliente;
  const RepartidorDetalleScreen({super.key, required this.cliente});

  @override
  State<RepartidorDetalleScreen> createState() =>
      _RepartidorDetalleScreenState();
}

class _RepartidorDetalleScreenState extends State<RepartidorDetalleScreen> {
  final fmt = NumberFormat('#,###', 'es_CO');

  Future<void> _abrirRuta() async {
    if (widget.cliente.lat == 0 && widget.cliente.lng == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordenadas no disponibles')));
      }
      return;
    }
    final destino = '${widget.cliente.lat},${widget.cliente.lng}';
    const origen = '6.1846,-75.5994';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origen&destination=$destino&travelmode=driving',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  void _marcarEntregado() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Recibió abono?'),
        content: Text('${widget.cliente.nombre} - ¿Realizó algún pago o abono?'),
        actions: [
          TextButton(
            onPressed: () async {
              // No recibió abono, marcar todos los pedidos como atendidos
              final state = context.read<AppState>();
              final pedidos = state.pedidosPorCliente(widget.cliente.id);
              
              try {
                // Marcar cada pedido como atendido (actualizar estado_asignacion)
                for (final pedido in pedidos) {
                  await state.marcarPedidoAtendido(pedido.id);
                }
                
                // Luego cambiar estado del cliente
                await state.cambiarEstadoCliente(widget.cliente.id, EstadoCliente.atendido);
                
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Entrega confirmada: ${widget.cliente.nombre}'), backgroundColor: AppTheme.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al marcar entrega: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Ir a pantalla de abonos con cliente preseleccionado
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AbonosScreen(
                    preselectedCliente: widget.cliente,
                    fromDelivery: true,
                    onAbonoRegistered: () async {
                      // Marcar todos los pedidos como atendidos después de registrar abono
                      final state = context.read<AppState>();
                      final pedidos = state.pedidosPorCliente(widget.cliente.id);
                      
                      try {
                        for (final pedido in pedidos) {
                          await state.marcarPedidoAtendido(pedido.id);
                        }
                        await state.cambiarEstadoCliente(widget.cliente.id, EstadoCliente.atendido);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Abono registrado. Entrega completada: ${widget.cliente.nombre}'), backgroundColor: AppTheme.success),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al marcar entrega: $e'), backgroundColor: AppTheme.error),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.repartidorColor),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _verDetallePedido(PedidoModel pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PedidoDetalleModal(pedido: pedido, fmt: fmt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pedidos = state.pedidosPorCliente(widget.cliente.id);
    final totalAbonos = pedidos.fold(0.0, (s, p) => s + p.totalAbonado);
    final pedidoPrincipal = pedidos.isNotEmpty ? pedidos.first : null;
    
    // Obtener el cliente actualizado del estado (no usar widget.cliente que es estático)
    final clienteActualizado = state.clientes.firstWhere(
      (c) => c.id == widget.cliente.id,
      orElse: () => widget.cliente,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(state.currentUser!.nombreCompleto),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RUTA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Card cliente
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            color: AppTheme.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cliente.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                widget.cliente.zona,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                widget.cliente.direccion,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.cliente.saldoPendiente > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Debe',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.warning,
                                  ),
                                ),
                                Text(
                                  '\$${fmt.format(widget.cliente.saldoPendiente)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mapa
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Stack(
                      children: [
                        // Mostrar placeholder si no hay coordenadas válidas
                        if (widget.cliente.lat == 0 && widget.cliente.lng == 0)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.location_off_outlined, size: 36, color: AppTheme.textSecondary),
                                SizedBox(height: 8),
                                Text('Ubicación no disponible', style: TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  widget.cliente.lat,
                                  widget.cliente.lng,
                                ),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('cliente'),
                                  position: LatLng(
                                    widget.cliente.lat,
                                    widget.cliente.lng,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: widget.cliente.nombre,
                                  ),
                                ),
                              },
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              myLocationButtonEnabled: false,
                              myLocationEnabled: false,
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _abrirRuta,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.alt_route_rounded,
                                      size: 14,
                                      color: AppTheme.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Como llegar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppTheme.error,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.cliente.direccion,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (pedidoPrincipal != null) ...[
                    const SectionHeader(title: 'PEDIDO'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _EstadoBadge(estado: pedidoPrincipal.estado),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy – HH:mm',
                                    'es_CO',
                                  ).format(pedidoPrincipal.fecha),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.border),
                          ...pedidoPrincipal.items
                              .take(3)
                              .map(
                                (item) => ListTile(
                                  dense: true,
                                  title: Text(
                                    item.producto.nombre,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: Text(
                                    'Cnt ${item.cantidad}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          if (pedidoPrincipal.items.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                bottom: 6,
                              ),
                              child: Text(
                                '+${pedidoPrincipal.items.length - 3} productos más',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          const Divider(height: 1, color: AppTheme.border),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Abonado: \$${fmt.format(pedidoPrincipal.totalAbonado)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Pendiente: \$${fmt.format(pedidoPrincipal.saldoPendiente)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Total: \$${fmt.format(pedidoPrincipal.total)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (totalAbonos > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total abonado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.success,
                                ),
                              ),
                              Text(
                                '\$${fmt.format(totalAbonos)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          PointerInterceptor(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (pedidoPrincipal != null) {
                          _verDetallePedido(pedidoPrincipal);
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Este cliente no tiene pedido registrado',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Ver pedido'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (clienteActualizado.estado != EstadoCliente.atendido) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _marcarEntregado,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Entregado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.repartidorColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal detalle pedido ──────────────────────────────────────────────────────

class _PedidoDetalleModal extends StatelessWidget {
  final PedidoModel pedido;
  final NumberFormat fmt;
  const _PedidoDetalleModal({required this.pedido, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalle del Pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 4),
                  // Estado + abonado/pendiente
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EstadoBadge(estado: pedido.estado),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Abonado: \$${fmt.format(pedido.totalAbonado)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pendiente: \$${fmt.format(pedido.saldoPendiente)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoField(
                            label: 'Cliente',
                            value: pedido.cliente.nombre,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoField(
                            label: 'F. Pedido',
                            value: DateFormat(
                              'dd/MM/yyyy',
                              'es_CO',
                            ).format(pedido.fecha),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoField(
                            label: 'Hora',
                            value: DateFormat(
                              'HH:mm',
                              'es_CO',
                            ).format(pedido.fecha),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tabla productos
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(11),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Producto',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Cant.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'V. Uni',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Vl. Total',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.border),
                        ...pedido.items.map(
                          (item) => Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        item.producto.nombre,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${item.cantidad}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '\$${fmt.format(item.producto.precio)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '\$${fmt.format(item.subtotal)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: AppTheme.border),
                            ],
                          ),
                        ),
                        _TotalRow(
                          label: 'Subtotal',
                          value: '\$${fmt.format(pedido.subtotal)}',
                          light: true,
                        ),
                        _TotalRow(
                          label: 'IVA 19%',
                          value: '\$${fmt.format(pedido.iva)}',
                          light: true,
                        ),
                        _TotalRow(
                          label: 'Total:',
                          value: '\$${fmt.format(pedido.total)}',
                          bold: true,
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool light;
  final bool bold;
  final Color? color;
  const _TotalRow({
    required this.label,
    required this.value,
    this.light = false,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: bold ? 12 : 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _EstadoBadge extends StatelessWidget {
  final EstadoPedido estado;
  const _EstadoBadge({required this.estado});

  Color get _color {
    switch (estado) {
      case EstadoPedido.pendiente:
        return AppTheme.warning;
      case EstadoPedido.enProceso:
        return AppTheme.primary;
      case EstadoPedido.pendientePorPago:
        return AppTheme.accentOrange;
      case EstadoPedido.pagado:
        return AppTheme.success;
      case EstadoPedido.anulado:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color.withValues(alpha: 0.3)),
    ),
    child: Text(
      estado.label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _color,
      ),
    ),
  );
}
