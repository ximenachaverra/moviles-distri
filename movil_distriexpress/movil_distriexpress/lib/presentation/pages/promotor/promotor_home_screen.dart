import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/common_widgets.dart';
import 'promotor_detalle_screen.dart';
import 'promotor_abonos_screen.dart';
import 'promotor_pedidos_screen.dart';
import '../perfil_screen.dart';

class PromotorHomeScreen extends StatefulWidget {
  const PromotorHomeScreen({super.key});

  @override
  State<PromotorHomeScreen> createState() => _PromotorHomeScreenState();
}

class _PromotorHomeScreenState extends State<PromotorHomeScreen> {
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
    final query = _searchCtrl.text.trim().toLowerCase();
    
    // Mostrar solo clientes PENDIENTES
    final clientesFiltrados = state.clientes.where((c) {
      if (c.estado != EstadoCliente.pendiente) return false;
      
      if (query.isEmpty) return true;
      return '${c.nombre} ${c.zona} ${c.direccion}'.toLowerCase().contains(query);
    }).toList();
    
    // Contar clientes por estado
    final pendientes = state.clientes.where((c) => c.estado == EstadoCliente.pendiente).length;
    final atendidos = state.clientes.where((c) => c.estado == EstadoCliente.atendido).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.nombreCompleto,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          RoleBadge(rol: user.rol),
        ]),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ClienteSearchDelegate(state.clientes),
              );
            },
          ),          
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.route_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      const Text('RUTA:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5)),
                      const SizedBox(width: 6),
                      const Text('Ventas del norte',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary)),
                    ]),
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
                      StatCard(
                          label: 'Pendientes',
                          value: '$pendientes',
                          icon: Icons.store_rounded,
                          color: AppTheme.promotorColor),
                      const SizedBox(width: 10),
                      StatCard(
                          label: 'Atendidos',
                          value: '$atendidos',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.success),
                      const SizedBox(width: 10),
                      StatCard(
                          label: 'Pedidos hoy',
                          value: '${state.pedidos.length}',
                          icon: Icons.receipt_long_rounded,
                          color: AppTheme.accentOrange),
                    ]),
                  ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: const SectionHeader(
                          title: 'CLIENTES EN RUTA',
                          subtitle: 'Selecciona para crear pedido'),
                    ),
                    Flexible(
                      flex: 1,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: [
                          // Acceso rápido a abonos desde el header
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PromotorAbonosScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.promotorColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.promotorColor
                                        .withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                Icon(Icons.payments_outlined,
                                    size: 13, color: AppTheme.promotorColor),
                                SizedBox(width: 4),
                                Text('Abonos',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.promotorColor)),
                              ]),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            constraints: const BoxConstraints(
                                maxWidth: 120),
                            decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('${state.clientes.length} en ruta',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary)),
                          ),
                        ],
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
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PromotorDetalleScreen(cliente: cliente))),
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
        decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.border))),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.promotorColor,
          unselectedItemColor: AppTheme.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.route_rounded), label: 'Ruta'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded), label: 'Pedidos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined), label: 'Abonos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
          ],
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 1) {
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PromotorPedidosScreen()))
                  .then((_) => setState(() => _selectedIndex = 0));
            } else if (index == 2) {
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PromotorAbonosScreen()))
                  .then((_) => setState(() => _selectedIndex = 0));
            } else if (index == 3) {
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PerfilScreen()))
                  .then((_) => setState(() => _selectedIndex = 0));
            }
          },
        ),
      ),
    );
  }
}

class _ClienteSearchDelegate extends SearchDelegate<String> {
  final List<ClienteModel> clientes;

  _ClienteSearchDelegate(this.clientes);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim().toLowerCase();
    // Solo buscar entre clientes con estado PENDIENTE
    final filtered = clientes.where((c) {
      if (c.estado != EstadoCliente.pendiente) return false;
      if (q.isEmpty) return true;
      return '${c.nombre} ${c.zona} ${c.direccion}'.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, index) {
        final cliente = filtered[index];
        return ListTile(
          leading: const Icon(Icons.store_rounded),
          title: Text(cliente.nombre),
          subtitle: Text('${cliente.zona} • ${cliente.direccion}'),
          onTap: () => close(context, cliente.id),
        );
      },
    );
  }
}