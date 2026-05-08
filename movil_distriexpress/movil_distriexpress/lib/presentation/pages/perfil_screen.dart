import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../../core/theme/app_theme.dart';
import '../../data/models/app_state.dart';
import '../../data/models/models.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Uint8List? _fotoBytes;
  String? _fotoNombre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().fetchPerfil();
      }
    });
  }

  Future<void> _seleccionarFoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _fotoBytes = file.bytes;
      _fotoNombre = file.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          title: const Text('Mi Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ),
        body: const Center(child: Text('No hay sesion activa')),
      );
    }

    final isPromotor = user.rol == UserRole.promotor;
    final roleColor = isPromotor ? AppTheme.promotorColor : AppTheme.repartidorColor;
    final roleLabel = isPromotor ? 'Promotor' : 'Repartidor';
    final roleIcon = isPromotor ? Icons.campaign_rounded : Icons.delivery_dining_rounded;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Mi Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _seleccionarFoto,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: roleColor.withValues(alpha: 0.12),
                            border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 3),
                          ),
                          child: ClipOval(
                            child: _fotoBytes != null
                                ? Image.memory(
                                    _fotoBytes!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  )
                                : Container(
                                    color: roleColor.withValues(alpha: 0.05),
                                    child: Icon(Icons.person_rounded, size: 60, color: roleColor.withValues(alpha: 0.5)),
                                  ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _seleccionarFoto,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: roleColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  if (_fotoNombre != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _fotoNombre!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    user.nombreCompleto,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 14, color: roleColor),
                        const SizedBox(width: 6),
                        Text(roleLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: roleColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INFORMACION PERSONAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(icon: Icons.badge_outlined, label: 'Nombre', value: user.nombre),
                    const Divider(height: 1, color: AppTheme.border),
                    _InfoRow(icon: Icons.person_outline_rounded, label: 'Apellido', value: user.apellido),
                    const Divider(height: 1, color: AppTheme.border),
                    _InfoRow(icon: Icons.email_outlined, label: 'Correo', value: user.email),
                    const Divider(height: 1, color: AppTheme.border),
                    _InfoRow(icon: Icons.fingerprint_rounded, label: 'Documento', value: '1.045.${user.id.padLeft(6, '0')}'),
                    if (user.telefono != null) ...[
                      const Divider(height: 1, color: AppTheme.border),
                      _InfoRow(icon: Icons.phone_outlined, label: 'Telefono', value: user.telefono!),
                    ],
                  ]),
                  const SizedBox(height: 20),
                  const Text('ROL Y PERMISOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(icon: roleIcon, label: 'Rol asignado', value: roleLabel, valueColor: roleColor),
                    const Divider(height: 1, color: AppTheme.border),
                    _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Permisos',
                      value: isPromotor ? 'Crear pedidos • Ver clientes' : 'Entregar pedidos • Registrar abonos',
                    ),
                  ]),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AppState>().logout();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Cerrar sesion'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary)),
            ]),
          ),
        ]),
      );
}