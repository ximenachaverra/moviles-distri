import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_state.dart';
import '../../../data/models/models.dart';
import 'repartidor_home_screen.dart';
import '../promotor/promotor_home_screen.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return user.rol == UserRole.promotor
        ? const PromotorHomeScreen()
        : const RepartidorHomeScreen();
  }
}