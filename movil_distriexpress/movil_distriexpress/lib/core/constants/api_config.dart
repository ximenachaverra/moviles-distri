class ApiConfig {
  // For web dev, prefer explicit --dart-define; default to backend on port 5001.
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    return 'http://localhost:5001';
  }

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String perfil = '/api/auth/perfil';
  static const String clientes = '/api/clientes';
  static const String productos = '/api/productos';
  static const String pedidos = '/api/pedidos';
  static const String abonos = '/api/abonos';
  static const String ruta = '/api/ruta';
  static const String entregas = '/api/entregas';
}
