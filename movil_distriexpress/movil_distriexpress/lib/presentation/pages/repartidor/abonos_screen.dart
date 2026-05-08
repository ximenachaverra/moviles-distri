import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/common_widgets.dart';

class AbonosScreen extends StatefulWidget {
  final ClienteModel? preselectedCliente;
  final bool fromDelivery;
  final VoidCallback? onAbonoRegistered;

  const AbonosScreen({
    super.key,
    this.preselectedCliente,
    this.fromDelivery = false,
    this.onAbonoRegistered,
  });

  @override
  State<AbonosScreen> createState() => _AbonosScreenState();
}

class _AbonosScreenState extends State<AbonosScreen> {
  String? _selectedClienteId;
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

    // Validación adicional: el monto no puede exceder el saldo pendiente
    final saldoPendiente = state.calcularSaldoPendienteCliente(selectedCliente.id);
    if (monto > saldoPendiente + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El abono supera el saldo pendiente de \$${fmt.format(saldoPendiente)}'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await context.read<AppState>().registrarAbono(
          selectedCliente.id,
          selectedCliente.nombre,
          monto,
          _obsController.text.trim().isEmpty ? null : _obsController.text.trim(),
        );

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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Si viene desde entrega, ejecutar callback y volver
    if (widget.fromDelivery && widget.onAbonoRegistered != null) {
      await Future.delayed(const Duration(milliseconds: 500));
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
        title: const Text('MÃ³dulo de Abonos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.repartidorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payments_outlined,
                color: AppTheme.repartidorColor, size: 20),
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
              // Nuevo abono form
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
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.repartidorColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_card_rounded,
                                color: AppTheme.repartidorColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Registrar Abono',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Cliente selector
                      const Text(
                        'Cliente',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.fromDelivery && widget.preselectedCliente != null)
                        // Mostrar cliente bloqueado si viene desde entrega
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.repartidorColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.store_rounded, color: AppTheme.repartidorColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.preselectedCliente!.nombre,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                    ),
                                    if (state.calcularSaldoPendienteCliente(widget.preselectedCliente!.id) > 0)
                                      Text(
                                        'Saldo: \$${fmt.format(state.calcularSaldoPendienteCliente(widget.preselectedCliente!.id))}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.warning),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary, size: 18),
                            ],
                          ),
                        )
                      else
                        // Dropdown normal si no viene desde entrega
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
                              onChanged: (c) => setState(() {
                                _selectedClienteId = c?.id;
                              }),
                            ),
                          ),
                        ),
                      // Saldo info
                      if (selectedCliente != null &&
                          state.calcularSaldoPendienteCliente(selectedCliente.id) > 0) ...[
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
                                'Saldo pendiente: \$${fmt.format(state.calcularSaldoPendienteCliente(selectedCliente.id))}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Monto field
                      const Text(
                        'Monto del abono',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
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
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 22,
                            color: AppTheme.textSecondary,
                          ),
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
                            final saldoPendiente = state.calcularSaldoPendienteCliente(selectedCliente.id);
                            if (n > saldoPendiente + 0.01) {
                              return 'El monto supera el saldo pendiente (\$${fmt.format(saldoPendiente)})';
                            }
                          }
                          return null;
                        },
                        onChanged: (v) => setState(() {}),
                      ),
                      // Saldo restante preview
                        if (selectedCliente != null &&
                          _montoController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final ingresado =
                              double.tryParse(_montoController.text) ?? 0;
                          final restante = (selectedCliente.saldoPendiente -
                              ingresado)
                              .clamp(0, double.infinity);
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Saldo restante:',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.success)),
                                Text(
                                  '\$${fmt.format(restante)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      // ObservaciÃ³n
                      const Text(
                        'ObservaciÃ³n (opcional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
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
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _registrarAbono,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Registrar abono'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.repartidorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Historial de abonos
              const SectionHeader(title: 'HISTORIAL DE ABONOS'),
              const SizedBox(height: 12),
              if (state.abonos.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 48,
                            color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay abonos registrados',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...state.abonos.map((abono) => _AbonoTile(abono: abono)),
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
                if (abono.observacion != null)
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
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}
