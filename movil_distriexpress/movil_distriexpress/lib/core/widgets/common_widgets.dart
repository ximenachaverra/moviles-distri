import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../data/models/models.dart';
import 'package:intl/intl.dart';

// â”€â”€â”€ Cliente Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ClienteCard extends StatelessWidget {
  final ClienteModel cliente;
  final VoidCallback onTap;
  final Function(bool)? onToggleAtendido;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.onTap,
    this.onToggleAtendido,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cliente.estado == EstadoCliente.atendido
              ? AppTheme.success.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cliente.estado == EstadoCliente.atendido
                ? AppTheme.success.withValues(alpha: 0.3)
                : AppTheme.border,
            width: cliente.estado == EstadoCliente.atendido ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cliente.estado == EstadoCliente.atendido
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cliente.estado == EstadoCliente.atendido
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                cliente.estado == EstadoCliente.atendido ? Icons.check_circle : Icons.store_rounded,
                color: cliente.estado == EstadoCliente.atendido ? AppTheme.success : AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cliente.zona,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    cliente.direccion,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge saldo / check / toggle button
            if (cliente.estado == EstadoCliente.atendido)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: onToggleAtendido != null
                    ? GestureDetector(
                        onTap: () => onToggleAtendido!(false),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Atendido',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Atendido',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              )
            else if (cliente.saldoPendiente > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${NumberFormat('#,###', 'es_CO').format(cliente.saldoPendiente)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (onToggleAtendido != null)
              GestureDetector(
                onTap: () => onToggleAtendido!(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.promotorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.promotorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.radio_button_unchecked, size: 14, color: AppTheme.promotorColor),
                      SizedBox(width: 4),
                      Text(
                        'Marcar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.promotorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Logo Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_shipping_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          'DistriExpress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Role Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RoleBadge extends StatelessWidget {
  final UserRole rol;

  const RoleBadge({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    final isPromotor = rol == UserRole.promotor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPromotor ? AppTheme.promotorColor : AppTheme.repartidorColor)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPromotor ? Icons.campaign_rounded : Icons.delivery_dining_rounded,
            size: 13,
            color:
                isPromotor ? AppTheme.promotorColor : AppTheme.repartidorColor,
          ),
          const SizedBox(width: 4),
          Text(
            isPromotor ? 'Promotor' : 'Repartidor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPromotor
                  ? AppTheme.promotorColor
                  : AppTheme.repartidorColor,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Stat Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              _shortenStat(value),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Section Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

String _shortenStat(String value) {
  // Preserve non-numeric prefix (like '$') and shorten digits to max 3
  final prefixMatch = RegExp(r'^\s*([^0-9]*)').firstMatch(value);
  final prefix = prefixMatch != null ? prefixMatch.group(1) ?? '' : '';
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= 3) return value;
  return '${prefix}${digits.substring(0, 3)}+';
}

// â”€â”€â”€ Loading Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.white.withValues(alpha: 0.6),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2.5,
              ),
            ),
          ),
      ],
    );
  }
}
