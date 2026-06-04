import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/api_config.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  String? _token;
  UserModel? _currentUser;
  List<ClienteModel> _clientes = [];
  List<ProductoModel> _productos = [];
  List<PedidoModel> _pedidos = [];
  List<AbonoModel> _abonos = [];
  Map<String, dynamic>? _rutaActual;
  bool _loading = false;

  UserModel? get currentUser => _currentUser;
  List<ClienteModel> get clientes => _clientes;
  List<ProductoModel> get productos => _productos;
  List<PedidoModel> get pedidos => _pedidos;
  List<AbonoModel> get abonos => _abonos;
  Map<String, dynamic>? get rutaActual => _rutaActual;
  bool get loading => _loading;
  String? get token => _token;

  // Aliases para mejor claridad
  Map<String, dynamic>? get rutaAsignada => _rutaActual;
  Map<String, dynamic>? get entregaActual => _rutaActual; // Usa la ruta actual como referencia de entrega

  AppState() {
    // On app start (web) attempt to prefetch products so catalog is available
    // before user logs in. Errors are logged but do not crash the app.
    fetchProductos();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      _token = data['token']?.toString();
      final usuario = (data['usuario'] as Map?)?.cast<String, dynamic>() ?? {};

      _currentUser = UserModel.fromJson(usuario);
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      await _cargarDatosIniciales();
      await fetchPerfil();
      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String nombre, String apellido, String email,
      String password, UserRole rol) async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'password': password,
          'rol': rol == UserRole.promotor ? 'promotor' : 'repartidor',
        },
      );

      final data = response.data as Map<String, dynamic>;
      _token = data['token']?.toString();
      final usuario = (data['usuario'] as Map?)?.cast<String, dynamic>() ?? {};

      _currentUser = UserModel.fromJson(usuario);
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      await _cargarDatosIniciales();
      await fetchPerfil();
      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void logout() {
    _token = null;
    _dio.options.headers.remove('Authorization');
    _currentUser = null;
    _clientes = [];
    _productos = [];
    _pedidos = [];
    _abonos = [];
    notifyListeners();
  }

  // ── Password Recovery ──────────────────────────────────────────────────────
  Future<bool> olvidePassword(String email) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/auth/olvide-password',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error olvidePassword: $e');
      return false;
    }
  }

  Future<bool> verificarCodigo(String email, String codigo) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/auth/verificar-codigo',
        data: {'email': email, 'codigo': codigo},
      );
      return response.data['valido'] ?? false;
    } catch (e) {
      print('Error verificarCodigo: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String email, String codigo, String nuevaPassword, String confirmarPassword) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/auth/reset-password',
        data: {
          'email': email,
          'codigo': codigo,
          'nuevaPassword': nuevaPassword,
          'confirmarPassword': confirmarPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error resetPassword: $e');
      return false;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    // Determinar si es promotor/repartidor
    final esPromotorORepartidor = _currentUser?.rol == UserRole.promotor || _currentUser?.rol == UserRole.repartidor;
    
    // ignore: avoid_print
    print('[AppState] _cargarDatosIniciales - Rol: ${_currentUser?.rol}, Es promotor/repartidor: $esPromotorORepartidor');

    // Obtener clientes según el rol
    late Future<dynamic> clientesRequest;
    if (esPromotorORepartidor) {
      // ignore: avoid_print
      print('[AppState] Obteniendo clientes de ruta asignada...');
      clientesRequest = _dio.get(ApiConfig.ruta);
    } else {
      // ignore: avoid_print
      print('[AppState] Obteniendo todos los clientes...');
      clientesRequest = _dio.get(ApiConfig.clientes);
    }

    final responses = await Future.wait([
      clientesRequest,
      _dio.get(ApiConfig.productos),
      _dio.get(ApiConfig.pedidos),
      _dio.get(ApiConfig.abonos),
    ]);

    // Procesar clientes según el tipo de respuesta
    late List<dynamic> clientesJson;
    if (esPromotorORepartidor) {
      // La respuesta es { ruta: {...}, clientes: [...] }
      final rutaResponse = responses[0].data as Map<String, dynamic>;
      clientesJson = (rutaResponse['clientes'] ?? []) as List<dynamic>;
      // ignore: avoid_print
      print('[AppState] Clientes cargados de ruta: ${clientesJson.length}');
    } else {
      // La respuesta es directamente una lista de clientes
      clientesJson = _asListMap(responses[0].data);
      // ignore: avoid_print
      print('[AppState] Todos los clientes cargados: ${clientesJson.length}');
    }

    final productosJson = _asListMap(responses[1].data);
    final pedidosJson = _asListMap(responses[2].data);
    final abonosJson = _asListMap(responses[3].data);

    _clientes = clientesJson.map((c) => ClienteModel.fromJson(c as Map<String, dynamic>)).toList();
    _productos = productosJson.map(ProductoModel.fromJson).toList();
    _abonos = abonosJson.map(AbonoModel.fromJson).toList();

    final clientePorId = {for (final c in _clientes) c.id: c};
    _pedidos = pedidosJson
        .map((p) {
          final clienteId = (p['cliente_id'] ?? '').toString();
          ClienteModel? cliente = clientePorId[clienteId];

          if (cliente == null) {
            cliente = ClienteModel(
              id: clienteId.isEmpty ? '0' : clienteId,
              nombre: (p['cliente_nombre'] ?? 'Cliente').toString(),
              zona: '',
              direccion: (p['cliente_direccion'] ?? '').toString(),
              lat: 0,
              lng: 0,
            );
          }

          return PedidoModel.fromJson(p, cliente: cliente);
        })
        .toList();
  }

  /// Public method to fetch products independently (useful for web when not
  /// authenticated). Leaves other state untouched.
  Future<void> fetchProductos() async {
    try {
      final response = await _dio.get(ApiConfig.productos);
      final productosJson = _asListMap(response.data);
      _productos = productosJson.map(ProductoModel.fromJson).toList();
      // debug info for web console
      // ignore: avoid_print
      print('[AppState] fetchProductos -> loaded ${_productos.length} productos');
      notifyListeners();
    } catch (_) {
      // ignore network errors here; caller can retry
      // ignore: avoid_print
      print('[AppState] fetchProductos failed');
    }
  }

  /// Fetch clients from API and update local state.
  /// Para promotores y repartidores, trae solo los clientes asignados a su ruta.
  /// Para otros roles, trae todos los clientes.
  Future<void> fetchClientes() async {
    if (_token == null) return;
    try {
      // Debug: mostrar rol del usuario
      // ignore: avoid_print
      print('[AppState] fetchClientes - Rol actual: ${_currentUser?.rol} (${_currentUser?.rol.runtimeType})');
      
      // Si es promotor o repartidor, obtener su ruta asignada
      if (_currentUser?.rol == UserRole.promotor || _currentUser?.rol == UserRole.repartidor) {
        // ignore: avoid_print
        print('[AppState] fetchClientes - Es promotor/repartidor, obteniendo ruta asignada...');
        
        final response = await _dio.get(ApiConfig.ruta);
        final rutaData = response.data as Map<String, dynamic>;
        
        // ignore: avoid_print
        print('[AppState] fetchClientes - Respuesta ruta: ${rutaData.keys.toList()}');
        
        // Guardar la ruta actual
        _rutaActual = rutaData['ruta'] as Map<String, dynamic>?;
        
        // ignore: avoid_print
        print('[AppState] fetchClientes - Ruta guardada: $_rutaActual');
        print('[AppState] fetchClientes - Campos de ruta: ${_rutaActual?.keys.toList()}');
        
        // Si tiene ruta asignada, usar los clientes de la ruta
        if (rutaData['clientes'] != null && rutaData['clientes'] is List) {
          final clientesJson = _asListMap(rutaData['clientes']);
          _clientes = clientesJson.map(ClienteModel.fromJson).toList();
          // ignore: avoid_print
          print('[AppState] fetchClientes (ruta) -> loaded ${_clientes.length} clientes asignados');
        } else {
          _clientes = [];
          // ignore: avoid_print
          print('[AppState] fetchClientes -> sin ruta asignada, devuelve lista vacía');
        }
      } else {
        // Para otros roles, traer todos los clientes
        // ignore: avoid_print
        print('[AppState] fetchClientes - No es promotor/repartidor, obteniendo todos los clientes...');
        
        final response = await _dio.get(ApiConfig.clientes);
        final clientesJson = _asListMap(response.data);
        _clientes = clientesJson.map(ClienteModel.fromJson).toList();
        // ignore: avoid_print
        print('[AppState] fetchClientes -> loaded ${_clientes.length} clientes');
      }
      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print('[AppState] fetchClientes error: $e');
    }
  }

  /// Fetch pedidos and map clientes by existing client list.
  Future<void> fetchPedidos() async {
    if (_token == null) return;
    try {
      final response = await _dio.get(ApiConfig.pedidos);
      final pedidosJson = _asListMap(response.data);
      final clientePorId = {for (final c in _clientes) c.id: c};
      _pedidos = pedidosJson
          .map((p) {
            final clienteId = (p['cliente_id'] ?? '').toString();
            ClienteModel? cliente = clientePorId[clienteId];

            if (cliente == null) {
              cliente = ClienteModel(
                id: clienteId.isEmpty ? '0' : clienteId,
                nombre: (p['cliente_nombre'] ?? 'Cliente').toString(),
                zona: '',
                direccion: (p['cliente_direccion'] ?? '').toString(),
                lat: 0,
                lng: 0,
              );
            }

            return PedidoModel.fromJson(p, cliente: cliente);
          })
          .toList();
      notifyListeners();
      // ignore: avoid_print
      print('[AppState] fetchPedidos -> loaded ${_pedidos.length} pedidos');
    } catch (_) {
      // ignore: avoid_print
      print('[AppState] fetchPedidos failed');
    }
  }

  Future<void> fetchAbonos() async {
    if (_token == null) return;
    try {
      final response = await _dio.get(ApiConfig.abonos);
      final abonosJson = _asListMap(response.data);
      _abonos = abonosJson.map(AbonoModel.fromJson).toList();
      notifyListeners();
      // ignore: avoid_print
      print('[AppState] fetchAbonos -> loaded ${_abonos.length} abonos');
    } catch (_) {
      // ignore: avoid_print
      print('[AppState] fetchAbonos failed');
    }
  }

  Future<void> fetchPerfil() async {
    if (_token == null) return;
    try {
      final response = await _dio.get(ApiConfig.perfil);
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      _currentUser = UserModel.fromJson({
        ...data,
        'rol': data['rol'],
        'telefono': data['telefono'] ?? data['celular'],
      });
      notifyListeners();
      // ignore: avoid_print
      print('[AppState] fetchPerfil -> user ${_currentUser?.id} refreshed');
    } catch (_) {
      // ignore: avoid_print
      print('[AppState] fetchPerfil failed');
    }
  }

  List<Map<String, dynamic>> _asListMap(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return [];
  }

  bool _esIdDeApi(String id) => int.tryParse(id) != null;

  // ignore: unused_element
  void _loadMockData() {
    _clientes = [
      ClienteModel(
        id: '1',
        nombre: 'Ximena Tiendas',
        zona: 'Zona Sur',
        direccion: 'Cra 45 Clle 34 Rio Negro Antioquia',
        lat: 6.1586,
        lng: -75.3742,
        saldoPendiente: 125000,
        estado: EstadoCliente.pendiente,
      ),
      ClienteModel(
        id: '2',
        nombre: 'Tienda Don Carlos',
        zona: 'Zona Norte',
        direccion: 'Clle 50 # 23-10 Itagui',
        lat: 6.1742,
        lng: -75.6012,
        saldoPendiente: 75000,
        estado: EstadoCliente.pendiente,
      ),
      ClienteModel(
        id: '3',
        nombre: 'Supermercado La 14',
        zona: 'Zona Centro',
        direccion: 'Av Regional # 45-67 Medellin',
        lat: 6.2145,
        lng: -75.5765,
        saldoPendiente: 0,
        estado: EstadoCliente.pendiente,
      ),
      ClienteModel(
        id: '4',
        nombre: 'Minimercado El Parque',
        zona: 'Zona Sur',
        direccion: 'Cra 80 # 12-45 Envigado',
        lat: 6.1693,
        lng: -75.5803,
        saldoPendiente: 200000,
        estado: EstadoCliente.pendiente,
      ),
    ];

    _productos = [
      ProductoModel(id: 'p1', nombre: 'Arroz Premiun 200g Pk', precio: 35000),
      ProductoModel(id: 'p2', nombre: 'Arroz Integral 500g', precio: 48000),
      ProductoModel(id: 'p3', nombre: 'Aceite Girasol 1L', precio: 22000),
      ProductoModel(id: 'p4', nombre: 'Azucar Morena 1kg', precio: 18000),
      ProductoModel(id: 'p5', nombre: 'Sal Marina 500g', precio: 5000),
      ProductoModel(id: 'p6', nombre: 'Harina de Trigo 1kg', precio: 12000),
    ];

    _abonos = [
      AbonoModel(
        id: 'a1',
        clienteId: '2',
        clienteNombre: 'Tienda Don Carlos',
        monto: 50000,
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        observacion: 'Abono parcial',
      ),
    ];

    _pedidos = [
      PedidoModel(
        id: 'ped1',
        cliente: _clientes[0],
        items: [
          ItemPedido(
            producto:
                ProductoModel(id: 'p1', nombre: 'Arroz Premiun 200g Pk', precio: 35000),
            cantidad: 2,
          ),
          ItemPedido(
            producto: ProductoModel(id: 'p3', nombre: 'Aceite Girasol 1L', precio: 22000),
            cantidad: 3,
          ),
        ],
        fecha: DateTime.now(),
        estado: EstadoPedido.pendiente,
        origen: 'pedido',
      ),
    ];
  }

  Future<void> cambiarEstadoCliente(String clienteId, EstadoCliente nuevoEstado) async {
    final idx = _clientes.indexWhere((c) => c.id == clienteId);
    if (idx >= 0) {
      final estadoAnterior = _clientes[idx].estado;
      // Actualizar localmente de inmediato
      _clientes[idx].estado = nuevoEstado;
      notifyListeners();

      // Sincronizar con servidor si es un ID de BD
      if (_token != null && _esIdDeApi(clienteId)) {
        try {
          await _dio.patch(
            '${ApiConfig.clientes}/$clienteId/estado',
            data: {'estado': nuevoEstado.label.toLowerCase()},
          );
          // Forzar refresco desde servidor para asegurar consistencia
          await fetchClientes();
        } catch (e) {
          // Si falla la sincronización, revertir el cambio local
          _clientes[idx].estado = estadoAnterior;
          notifyListeners();
          // ignore: avoid_print
          print('[AppState] Error cambiarEstadoCliente: $e');
          rethrow;
        }
      }
    }
  }

  /// Calcula dinámicamente el saldo pendiente de un cliente basado en sus pedidos
  double calcularSaldoPendienteCliente(String clienteId) {
    final pedidosCliente = pedidosPorCliente(clienteId);
    if (pedidosCliente.isEmpty) return 0;
    return pedidosCliente.fold<double>(
      0,
      (sum, pedido) => sum + pedido.saldoPendiente,
    );
  }

  Future<void> registrarAbono(
    String clienteId,
    String clienteNombre,
    double monto,
    String? observacion,
  ) async {
    // Si hay un pedido asociado, usar el flujo por pedido para persistir en DB.
    final pedidosCliente = pedidosPorCliente(clienteId)
        .where((p) => p.saldoPendiente > 0)
        .toList();
    final pedidoObjetivo = pedidosCliente.isNotEmpty
        ? pedidosCliente.first
        : (pedidosPorCliente(clienteId).isNotEmpty ? pedidosPorCliente(clienteId).first : null);

    if (pedidoObjetivo != null) {
      await agregarAbonoPedido(
        pedidoObjetivo.id,
        AbonoPedido(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          monto: monto,
          tipo: 'Efectivo',
          fecha: DateTime.now(),
        ),
      );
      return;
    }

    // Fallback local si no existe pedido para enlazar.
    _abonos.add(AbonoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      monto: monto,
      fecha: DateTime.now(),
      observacion: observacion,
    ));

    final idx = _clientes.indexWhere((c) => c.id == clienteId);
    if (idx >= 0) {
      _clientes[idx] = ClienteModel(
        id: _clientes[idx].id,
        nombre: _clientes[idx].nombre,
        zona: _clientes[idx].zona,
        direccion: _clientes[idx].direccion,
        lat: _clientes[idx].lat,
        lng: _clientes[idx].lng,
        saldoPendiente:
            (_clientes[idx].saldoPendiente - monto).clamp(0, double.infinity),
        estado: _clientes[idx].estado,
      );
    }
    notifyListeners();
  }

  void guardarPedido(
    String clienteId,
    List<ProductoModel> productosConCantidad, {
    DateTime? fechaEntrega,
    String observaciones = '',
    List<AbonoPedido>? abonos,
    EstadoPedido estado = EstadoPedido.pendiente,
    String origen = 'pedido',
  }) {
    final cliente = _clientes.firstWhere((c) => c.id == clienteId);
    final items = productosConCantidad
        .where((p) => p.cantidad > 0)
        .map((p) => ItemPedido(
              producto: ProductoModel(id: p.id, nombre: p.nombre, precio: p.precio),
              cantidad: p.cantidad,
            ))
        .toList();

    if (items.isEmpty) return;

    final nuevoPedido = PedidoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cliente: cliente,
      items: items,
      fecha: DateTime.now(),
      fechaEntrega: fechaEntrega,
      observaciones: observaciones,
      abonosPedido: abonos ?? [],
      estado: estado,
      origen: origen,
    );

    _pedidos.add(nuevoPedido);
    notifyListeners();

    if (_token != null) {
      final payload = {
        'clienteId': int.tryParse(cliente.id),
        'clienteNombre': cliente.nombre,
        'clienteTelefono': '',
        'clienteDireccion': cliente.direccion,
        'fechaEntrega': fechaEntrega?.toIso8601String().split('T').first,
        'observaciones': observaciones,
        'productos': nuevoPedido.items
            .map((i) => {
                  'id': int.tryParse(i.producto.id),
                  'nombre': i.producto.nombre,
                  'precio': i.producto.precio,
                  'cantidad': i.cantidad,
                })
            .where((p) => p['id'] != null)
            .toList(),
        'abonos': (abonos ?? [])
            .map((a) => {'monto': a.monto, 'tipo': a.tipo})
            .toList(),
      };
      unawaited(_dio.post(ApiConfig.pedidos, data: payload));
      // Trigger refetch so UI reflects DB changes made on the server
      unawaited(fetchPedidos());
      unawaited(fetchAbonos());
      unawaited(fetchClientes());
    }
  }

  Future<void> agregarAbonoPedido(String pedidoId, AbonoPedido abono) async {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx < 0) return;

    _pedidos[idx].abonosPedido.add(abono);
    _recalcularEstadoPedido(idx);
    notifyListeners();

    if (_token != null && _esIdDeApi(pedidoId)) {
      await _dio.post(
        '${ApiConfig.pedidos}/$pedidoId/abono',
        data: {'monto': abono.monto, 'tipo': abono.tipo},
      );
      // Refresh relevant data
      await fetchPedidos();
      await fetchAbonos();
      await fetchClientes();
    }
  }

  void checkProductoPedido(String pedidoId, String productoId, bool checked) {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx < 0) return;

    for (final item in _pedidos[idx].items) {
      if (item.producto.id == productoId) item.checked = checked;
    }
    _recalcularEstadoPedido(idx);
    notifyListeners();

    if (_token != null && _esIdDeApi(pedidoId) && _esIdDeApi(productoId)) {
      unawaited(_dio.patch(
        '${ApiConfig.pedidos}/$pedidoId/check',
        data: {'productoId': int.parse(productoId), 'checked': checked},
      ));
      unawaited(fetchPedidos());
    }
  }

  void _recalcularEstadoPedido(int idx) {
    final p = _pedidos[idx];
    final todosChequeados = p.items.every((i) => i.checked);
    final tieneAbono = p.totalAbonado > 0;
    final pagadoCompleto = p.totalAbonado >= p.total;

    if (!tieneAbono) {
      p.estado = todosChequeados ? EstadoPedido.pendientePorPago : EstadoPedido.enProceso;
      p.origen = 'pedido';
    } else if (tieneAbono && !todosChequeados) {
      p.estado = EstadoPedido.enProceso;
      p.origen = 'pedido';
    } else if (tieneAbono && todosChequeados && !pagadoCompleto) {
      p.estado = EstadoPedido.pendientePorPago;
      p.origen = 'venta';
    } else if (tieneAbono && todosChequeados && pagadoCompleto) {
      p.estado = EstadoPedido.pagado;
      p.origen = 'venta';
    }
  }

  List<AbonoModel> abonosPorCliente(String clienteId) =>
      _abonos.where((a) => a.clienteId == clienteId).toList();

  List<PedidoModel> pedidosPorCliente(String clienteId) =>
      _pedidos.where((p) => p.cliente.id == clienteId).toList();

  /// Recalcula el estado de un cliente basado en sus pedidos
  /// - 'pendiente' si tiene algún pedido que NO está en estado terminal
  /// - 'atendido' si todos sus pedidos están en estado terminal (Pagado, Anulado) O en estado Atendida
  void _recalcularEstadoCliente(String clienteId) {
    final idx = _clientes.indexWhere((c) => c.id == clienteId);
    if (idx >= 0) {
      final pedidosDelCliente = pedidosPorCliente(clienteId);
      
      // Si no tiene pedidos o tiene pedidos que aún no están en estado terminal
      // Un pedido está "completado" si:
      // - Estado es Pagado O Anulado (estado de pago)
      // - O estado_asignacion es Atendida (estado de entrega)
      final tienePedidosPendientes = pedidosDelCliente.isEmpty ||
          pedidosDelCliente.any((p) => 
            p.estado != EstadoPedido.pagado &&
            p.estado != EstadoPedido.anulado &&
            p.estadoAsignacion != EstadoAsignacionEntrega.atendida
          );

      final nuevoEstado = tienePedidosPendientes 
        ? EstadoCliente.pendiente 
        : EstadoCliente.atendido;
      
      _clientes[idx].estado = nuevoEstado;
    }
  }

  /// Marca un pedido como "Atendida" (actualiza estado_asignacion en entrega_pedidos)
  /// Ahora usa el nuevo endpoint: POST /api/entregas/pedidos/:pedidoId/estado
  Future<void> marcarPedidoAtendido(String pedidoId) async {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0) {
      final estadoAnterior = _pedidos[idx].estadoAsignacion;
      final clienteId = _pedidos[idx].cliente.id;
      
      // Actualizar localmente de inmediato (optimistic UI)
      _pedidos[idx].estadoAsignacion = EstadoAsignacionEntrega.atendida;
      _recalcularEstadoCliente(clienteId); // Recalcular estado del cliente
      notifyListeners();

      // Sincronizar con servidor usando el nuevo endpoint
      if (_token != null) {
        try {
          await _dio.patch(
            '${ApiConfig.entregas}/pedidos/$pedidoId/estado',
            data: {
              'estado_asignacion': 'Atendida',
            },
          );
          // ✅ Éxito - el estado se actualizó correctamente
        } catch (e) {
          // Si falla, revertir el cambio local
          _pedidos[idx].estadoAsignacion = estadoAnterior;
          _recalcularEstadoCliente(clienteId); // Revertir estado del cliente
          notifyListeners();
          // ignore: avoid_print
          print('[AppState] Error marcarPedidoAtendido: $e');
          rethrow;
        }
      }
    }
  }

  /// Marca un pedido como "Entregado" (actualiza estado de entrega)
  /// Usado por repartidores para confirmar entrega
  Future<void> marcarPedidoEntregado(String pedidoId) async {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0) {
      final estadoAnterior = _pedidos[idx].entregado;
      final clienteId = _pedidos[idx].cliente.id;
      
      // Actualizar localmente de inmediato (optimistic UI)
      _pedidos[idx].entregado = true;
      _recalcularEstadoCliente(clienteId);
      notifyListeners();

      // Sincronizar con servidor
      if (_token != null && _esIdDeApi(pedidoId)) {
        try {
          await _dio.patch(
            '${ApiConfig.entregas}/pedidos/$pedidoId/entregado',
            data: {'entregado': true},
          );
          // ✅ Éxito - el pedido se marcó como entregado
        } catch (e) {
          // Si falla, revertir el cambio local
          _pedidos[idx].entregado = estadoAnterior;
          _recalcularEstadoCliente(clienteId);
          notifyListeners();
          // ignore: avoid_print
          print('[AppState] Error marcarPedidoEntregado: $e');
          rethrow;
        }
      }
    }
  }

  /// Marca un cliente como "Atendido en Ruta"
  /// Combinación de marcar cliente atendido y actualizar estado de asignación
  Future<void> marcarClienteAtendidoEnRuta(String clienteId) async {
    try {
      // 1. Cambiar estado del cliente a atendido
      await cambiarEstadoCliente(clienteId, EstadoCliente.atendido);
      
      // 2. Marcar todos sus pedidos de esta ruta como atendidos
      final pedidosCliente = pedidosPorCliente(clienteId);
      for (final pedido in pedidosCliente) {
        if (pedido.estadoAsignacion != EstadoAsignacionEntrega.atendida) {
          await marcarPedidoAtendido(pedido.id);
        }
      }
      
      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print('[AppState] Error marcarClienteAtendidoEnRuta: $e');
      rethrow;
    }
  }

  // Getter para acceder a Dio desde fuera de AppState
  Dio getDio() => _dio;
}