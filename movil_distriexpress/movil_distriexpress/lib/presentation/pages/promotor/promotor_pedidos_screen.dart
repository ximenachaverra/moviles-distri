import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/common_widgets.dart';
import 'promotor_detalle_screen.dart';
import 'promotor_editar_pedido_screen.dart';
import 'promotor_abonos_screen.dart';

class PromotorPedidosScreen extends StatefulWidget {
  const PromotorPedidosScreen({super.key});

  @override
  State<PromotorPedidosScreen> createState() => _PromotorPedidosScreenState();
}

class _PromotorPedidosScreenState extends State<PromotorPedidosScreen> {
  final fmt = NumberFormat('#,###', 'es_CO');
  ClienteModel? _clienteSeleccionado;
  final TextEditingController _searchCtrl = TextEditingController();
  
  // Filtros de fecha
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int? _mesFiltro;
  int? _anoFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.productos.isEmpty) state.fetchProductos();
    });
  }

  bool _pedidoMatchesFiltros(PedidoModel pedido) {
    // Filtro por fecha específica
    if (_fechaInicio != null) {
      final pedidoDate = DateTime(pedido.fecha.year, pedido.fecha.month, pedido.fecha.day);
      final filterDate = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
      if (pedidoDate.isBefore(filterDate)) return false;
    }
    
    if (_fechaFin != null) {
      final pedidoDate = DateTime(pedido.fecha.year, pedido.fecha.month, pedido.fecha.day);
      final filterDate = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
      if (pedidoDate.isAfter(filterDate)) return false;
    }
    
    // Filtro por mes
    if (_mesFiltro != null && pedido.fecha.month != _mesFiltro) return false;
    
    // Filtro por año
    if (_anoFiltro != null && pedido.fecha.year != _anoFiltro) return false;
    
    return true;
  }

  String _getMonthName(int month) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  void _mostrarDialogoAbonoCliente(ClienteModel cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PromotorAbonosScreen(
          preselectedCliente: cliente,
          fromDelivery: false,
          onAbonoRegistered: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Abono registrado. ${cliente.nombre}'),
                backgroundColor: AppTheme.success,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: isActive ? onClear : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.border,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.primary : AppTheme.textSecondary)),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 12, color: AppTheme.primary),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: isActive ? onClear : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.promotorColor.withValues(alpha: 0.1)
              : AppTheme.border,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive
                  ? AppTheme.promotorColor.withValues(alpha: 0.3)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? AppTheme.promotorColor : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.promotorColor : AppTheme.textSecondary)),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 12, color: AppTheme.promotorColor),
            ]
          ],
        ),
      ),
    );
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un mes'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = _mesFiltro == month;
              return GestureDetector(
                onTap: () {
                  setState(() => _mesFiltro = month);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected ? Colors.transparent : AppTheme.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getMonthName(month),
                    style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un año'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              final year = DateTime.now().year - 4 + index;
              final isSelected = _anoFiltro == year;
              return GestureDetector(
                onTap: () {
                  setState(() => _anoFiltro = year);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected ? Colors.transparent : AppTheme.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    

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
          'Pedidos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ),
      body: _clienteSeleccionado == null
          ? _buildClienteList(state)
          : _buildPedidoDetalle(state, _clienteSeleccionado!),
    );
  }

  Widget _buildClienteList(AppState state) {
    final clientesConPedidos =
        state.clientes.where((c) => state.pedidosPorCliente(c.id).isNotEmpty).toList();

    if (clientesConPedidos.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_rounded, size: 56, color: AppTheme.textSecondary),
          SizedBox(height: 12),
          Text('Sin pedidos registrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          SizedBox(height: 8),
          Text('Los clientes con pedidos aparecerán aquí',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ]),
      );
    }

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(children: [
            _StatMini(
              label: 'Total pedidos',
              value: '${state.pedidos.length}',
              color: AppTheme.promotorColor,
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(width: 10),
            _StatMini(
              label: 'Monto total',
              value: '\$${fmt.format(state.pedidos.fold(0.0, (s, p) => s + p.total))}',
              color: AppTheme.success,
              icon: Icons.attach_money_rounded,
            ),
            const SizedBox(width: 10),
            _StatMini(
              label: 'Pendiente',
              value: '\$${fmt.format(state.pedidos.fold(0.0, (s, p) => s + p.saldoPendiente))}',
              color: AppTheme.error,
              icon: Icons.pending_outlined,
            ),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Buscar clientes, pedidos o zonas...',
            ),
          ),
        ),
      ),
      // Filtros de fecha
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filtro por fecha específica
                _buildDateFilterChip(
                  icon: Icons.calendar_today_rounded,
                  label: _fechaInicio != null
                      ? DateFormat('dd MMM', 'es_CO').format(_fechaInicio!)
                      : 'Desde',
                  isActive: _fechaInicio != null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaInicio ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _fechaInicio = picked);
                    }
                  },
                  onClear: () => setState(() => _fechaInicio = null),
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  icon: Icons.calendar_today_rounded,
                  label: _fechaFin != null
                      ? DateFormat('dd MMM', 'es_CO').format(_fechaFin!)
                      : 'Hasta',
                  isActive: _fechaFin != null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaFin ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _fechaFin = picked);
                    }
                  },
                  onClear: () => setState(() => _fechaFin = null),
                ),
                const SizedBox(width: 8),
                // Filtro por mes
                _buildFilterChip(
                  icon: Icons.date_range_rounded,
                  label: _mesFiltro != null ? _getMonthName(_mesFiltro!) : 'Mes',
                  isActive: _mesFiltro != null,
                  onTap: () => _showMonthPicker(),
                  onClear: () => setState(() => _mesFiltro = null),
                ),
                const SizedBox(width: 8),
                // Filtro por año
                _buildFilterChip(
                  icon: Icons.event_outlined,
                  label: _anoFiltro != null ? _anoFiltro.toString() : 'Año',
                  isActive: _anoFiltro != null,
                  onTap: () => _showYearPicker(),
                  onClear: () => setState(() => _anoFiltro = null),
                ),
                const SizedBox(width: 8),
                // Botón limpiar todos
                if (_fechaInicio != null ||
                    _fechaFin != null ||
                    _mesFiltro != null ||
                    _anoFiltro != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _fechaInicio = null;
                      _fechaFin = null;
                      _mesFiltro = null;
                      _anoFiltro = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.clear_rounded,
                              size: 14, color: AppTheme.error),
                          SizedBox(width: 4),
                          Text('Limpiar',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.error)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final q = _searchCtrl.text.trim().toLowerCase();
              final filtered = clientesConPedidos
                  .where((c) => q.isEmpty
                      ? true
                      : ('${c.nombre} ${c.zona} ${c.direccion}').toLowerCase().contains(q))
                  .toList();
              final c = filtered[index];
              // Filtrar pedidos según criterios de fecha
              final todosPedidos = state.pedidosPorCliente(c.id);
              final pedidos = todosPedidos
                  .where((p) => _pedidoMatchesFiltros(p))
                  .toList();
              
              // Solo mostrar cliente si tiene pedidos después de aplicar filtros
              if (pedidos.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return _ClientePedidoCard(
                cliente: c,
                pedidos: pedidos,
                fmt: fmt,
                onTap: () => setState(() => _clienteSeleccionado = c),
              );
            },
            childCount: clientesConPedidos
                .where((c) => _searchCtrl.text.trim().isEmpty
                    ? true
                    : ('${c.nombre} ${c.zona} ${c.direccion}').toLowerCase().contains(_searchCtrl.text.trim().toLowerCase()))
                .length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }

  Widget _buildPedidoDetalle(AppState state, ClienteModel cliente) {
    final todosPedidos = state.pedidosPorCliente(cliente.id);
    // Aplicar filtros de fecha
    final pedidos = todosPedidos
        .where((p) => _pedidoMatchesFiltros(p))
        .toList();

    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _clienteSeleccionado = null),
        child: Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.store_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cliente.nombre,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(cliente.zona,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${pedidos.length} pedido${pedidos.length != 1 ? "s" : ""}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            PointerInterceptor(
              child: SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoAbonoCliente(cliente),
                  icon: const Icon(Icons.add_card_rounded, size: 14),
                  label: const Text('Abono', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
      const Divider(height: 1, color: AppTheme.border),
      Expanded(
        child: Builder(builder: (_) {
          final isPromotor = state.currentUser?.rol == UserRole.promotor;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: isPromotor ? (pedidos.isNotEmpty ? 1 : 0) : pedidos.length,
            itemBuilder: (_, i) => isPromotor
                ? _PedidoDetalleCard(pedido: pedidos.first, fmt: fmt)
                : _PedidoDetalleCard(pedido: pedidos[i], fmt: fmt),
          );
        }),
      ),
    ]);
  }
}

