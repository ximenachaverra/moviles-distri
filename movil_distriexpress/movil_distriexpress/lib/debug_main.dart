import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/models/app_state.dart';

// Usa esto temporalmente para debuggear
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Debug Info')),
          body: Consumer<AppState>(
            builder: (context, state, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Usuario
                    _buildSection('👤 USUARIO ACTUAL', [
                      'ID: ${state.usuarioActual?.id}',
                      'Nombre: ${state.usuarioActual?.nombre} ${state.usuarioActual?.apellido}',
                      'Email: ${state.usuarioActual?.email}',
                      'Rol: ${state.usuarioActual?.rol}',
                    ]),
                    const SizedBox(height: 20),
                    
                    // Ruta
                    _buildSection('🗺️ RUTA ACTUAL', [
                      'ID: ${state.rutaActual?['id']}',
                      'Nombre: ${state.rutaActual?['nombre']}',
                      'Clientes en ruta: ${state.clientes.length}',
                    ]),
                    const SizedBox(height: 20),
                    
                    // Clientes
                    _buildSection('👥 CLIENTES', [
                      ...state.clientes.map((c) => 
                        '- ${c.nombre} (zona: ${c.zona}, dir: ${c.direccion})')
                    ]),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

Widget _buildSection(String title, List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(item, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      )),
    ],
  );
}
