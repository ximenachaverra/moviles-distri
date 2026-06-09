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
import 'promotor_abonos_screen.dart';
import 'promotor_pedidos_screen.dart';

class PromotorDetalleScreen extends StatefulWidget {
  final ClienteModel cliente;

  const PromotorDetalleScreen({super.key, required this.cliente});

  @override
  State<PromotorDetalleScreen> createState() => _PromotorDetalleScreenState();
}

class _PromotorDetalleScreenState extends State<PromotorDetalleScreen> {
  Map<String, dynamic>? _pedidoEnProgreso;

  Future<void> _abrirRuta(BuildContext context) async {
    if (widget.cliente.lat == 0 && widget.cliente.lng == 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coordenadas no disponibles')));
      }
      return;
    }
    final destino = '${widget.cliente.lat},${widget.cliente.lng}';
    const origen = '6.1846,-75.5994';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origen&destination=$destino&travelmode=driving',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  void _abrirCrearPedido() async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPedidoScreen(cliente: widget.cliente),
      ),
    );
    if (resultado != null && mounted) {
      setState(() => _pedidoEnProgreso = resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pedidos = state.pedidosPorCliente(widget.cliente.id);
    final abonosHistorial = state.abonosPorCliente(widget.cliente.id);
    final fmt = NumberFormat('#,###', 'es_CO');

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
                  Row(
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
                      const Spacer(),
                      PointerInterceptor(
                        child: OutlinedButton.icon(
                          onPressed: _abrirCrearPedido,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Crear pedido'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.textPrimary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Stack(
                      children: [
                        // Si no hay coordenadas válidas (0,0) mostramos un placeholder
                        if (widget.cliente.lat == 0 && widget.cliente.lng == 0)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.location_off_outlined,
                                    size: 36, color: AppTheme.textSecondary),
                                SizedBox(height: 8),
                                Text('Ubicación no disponible',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(widget.cliente.lat, widget.cliente.lng),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('cliente'),
                                  position: LatLng(widget.cliente.lat, widget.cliente.lng),
                                  infoWindow: InfoWindow(title: widget.cliente.nombre),
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
                              onTap: () => _abrirRuta(context),
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
                                  color: AppTheme.promotorColor,
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
                  const SizedBox(height: 20),
                  if (pedidos.isNotEmpty) ...[
                    const SectionHeader(title: 'PEDIDOS RECIENTES'),
                    const SizedBox(height: 12),
                    if (state.currentUser!.rol == UserRole.promotor)
                      _PedidoCard(pedido: pedidos.first, fmt: fmt)
                    else
                      ...pedidos.map((p) => _PedidoCard(pedido: p, fmt: fmt)),
                  ] else if (_pedidoEnProgreso != null) ...[
                    const SectionHeader(title: 'PEDIDO EN PROGRESO'),
                    const SizedBox(height: 12),
                    _ResumenPedidoEnProgreso(
                      pedido: _pedidoEnProgreso!,
                      fmt: fmt,
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 40,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Sin pedidos aun',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toca "Crear pedido" para comenzar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (abonosHistorial.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const SectionHeader(title: 'HISTORIAL DE ABONOS'),
                    const SizedBox(height: 10),
                    ...abonosHistorial.map(
                      (a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${fmt.format(a.monto)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                      'es_CO',
                                    ).format(a.fecha),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  if ((a.observacion ?? '').isNotEmpty)
                                    Text(
                                      a.observacion!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
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
              child: SizedBox(
                width: double.infinity,
                child: Consumer<AppState>(
                  builder: (context, appState, _) {
                    final clienteActualizado = appState.clientes.firstWhere(
                      (c) => c.id == widget.cliente.id,
                      orElse: () => widget.cliente,
                    );
                    final esAtendido = clienteActualizado.estado == EstadoCliente.atendido;
                    
                    return ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await appState.toggleAtendidoCliente(
                            widget.cliente.id,
                            !esAtendido,
                          );

                          if (!context.mounted) return;

                          if (!esAtendido) {
                            // Se marcó como atendido → preguntar si recibió abono
                            final recibeAbono = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(Icons.payments_outlined,
                                        color: AppTheme.promotorColor),
                                    SizedBox(width: 10),
                                    Text('¿Recibiste un abono?'),
                                  ],
                                ),
                                content: Text(
                                  '¿${widget.cliente.nombre} realizó algún pago hoy?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.promotorColor,
                                    ),
                                    child: const Text('Sí, registrar'),
                                  ),
                                ],
                              ),
                            );

                            if (!context.mounted) return;

                            if (recibeAbono == true) {
                              // Ir a abonos con cliente preseleccionado y bloqueado
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PromotorAbonosScreen(
                                    preselectedCliente: widget.cliente,
                                    fromDelivery: true,
                                  ),
                                ),
                              );
                            } else {
                              // Sin abono → volver al home (que navegará a pedidos)
                              Navigator.pop(context, 'atendido');
                            }
                          } else {
                            // Se desmarcó como pendiente
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${widget.cliente.nombre} marcado como pendiente'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al actualizar estado: $e'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        esAtendido ? Icons.check_circle : Icons.check_rounded,
                        size: 18,
                      ),
                      label: Text(esAtendido ? 'Atendido ✓' : 'ATENDIDO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esAtendido
                            ? AppTheme.success
                            : AppTheme.promotorColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoModel pedido;
  final NumberFormat fmt;

  const _PedidoCard({required this.pedido, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ...pedido.items.map(
            (item) => ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
              title: Text(
                item.producto.nombre,
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                '\$${fmt.format(item.producto.precio)} c/u',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                'Cnt ${item.cantidad}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.promotorColor,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy', 'es_CO').format(pedido.fecha),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: \$${fmt.format(pedido.total)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (pedido.totalAbonado > 0)
                          Text(
                            'Abonado: \$${fmt.format(pedido.totalAbonado)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.success,
                            ),
                          ),
                        if (pedido.saldoPendiente > 0)
                          Text(
                            'Pendiente: \$${fmt.format(pedido.saldoPendiente)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget para mostrar resumen del pedido en progreso ────────────────────
class _ResumenPedidoEnProgreso extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final NumberFormat fmt;

  const _ResumenPedidoEnProgreso({
    required this.pedido,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final productos = (pedido['productos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = (pedido['total'] as num?)?.toDouble() ?? 0.0;
    final abonado = (pedido['abonado'] as num?)?.toDouble() ?? 0.0;
    final saldo = (pedido['saldo'] as num?)?.toDouble() ?? 0.0;
    final abonos = (pedido['abonos'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Mostrar máximo 3 productos
    final productosAMostrar = productos.take(3).toList();
    final hayMas = productos.length > 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Productos
          ...productosAMostrar.asMap().entries.map((e) {
            final idx = e.key;
            final p = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: idx < productosAMostrar.length - 1 ? 8 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p['nombre'] ?? 'Producto'} x${p['cantidad'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${fmt.format(((p['precio'] as num?)?.toInt() ?? 0) * ((p['cantidad'] as num?)?.toInt() ?? 1))}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (hayMas)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+ ${productos.length - 3} más',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Total y Abonos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: \$${fmt.format(total.toInt())}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (abonado > 0)
                    Text(
                      'Abonado: \$${fmt.format(abonado.toInt())}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.success,
                      ),
                    ),
                  if (saldo > 0)
                    Text(
                      'Saldo: \$${fmt.format(saldo.toInt())}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              // Mostrar abonos si existen
              if (abonos.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ...abonos.take(2).map((a) => Text(
                      '${a['tipo'] ?? 'Abono'}: \$${fmt.format((a['monto'] as num?)?.toInt() ?? 0)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.success,
                      ),
                    )),
                    if (abonos.length > 2)
                      Text(
                        '+ ${abonos.length - 2} abono(s)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