// ── Card cliente en lista de pedidos ─────────────────────────────────────────

class _ClientePedidoCard extends StatelessWidget {
  final ClienteModel cliente;
  final List<PedidoModel> pedidos;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _ClientePedidoCard({
    required this.cliente, required this.pedidos,
    required this.fmt, required this.onTap,
  });

  Color _estadoColor(EstadoPedido e) {
    switch (e) {
      case EstadoPedido.pendiente:        return AppTheme.warning;
      case EstadoPedido.enProceso:        return AppTheme.primary;
      case EstadoPedido.pendientePorPago: return AppTheme.accentOrange;
      case EstadoPedido.pagado:           return AppTheme.success;
      case EstadoPedido.anulado:          return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastPedido  = pedidos.first;
    final totalGeneral = pedidos.fold(0.0, (s, p) => s + p.total);
    final saldoGeneral = pedidos.fold(0.0, (s, p) => s + p.saldoPendiente);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.store_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cliente.nombre,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text(cliente.zona,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _estadoColor(lastPedido.estado).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _estadoColor(lastPedido.estado).withValues(alpha: 0.3)),
                  ),
                  child: Text(lastPedido.estado.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _estadoColor(lastPedido.estado))),
                ),
                const SizedBox(height: 4),
                Text('${pedidos.length} pedido${pedidos.length != 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ]),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total acumulado', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  Text('\$${fmt.format(totalGeneral)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                ]),
              ),
              if (saldoGeneral > 0)
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    const Text('Pendiente', style: TextStyle(fontSize: 10, color: AppTheme.error)),
                    Text('\$${fmt.format(saldoGeneral)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.error)),
                  ]),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Card detalle de un pedido ─────────────────────────────────────────────────

