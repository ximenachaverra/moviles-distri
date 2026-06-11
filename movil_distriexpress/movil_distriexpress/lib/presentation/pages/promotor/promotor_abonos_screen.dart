import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/common_widgets.dart';

class PromotorAbonosScreen extends StatefulWidget {
  final ClienteModel? preselectedCliente;
  final bool fromDelivery;
  final String? fixedPedidoId;
  final VoidCallback? onAbonoRegistered;

  const PromotorAbonosScreen({
    super.key,
    this.preselectedCliente,
    this.fromDelivery = false,
    this.fixedPedidoId,
    this.onAbonoRegistered,
  });

  @override
  State<PromotorAbonosScreen> createState() => _PromotorAbonosScreenState();
}

class _PromotorAbonosScreenState extends State<PromotorAbonosScreen> {
  String? _selectedClienteId;
  String? _selectedPedidoId; // Nuevo: para seleccionar pedido específico
  final _montoController = TextEditingController();
  final _obsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final fmt = NumberFormat('#,###', 'es_CO');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedClienteId = widget.preselectedCliente?.id;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  PedidoModel? _pedidoFijo(AppState state) {
    if (widget.fixedPedidoId == null) return null;
    try {
      return state.pedidos.firstWhere((p) => p.id == widget.fixedPedidoId);
    } catch (_) {
      return null;
    }
  }

  double _saldoPermitido(AppState state, ClienteModel selectedCliente) {
    // Si hay un pedido seleccionado, usa el saldo del pedido
    if (_selectedPedidoId != null) {
      try {
        final pedido = state.pedidos.firstWhere((p) => p.id == _selectedPedidoId);
        return pedido.saldoPendiente;
      } catch (_) {
        // Si no encuentra el pedido, falla silenciosamente
      }
    }
    final pedido = _pedidoFijo(state);
    if (pedido != null) return pedido.saldoPendiente;
    final pedidos = state.pedidosPorCliente(selectedCliente.id);
    return pedidos.fold(0.0, (s, p) => s + p.saldoPendiente);
  }

