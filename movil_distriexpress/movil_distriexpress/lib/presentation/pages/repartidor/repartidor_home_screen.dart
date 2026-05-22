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
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final atendidos = state.clientes.where((c) => c.estado == EstadoCliente.atendido).length;
    final total = state.clientes.length;
    final query = _searchCtrl.text.trim().toLowerCase();
    final clientesFiltrados = state.clientes.where((c) {
      if (query.isEmpty) return true;
      return '${c.nombre} ${c.zona} ${c.direccion}'.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.nombreCompleto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Progreso de ruta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  Text('$atendidos / $total entregas', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total > 0 ? atendidos / total : 0,
                    backgroundColor: AppTheme.primaryLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar cliente, zona o dirección',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  StatCard(label: 'Pendientes', value: '${total - atendidos}', icon: Icons.pending_actions_rounded, color: AppTheme.accentOrange),
                  const SizedBox(width: 10),
                  StatCard(label: 'Entregados', value: '$atendidos', icon: Icons.check_circle_outline_rounded, color: AppTheme.success),
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
                const SectionHeader(title: 'RUTA DEL DÍA', subtitle: 'Toca un cliente para gestionar la entrega'),
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
                      Text('Abonos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.repartidorColor)),
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
                  final cliente = clientesFiltrados[index];
                  return ClienteCard(
                    cliente: cliente,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RepartidorDetalleScreen(cliente: cliente))),
                  );
                },
                childCount: clientesFiltrados.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
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