class _PedidoDetalleCard extends StatelessWidget {
  final PedidoModel pedido;
  final NumberFormat fmt;
  const _PedidoDetalleCard({required this.pedido, required this.fmt});

  Color get _estadoColor {
    switch (pedido.estado) {
      case EstadoPedido.pendiente:        return AppTheme.warning;
      case EstadoPedido.enProceso:        return AppTheme.primary;
      case EstadoPedido.pendientePorPago: return AppTheme.accentOrange;
      case EstadoPedido.pagado:           return AppTheme.success;
      case EstadoPedido.anulado:          return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _estadoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _estadoColor.withValues(alpha: 0.3)),
              ),
              child: Text(pedido.estado.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _estadoColor)),
            ),
            const Spacer(),
            Text('Abonado: \$${fmt.format(pedido.totalAbonado)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.success)),
            const SizedBox(width: 10),
            Text('Pendiente: \$${fmt.format(pedido.saldoPendiente)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.error)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(children: [
              Expanded(child: _InfoField(label: 'Cliente', value: pedido.cliente.nombre)),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoField(
                  label: 'F. Entrega',
                  value: pedido.fechaEntrega != null
                      ? DateFormat('dd/MM/yyyy', 'es_CO').format(pedido.fechaEntrega!)
                      : DateFormat('dd/MM/yyyy', 'es_CO').format(pedido.fecha),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _InfoField(label: 'Hora pedido', value: DateFormat('HH:mm', 'es_CO').format(pedido.fecha.subtract(const Duration(hours: 5))))),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                ),
                child: const Row(children: [
                  Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                  Expanded(child: Text('Cant.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                  Expanded(flex: 2, child: Text('V. Uni', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                  Expanded(flex: 2, child: Text('Vl. Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                ]),
              ),
              const Divider(height: 1, color: AppTheme.border),
              ...pedido.items.map((item) => Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 4, child: Text(item.producto.nombre, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                    Expanded(child: Text('${item.cantidad}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('\$${fmt.format(item.producto.precio)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                    Expanded(flex: 2, child: Text('\$${fmt.format(item.subtotal)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.success))),
                  ]),
                ),
                const Divider(height: 1, color: AppTheme.border),
              ])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  children: [
                    _FilaTotal(label: 'Subtotal:', value: '\$${fmt.format(pedido.subtotal)}'),
                    const SizedBox(height: 4),
                    _FilaTotal(label: 'IVA 19%:', value: '\$${fmt.format(pedido.iva)}'),
                    const SizedBox(height: 6),
                    _FilaTotal(
                      label: 'Total:',
                      value: '\$${fmt.format(pedido.total)}',
                      bold: true,
                      valueColor: AppTheme.success,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        // Botón Editar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PromotorEditarPedidoScreen(pedido: pedido),
                  ),
                ).then((_) {
                  // Después de volver del editor, refrescar los datos del servidor
                  final state = context.read<AppState>();
                  state.fetchPedidos();
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Editar Pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ]),
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
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatMini({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ]),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// CREAR PEDIDO
// ═════════════════════════════════════════════════════════════════════════════

class CrearPedidoScreen extends StatefulWidget {
  final ClienteModel cliente;
  const CrearPedidoScreen({super.key, required this.cliente});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  final TextEditingController _buscarCtrl = TextEditingController();
  final TextEditingController _abonoCtrl  = TextEditingController();
  final Map<String, int> _cantidades      = {};
  final Map<String, TextEditingController> _qtyCtrls = {};
  final NumberFormat _moneyFmt = NumberFormat('#,###', 'es_CO');
  
  // ── Paginación ────────────────────────────────────────────────────────
  int _paginaActual = 0;
  final int _productosPerPage = 6;

  DateTime? _fechaEntrega;
  String _tipoAbono   = 'Efectivo';
  bool _pagoCompleto  = false;
  final List<AbonoPedido> _abonos = [];

  @override
  void dispose() {
    _buscarCtrl.dispose();
    _abonoCtrl.dispose();
    for (final c in _qtyCtrls.values) c.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(String id) {
    return _qtyCtrls.putIfAbsent(
      id, () => TextEditingController(text: '${_cantidades[id] ?? 0}'));
  }

  void _setCantidad(String id, int value) {
    final cantidad = value < 0 ? 0 : value;
    setState(() {
      if (cantidad == 0) _cantidades.remove(id); else _cantidades[id] = cantidad;
      _controllerFor(id).text = '$cantidad';
    });
  }

  void _sumar(String id)          => _setCantidad(id, (_cantidades[id] ?? 0) + 1);
  void _limpiarCantidad(String id) => _setCantidad(id, 0);

  Future<void> _seleccionarFechaEntrega() async {
    try {
      final today = DateTime.now();
      final selected = await showDatePicker(
        context: context,
        initialDate: _fechaEntrega ?? today,
        firstDate: DateTime(today.year, today.month, today.day),
        lastDate: DateTime(2100),
      );
      if (selected != null && mounted) setState(() => _fechaEntrega = selected);
    } catch (e) {
      debugPrint('Error seleccionando fecha: $e');
    }
  }

  void _agregarAbono(double total) {
    final monto = double.tryParse(_abonoCtrl.text.replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ingresa un monto de abono válido')));
      return;
    }
    final abonado  = _abonos.fold<double>(0, (s, a) => s + a.monto);
    final restante = (total - abonado).clamp(0, double.infinity).toDouble();
    if (monto > restante) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('El abono supera el saldo restante (\$${_moneyFmt.format(restante)})'),
      ));
      return;
    }
    setState(() {
      _abonos.add(AbonoPedido(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        monto: monto, tipo: _tipoAbono, fecha: DateTime.now(),
      ));
      _abonoCtrl.clear();
    });
  }

  void _guardarPedido(AppState state, double total) {
    final seleccionados = state.productos
        .where((p) => (_cantidades[p.id] ?? 0) > 0)
        .map((p) => ProductoModel(
              id: p.id, nombre: p.nombre, precio: p.precio,
              imagen: p.imagen, cantidad: _cantidades[p.id] ?? 0))
        .toList();

    if (seleccionados.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Agrega al menos un producto')));
      return;
    }
    if (_fechaEntrega == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Debes establecer la fecha de entrega')));
      return;
    }
    // Validación adicional: fechaEntrega no puede ser anterior a hoy
    final today = DateTime.now();
    final fechaOnly = DateTime(_fechaEntrega!.year, _fechaEntrega!.month, _fechaEntrega!.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (fechaOnly.isBefore(todayOnly)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La fecha de entrega no puede ser anterior a hoy')));
      return;
    }

    final abonosGuardar = _pagoCompleto
        ? [AbonoPedido(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            monto: total, tipo: _tipoAbono, fecha: DateTime.now())]
        : (_abonos.isEmpty ? null : _abonos);

    state.guardarPedido(widget.cliente.id, seleccionados,
        fechaEntrega: _fechaEntrega, abonos: abonosGuardar);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Pedido guardado correctamente')));
    
    // Retornar datos del pedido para mostrar resumen en pantalla anterior
    final abonado = abonosGuardar?.fold<double>(0, (sum, a) => sum + a.monto) ?? 0;
    final saldo = total - abonado;
    final resumenPedido = <String, dynamic>{
      'productos': seleccionados.map((p) => {
        'nombre': p.nombre,
        'cantidad': p.cantidad,
        'precio': p.precio,
      }).toList(),
      'total': total,
      'abonado': abonado,
      'saldo': saldo,
      'abonos': abonosGuardar?.map((a) => {
        'tipo': a.tipo,
        'monto': a.monto,
      }).toList() ?? [],
    };
    
    Navigator.pop(context, resumenPedido);
  }

  // Método para obtener productos de la página actual
  List<ProductoModel> _productosEnPagina(List<ProductoModel> productos) {
    final inicio = _paginaActual * _productosPerPage;
    final fin = (inicio + _productosPerPage).clamp(0, productos.length);
    return productos.sublist(inicio, fin);
  }

  // Método para construir los controles de paginación
  Widget _buildPaginationControls(List<ProductoModel> productos) {
    final totalPaginas = (productos.length / _productosPerPage).ceil();
    final paginaActualDisplay = _paginaActual + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón anterior
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _paginaActual > 0
                ? () => setState(() => _paginaActual--)
                : null,
            tooltip: 'Página anterior',
          ),
          const SizedBox(width: 8),
          // Indicador de página
          Text(
            'Página $paginaActualDisplay de $totalPaginas',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Botón siguiente
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _paginaActual < (totalPaginas - 1)
                ? () => setState(() => _paginaActual++)
                : null,
            tooltip: 'Página siguiente',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final query   = _buscarCtrl.text.trim().toLowerCase();

    final double subtotalRaw = state.productos.fold<double>(0, (sum, p) {
      final cantidad = _cantidades[p.id] ?? 0;
      if (cantidad <= 0) return sum;
      final precio = p.precio.isFinite ? p.precio : 0;
      return sum + (precio * cantidad);
    });

    final double subtotal = subtotalRaw.isFinite ? subtotalRaw : 0.0;
    final double iva = ((subtotal * 0.19).isFinite ? (subtotal * 0.19) : 0.0).roundToDouble();
    final double total = (subtotal + iva).isFinite ? (subtotal + iva) : 0.0;
    final double abonado = _abonos.fold<double>(0, (s, a) => s + a.monto);
    final double saldo = (total - abonado).clamp(0, double.infinity).toDouble();
    final productos = state.productos
        .where((p) => p.nombre.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Crear pedido - ${widget.cliente.nombre}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Productos:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          // ── Buscador ──────────────────────────────────────────────────────
          TextField(
            controller: _buscarCtrl,
            onChanged: (_) => setState(() => _paginaActual = 0),
            decoration: const InputDecoration(
              labelText: 'Buscar producto',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),

          // ── Selector fecha entrega ────────────────────────────────────────
          PointerInterceptor(
            child: InkWell(
              onTap: _seleccionarFechaEntrega,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  const Icon(Icons.event_outlined, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fechaEntrega == null
                          ? 'Fecha de entrega (requerida)'
                          : 'Fecha de entrega: ${DateFormat('dd/MM/yyyy').format(_fechaEntrega!)}',
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Lista de productos ────────────────────────────────────────────
          Expanded(
            child: productos.isEmpty
                ? const Center(child: Text('No hay productos para mostrar'))
                : Column(
                    children: [
                      // Productos paginados
                      Expanded(
                        child: ListView.separated(
                          itemCount: _productosEnPagina(productos).length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p       = _productosEnPagina(productos)[i];
                      final cantidad = _cantidades[p.id] ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(children: [
                          // ── Imagen del producto ───────────────────────────
                          // Muestra la foto si la API la devuelve (campo imagen_url),
                          // de lo contrario cae en un placeholder con ícono.
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: p.imagen != null && p.imagen!.isNotEmpty
                                ? Image.network(
                                    p.imagen!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    // Mientras carga muestra un shimmer gris
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return _ImagenPlaceholder(productName: p.nombre);
                                    },
                                    // Si la URL falla o imagen_url es null, mostrar placeholder
                                    // que ahora incluye el nombre del producto en un SVG
                                    errorBuilder: (_, __, ___) => _ImagenPlaceholder(productName: p.nombre),
                                  )
                                : _ImagenPlaceholder(productName: p.nombre),
                          ),
                          const SizedBox(width: 10),

                          // ── Info + controles de cantidad ──────────────────
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                p.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '\$ ${NumberFormat('#,###', 'es_CO').format(p.precio)}',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                // Botón limpiar
                                GestureDetector(
                                  onTap: () => _limpiarCantidad(p.id),
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.error),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Campo cantidad
                                Container(
                                  width: 60, height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.border),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: TextField(
                                    controller: _controllerFor(p.id),
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: cantidad > 0 ? AppTheme.primary : AppTheme.textSecondary,
                                    ),
                                    onChanged: (v) => _setCantidad(p.id, int.tryParse(v) ?? 0),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Botón sumar
                                GestureDetector(
                                  onTap: () => _sumar(p.id),
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
                                  ),
                                ),
                              ]),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
                      ),
                      // Controles de paginación
                      const SizedBox(height: 12),
                      _buildPaginationControls(productos),
                    ],
                  ),
          ),

          // ── Resumen de totales y abono ────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FilaTotal(label: 'Subtotal:', value: '\$${_moneyFmt.format(subtotal)}'),
              const SizedBox(height: 4),
              _FilaTotal(label: 'IVA 19%:', value: '\$${_moneyFmt.format(iva)}'),
              const SizedBox(height: 4),
              _FilaTotal(
                label: 'Total:',
                value: '\$${_moneyFmt.format(total)}',
                bold: true,
                valueColor: AppTheme.promotorColor,
              ),
              const Divider(height: 24),

              const Text('Abono', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _abonoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_pagoCompleto,
                    decoration: const InputDecoration(hintText: '\$0'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _tipoAbono,
                  onChanged: _pagoCompleto ? null : (v) => setState(() => _tipoAbono = v ?? 'Efectivo'),
                  items: const [
                    DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                  ],
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pagoCompleto ? null : () => _agregarAbono(total),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  child: const Text('Agregar'),
                ),
              ]),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _pagoCompleto,
                onChanged: (v) => setState(() {
                  _pagoCompleto = v ?? false;
                  if (_pagoCompleto) { _abonos.clear(); _abonoCtrl.clear(); }
                }),
                title: const Text('Pago completo (→ Ventas)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              if (_abonos.isNotEmpty) ...[
                const SizedBox(height: 4),
                ..._abonos.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${a.tipo} - ${DateFormat('HH:mm').format(a.fecha)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('\$${_moneyFmt.format(a.monto)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.success)),
                  ]),
                )),
                _FilaTotal(label: 'Abonado total:', value: '\$${_moneyFmt.format(abonado)}', valueColor: AppTheme.success),
                _FilaTotal(label: 'Saldo:', value: '\$${_moneyFmt.format(saldo)}', valueColor: AppTheme.error),
              ],
            ]),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _guardarPedido(state, total),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.promotorColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Widget reutilizable: placeholder cuando no hay imagen ─────────────────────
// Se usa mientras carga la imagen o si la URL falla / es nula.
// Si se proporciona productName, muestra un badge con la inicial del producto.
class _ImagenPlaceholder extends StatelessWidget {
  final String? productName;

  const _ImagenPlaceholder({this.productName});

  @override
  Widget build(BuildContext context) {
    final inicial = (productName?.isNotEmpty ?? false)
        ? productName![0].toUpperCase()
        : '?';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          inicial,
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

// ── Widget reutilizable: fila de total ────────────────────────────────────────
class _FilaTotal extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _FilaTotal({
    required this.label, required this.value,
    this.bold = false, this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        fontSize: bold ? 16 : 14,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        color: AppTheme.textSecondary,
      )),
      Text(value, style: TextStyle(
        fontSize: bold ? 18 : 14,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        color: valueColor ?? AppTheme.textPrimary,
      )),
    ],
  );
}