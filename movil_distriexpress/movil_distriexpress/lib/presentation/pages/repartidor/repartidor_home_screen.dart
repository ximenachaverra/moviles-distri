import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/common_widgets.dart';
import 'repartidor_detalle_screen.dart';
import 'abonos_screen.dart';
import '../perfil_screen.dart';

class RepartidorHomeScreen extends StatefulWidget {
  const RepartidorHomeScreen({super.key});

  @override
  State<RepartidorHomeScreen> createState() => _RepartidorHomeScreenState();
}

class _RepartidorHomeScreenState extends State<RepartidorHomeScreen> {
  int _selectedIndex = 0;
  int _clientesMostrados = 5;
  static const int _clientesPorPagina = 5;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _mostrarObservacion(BuildContext context, ClienteModel cliente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.cancel_rounded, color: AppTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(cliente.nombre,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Motivo de no entrega:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                cliente.observacion?.isNotEmpty == true
                    ? cliente.observacion!
                    : 'Sin observación registrada',
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final entregados = state.clientes.where((c) => c.estado == EstadoCliente.entregado || c.estado == EstadoCliente.atendido).length;
    final noEntregados = state.clientes.where((c) => c.estado == EstadoCliente.noEntregado).length;
    final total = state.clientes.length;
    final query = _searchCtrl.text.trim().toLowerCase();

    // Ordenar: pendientes → no entregados → entregados
    int estadoOrden(EstadoCliente e) {
      switch (e) {
        case EstadoCliente.pendiente: return 0;
        case EstadoCliente.noEntregado: return 1;
        case EstadoCliente.entregado: return 2;
        case EstadoCliente.atendido: return 2;
      }
    }

    final clientesFiltrados = state.clientes
        .where((c) =>
            query.isEmpty ||
            '${c.nombre} ${c.zona} ${c.direccion}'.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => estadoOrden(a.estado) - estadoOrden(b.estado));

    final clientesVisibles = clientesFiltrados.take(_clientesMostrados).toList();

    // Nombre de la ruta asignada
    String nombreRuta = 'Sin asignar';
    final ruta = state.rutaActual;
    if (ruta != null) {
      final nombre = ruta['nombre'];
      final zona = ruta['zona'];
      final id = ruta['id'];
      if (nombre != null && nombre.toString().trim().isNotEmpty) {
        nombreRuta = nombre.toString().trim();
      } else if (zona != null && zona.toString().trim().isNotEmpty) {
        nombreRuta = 'Zona ${zona.toString().trim()}';
      } else if (id != null) {
        nombreRuta = 'Ruta #${id.toString()}';
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.nombreCompleto,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          RoleBadge(rol: user.rol),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 16),
                // Nombre de ruta
                Row(children: [
                  const Icon(Icons.route_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  const Text('RUTA:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(nombreRuta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                  ),
                ]),
                const SizedBox(height: 12),
                // Progreso
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Progreso de ruta',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  Text('$entregados / $total entregas',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total > 0 ? entregados / total : 0,
                    backgroundColor: AppTheme.primaryLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() { _clientesMostrados = _clientesPorPagina; }),
                  decoration: const InputDecoration(
                    hintText: 'Buscar cliente, zona o dirección',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  StatCard(label: 'Pendientes', value: '${total - entregados - noEntregados}', icon: Icons.pending_actions_rounded, color: AppTheme.accentOrange),
                  const SizedBox(width: 10),
                  StatCard(label: 'Entregados', value: '$entregados', icon: Icons.check_circle_outline_rounded, color: AppTheme.success),
                  const SizedBox(width: 10),
                  StatCard(label: 'Abonos hoy', value: '${state.abonos.length}', icon: Icons.payments_outlined, color: AppTheme.primary),
                ]),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Flexible(
                  flex: 2,
                  child: SectionHeader(title: 'CLIENTES EN RUTA', subtitle: 'Toca un cliente para gestionar la entrega'),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbonosScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.repartidorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.repartidorColor.withValues(alpha: 0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.payments_outlined, size: 14, color: AppTheme.repartidorColor),
                      SizedBox(width: 4),
                      Text('Abonos',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.repartidorColor)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cliente = clientesVisibles[index];
                  final esNoEntregado = cliente.estado == EstadoCliente.noEntregado;
                  final esPendiente = cliente.estado == EstadoCliente.pendiente;
                  return ClienteCard(
                    cliente: cliente,
                    onTap: esNoEntregado
                        ? () => _mostrarObservacion(context, cliente)
                        : esPendiente
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RepartidorDetalleScreen(cliente: cliente)),
                                )
                            : null, // entregado → sin acción
                  );
                },
                childCount: clientesVisibles.length,
              ),
            ),
          ),
          if (clientesFiltrados.length > _clientesMostrados)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _clientesMostrados += _clientesPorPagina),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(
                    'Ver más (${clientesFiltrados.length - _clientesMostrados} restantes)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.repartidorColor,
                    side: BorderSide(color: AppTheme.repartidorColor.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.repartidorColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.route_rounded), label: 'Ruta'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Abonos'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
          ],
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AbonosScreen()))
                  .then((_) => setState(() => _selectedIndex = 0));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()))
                  .then((_) => setState(() => _selectedIndex = 0));
            }
          },
        ),
      ),
    );
  }
}