  Future<void> _registrarAbono() async {
    final state = context.read<AppState>();
    final selectedCliente = _selectedCliente(state);

    if (!_formKey.currentState!.validate() || selectedCliente == null) {
      if (selectedCliente == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un cliente'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final monto = double.parse(
        _montoController.text.replaceAll('.', '').replaceAll(',', ''));

    final saldoPendiente = _saldoPermitido(state, selectedCliente);
    if (monto > saldoPendiente + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El abono supera el saldo pendiente (\$${fmt.format(saldoPendiente)})'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final pedidoFijo = _pedidoFijo(state);
    // Si hay un pedido seleccionado en el dropdown, usar ese
    if (_selectedPedidoId != null && _selectedPedidoId!.isNotEmpty) {
      try {
        final pedidoSeleccionado =
            state.pedidos.firstWhere((p) => p.id == _selectedPedidoId);
        await state.agregarAbonoPedido(
          pedidoSeleccionado.id,
          AbonoPedido(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            monto: monto,
            tipo: 'Efectivo',
            fecha: DateTime.now(),
          ),
        );
      } catch (e) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar abono: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    } else if (pedidoFijo != null) {
      try {
        await state.agregarAbonoPedido(
          pedidoFijo.id,
          AbonoPedido(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            monto: monto,
            tipo: 'Efectivo',
            fecha: DateTime.now(),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar abono: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    } else {
      try {
        await state.registrarAbono(
          selectedCliente.id,
          selectedCliente.nombre,
          monto,
          _obsController.text.trim().isEmpty
              ? null
              : _obsController.text.trim(),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar abono: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _saving = false;
      _montoController.clear();
      _obsController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Abono de \$${fmt.format(monto)} registrado'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (widget.fromDelivery && widget.onAbonoRegistered != null) {
      widget.onAbonoRegistered!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedCliente = _selectedCliente(state);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Módulo de abonos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.promotorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payments_outlined,
                color: AppTheme.promotorColor, size: 20),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Formulario nuevo abono ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.promotorColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_card_rounded,
                                color: AppTheme.promotorColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Registrar Abono',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Selector de cliente
                      const Text(
                        'Cliente',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      if (widget.fromDelivery && widget.preselectedCliente != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.store_rounded, color: AppTheme.promotorColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.preselectedCliente!.nombre,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary, size: 18),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ClienteModel>(
                              value: selectedCliente,
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Seleccionar cliente',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14)),
                              ),
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              borderRadius: BorderRadius.circular(12),
                              items: state.clientes
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.store_rounded,
                                              size: 16,
                                              color: AppTheme.textSecondary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(c.nombre,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                if (state.calcularSaldoPendienteCliente(c.id) > 0)
                                                  Text(
                                                    'Saldo: \$${fmt.format(state.calcularSaldoPendienteCliente(c.id))}',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme.warning),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (c) {
                                setState(() {
                                  _selectedClienteId = c?.id;
                                  _selectedPedidoId = null; // Reset pedido al cambiar cliente
                                });
                              },
                            ),
                          ),
                        ),

                      // Selector de pedido (solo si hay múltiples pedidos)
                      if (selectedCliente != null) ...[
                        const SizedBox(height: 16),
                        Builder(builder: (context) {
                          var pedidosDelCliente = state
                              .pedidosPorCliente(selectedCliente.id)
                              .where((p) => p.saldoPendiente > 0.01)
                              .toList();
                          
                          // Eliminar duplicados por ID
                          final pedidosUnicos = <String, PedidoModel>{};
                          for (var p in pedidosDelCliente) {
                            pedidosUnicos[p.id] = p;
                          }
                          pedidosDelCliente = pedidosUnicos.values.toList();
                          
                          // Validar que el pedido seleccionado siga siendo válido
                          if (_selectedPedidoId != null &&
                              !pedidosDelCliente.any((p) => p.id == _selectedPedidoId)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _selectedPedidoId = null);
                            });
                          }
                          if (pedidosDelCliente.length > 1) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selecciona un pedido (opcional)',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPedidoId,
                                      hint: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                            'Sin pedido específico',
                                            style: TextStyle(
                                                color:
                                                    AppTheme.textSecondary,
                                                fontSize: 14)),
                                      ),
                                      isExpanded: true,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      items: pedidosDelCliente
                                          .map(
                                            (p) => DropdownMenuItem(
                                              value: p.id,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .receipt_long_rounded,
                                                      size: 16,
                                                      color: AppTheme
                                                          .textSecondary),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Pedido #${p.id.length > 6 ? p.id.substring(p.id.length - 6) : p.id}',
                                                          style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Text(
                                                          'Total: \$${fmt.format(p.total)} | Saldo: \$${fmt.format(p.saldoPendiente)}',
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppTheme
                                                                  .textSecondary),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (p) =>
                                          setState(() =>
                                              _selectedPedidoId = p),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],

                        // Saldo pendiente del cliente/pedido
                        if (selectedCliente != null &&
                          _saldoPermitido(state, selectedCliente) > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppTheme.warning, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Saldo pendiente: \$${fmt.format(_saldoPermitido(state, selectedCliente))}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Campo monto
                      const Text(
                        'Monto del abono',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _montoController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                          hintText: '0',
                          hintStyle: TextStyle(
                              fontSize: 22, color: AppTheme.textSecondary),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa el monto del abono';
                          }
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) {
                            return 'Ingresa un monto válido';
                          }
                          if (selectedCliente != null) {
                            final saldoPendiente = _saldoPermitido(state, selectedCliente);
                            if (n > saldoPendiente + 0.01) {
                              return 'El monto supera el saldo pendiente (\$${fmt.format(saldoPendiente)})';
                            }
                          }
                          return null;
                        },
                        onChanged: (v) => setState(() {}),
                      ),

                      // Preview saldo restante
                      if (selectedCliente != null &&
                          _montoController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final ingresado =
                              double.tryParse(_montoController.text) ?? 0;
                          final restante = (_saldoPermitido(state, selectedCliente) -
                                  ingresado)
                              .clamp(0, double.infinity);
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Saldo restante:',
                                    style: TextStyle(
                                        fontSize: 13, color: AppTheme.success)),
                                Text(
                                  '\$${fmt.format(restante)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.success),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),

                      // Observación
                      const Text(
                        'Observación (opcional)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _obsController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Ej: Abono parcial, acuerdo de pago...',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _registrarAbono,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Registrar abono'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.promotorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Historial de abonos ────────────────────────────────────
              const SectionHeader(title: 'HISTORIAL DE ABONOS'),
              const SizedBox(height: 12),

              Builder(builder: (context) {
                List<dynamic> abonosFiltrados = [];

                // Si hay un pedido específico seleccionado
                if (_selectedPedidoId != null && _selectedPedidoId!.isNotEmpty) {
                  try {
                    final pedido = state.pedidos.firstWhere((p) => p.id == _selectedPedidoId);
                    // Mostrar los abonos del pedido específico
                    abonosFiltrados = pedido.abonosPedido;
                  } catch (_) {
                    // Si no encuentra el pedido, lista vacía
                  }
                } else if (_selectedClienteId != null) {
                  // Si hay un cliente seleccionado, mostrar sus abonos generales
                  abonosFiltrados = state.abonos
                      .where((a) => a.clienteId == _selectedClienteId)
                      .toList();
                } else {
                  // Sin filtro, mostrar todos los abonos
                  abonosFiltrados = state.abonos;
                }

                if (abonosFiltrados.isEmpty)
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.payments_outlined,
                              size: 48,
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay abonos registrados',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );

                // Si son AbonoPedido (del pedido específico), mostrar con _AbonoPedidoTile
                if (abonosFiltrados.isNotEmpty && abonosFiltrados.first is AbonoPedido) {
                  return Column(
                    children: abonosFiltrados
                        .map((abono) => _AbonoPedidoTile(abono: abono as AbonoPedido))
                        .toList(),
                  );
                }

                // Si son AbonoModel (abonos generales), mostrar con _AbonoTile
                return Column(
                  children: abonosFiltrados
                      .map((abono) => _AbonoTile(abono: abono as AbonoModel))
                      .toList(),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  ClienteModel? _selectedCliente(AppState state) {
    if (_selectedClienteId == null) return null;
    final matches = state.clientes.where((c) => c.id == _selectedClienteId);
    return matches.isEmpty ? null : matches.first;
  }
}

// ── Tile de abono en el historial ────────────────────────────────────────────

class _AbonoTile extends StatelessWidget {
  final AbonoModel abono;
  const _AbonoTile({required this.abono});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_CO');
    final dateFmt = DateFormat('dd MMM, HH:mm', 'es_CO');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(abono.clienteNombre,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (abono.pedidoId != null)
                  Text('Pedido #${abono.pedidoId!.length > 6 ? abono.pedidoId!.substring(abono.pedidoId!.length - 6) : abono.pedidoId}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                if (abono.observacion != null && abono.observacion!.isNotEmpty)
                  Text(abono.observacion!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                Text(
                  dateFmt.format(abono.fecha),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+\$${fmt.format(abono.monto)}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.success),
          ),
        ],
      ),
    );
  }
}

// ── Tile de abono de pedido en el historial ─────────────────────────────────

class _AbonoPedidoTile extends StatelessWidget {
  final AbonoPedido abono;
  const _AbonoPedidoTile({required this.abono});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_CO');
    final dateFmt = DateFormat('dd MMM, HH:mm', 'es_CO');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abono a Pedido',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  abono.tipo,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  dateFmt.format(abono.fecha),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+\$${fmt.format(abono.monto)}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.success),
          ),
        ],
      ),
    );
  }
}