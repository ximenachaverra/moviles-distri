// models/enums
enum UserRole { repartidor, promotor }

enum EstadoCliente {
  pendiente,
  atendido,
  entregado,
  noEntregado;

  String get label {
    switch (this) {
      case EstadoCliente.pendiente:
        return 'Pendiente';
      case EstadoCliente.atendido:
        return 'Atendido';
      case EstadoCliente.entregado:
        return 'Entregado';
      case EstadoCliente.noEntregado:
        return 'No Entregado';
    }
  }

  static EstadoCliente fromString(String s) {
    switch (s.toLowerCase()) {
      case 'atendido':
        return EstadoCliente.atendido;
      case 'entregado':
        return EstadoCliente.entregado;
      case 'noentregado':
        return EstadoCliente.noEntregado;
      default:
        return EstadoCliente.pendiente;
    }
  }
}

enum EstadoPedido {
  pendiente,
  enProceso,
  pendientePorPago,
  pagado,
  anulado;

  String get label {
    switch (this) {
      case EstadoPedido.pendiente:
        return 'Pendiente';
      case EstadoPedido.enProceso:
        return 'En proceso';
      case EstadoPedido.pendientePorPago:
        return 'Pendiente por pago';
      case EstadoPedido.pagado:
        return 'Pagado';
      case EstadoPedido.anulado:
        return 'Anulado';
    }
  }

  static EstadoPedido fromString(String s) {
    switch (s) {
      case 'En proceso':
        return EstadoPedido.enProceso;
      case 'Pendiente por pago':
        return EstadoPedido.pendientePorPago;
      case 'Pagado':
        return EstadoPedido.pagado;
      case 'Anulado':
        return EstadoPedido.anulado;
      default:
        return EstadoPedido.pendiente;
    }
  }
}

// Estado de asignación de entregas (anteriormente era "Atendido" en pedidos)
enum EstadoAsignacionEntrega {
  asignada,
  enTransito,
  atendida,
  rechazada,
  reprogramada;

  String get label {
    switch (this) {
      case EstadoAsignacionEntrega.asignada:
        return 'Asignada';
      case EstadoAsignacionEntrega.enTransito:
        return 'En tránsito';
      case EstadoAsignacionEntrega.atendida:
        return 'Atendida';
      case EstadoAsignacionEntrega.rechazada:
        return 'Rechazada';
      case EstadoAsignacionEntrega.reprogramada:
        return 'Reprogramada';
    }
  }

  static EstadoAsignacionEntrega fromString(String s) {
    switch (s) {
      case 'En tránsito':
        return EstadoAsignacionEntrega.enTransito;
      case 'Atendida':
        return EstadoAsignacionEntrega.atendida;
      case 'Rechazada':
        return EstadoAsignacionEntrega.rechazada;
      case 'Reprogramada':
        return EstadoAsignacionEntrega.reprogramada;
      default:
        return EstadoAsignacionEntrega.asignada;
    }
  }
}

// Estado de ruta (nuevo en esta refactorización)
enum EstadoRuta {
  pendiente,
  enEntrega,
  completada,
  parcial,
  cancelada;

  String get label {
    switch (this) {
      case EstadoRuta.pendiente:
        return 'Pendiente';
      case EstadoRuta.enEntrega:
        return 'En entrega';
      case EstadoRuta.completada:
        return 'Completada';
      case EstadoRuta.parcial:
        return 'Parcial';
      case EstadoRuta.cancelada:
        return 'Cancelada';
    }
  }

  static EstadoRuta fromString(String s) {
    switch (s) {
      case 'En entrega':
        return EstadoRuta.enEntrega;
      case 'Completada':
        return EstadoRuta.completada;
      case 'Parcial':
        return EstadoRuta.parcial;
      case 'Cancelada':
        return EstadoRuta.cancelada;
      default:
        return EstadoRuta.pendiente;
    }
  }
}

double _toDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;

  if (value is num) {
    final numValue = value.toDouble();
    return numValue.isFinite ? numValue : fallback;
  }

  var text = value.toString().trim();
  if (text.isEmpty) return fallback;

  // Keep only number characters and separators used by common locales.
  text = text.replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (text.isEmpty) return fallback;

  if (text.contains(',') && text.contains('.')) {
    // If comma is the last separator, assume EU format: 1.234,56
    if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Assume US format: 1,234.56
      text = text.replaceAll(',', '');
    }
  } else if (text.contains(',')) {
    // One comma can be decimal or thousand separator.
    final parts = text.split(',');
    if (parts.length == 2 && parts.last.length <= 2) {
      text = text.replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '');
    }
  } else if (RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(text)) {
    // Thousand grouping with dots only: 12.345.678
    text = text.replaceAll('.', '');
  }

  final parsed = double.tryParse(text);
  if (parsed == null || !parsed.isFinite) return fallback;
  return parsed;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final UserRole rol;
  final String? telefono;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rol,
    this.telefono,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        apellido: (json['apellido'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        rol: ((json['rol'] ?? '').toString().toLowerCase() == 'promotor')
            ? UserRole.promotor
            : UserRole.repartidor,
        telefono: (json['telefono'] ?? json['celular'])?.toString(),
      );
}

class ClienteModel {
  final String id;
  final String nombre;
  final String zona;
  final String direccion;
  final double lat;
  final double lng;
  final double saldoPendiente;
  EstadoCliente estado;
  final String? observacion;

  ClienteModel({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.direccion,
    required this.lat,
    required this.lng,
    this.saldoPendiente = 0,
    this.estado = EstadoCliente.pendiente,
    this.observacion,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) => ClienteModel(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        zona: (json['zona'] ?? '').toString(),
        direccion: (json['direccion'] ?? '').toString(),
        lat: _toDouble(json['latitud'] ?? json['lat']),
        lng: _toDouble(json['longitud'] ?? json['lng']),
        saldoPendiente:
            _toDouble(json['saldo_pendiente'] ?? json['saldoPendiente']),
        estado: EstadoCliente.fromString((json['estado'] ?? 'pendiente').toString()),
        observacion: json['observacion']?.toString(),
      );
}

class ProductoModel {
  final String id;
  final String nombre;
  final double precio;
  final String? imagen;
  int cantidad;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.precio,
    this.imagen,
    this.cantidad = 0,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) => ProductoModel(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        precio: _toDouble(json['precio']),
        imagen: (json['imagen_url'] ?? json['imagen'])?.toString(),
        cantidad: _toInt(json['cantidad']),
      );

  double get subtotal => precio * cantidad;
}

class AbonoPedido {
  final String id;
  final double monto;
  final String tipo;
  final DateTime fecha;

  AbonoPedido({
    required this.id,
    required this.monto,
    this.tipo = 'Efectivo',
    required this.fecha,
  });

  factory AbonoPedido.fromJson(Map<String, dynamic> json) => AbonoPedido(
        id: (json['id'] ?? '').toString(),
        monto: _toDouble(json['monto']),
        tipo: (json['tipo'] ?? 'Efectivo').toString(),
        fecha: _toDate(json['fecha']),
      );
}

class ItemPedido {
  final ProductoModel producto;
  int cantidad;
  bool checked;

  ItemPedido({
    required this.producto,
    required this.cantidad,
    this.checked = false,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
        producto: ProductoModel(
          id: (json['producto_id'] ?? json['id'] ?? '').toString(),
          nombre: (json['nombre'] ?? '').toString(),
          precio: _toDouble(json['precio_unitario'] ?? json['precio']),
        ),
        cantidad: _toInt(json['cantidad']),
        checked: json['checked'] == true,
      );

  double get subtotal => producto.precio * cantidad;
}

class PedidoModel {
  final String id;
  final ClienteModel cliente;
  late List<ItemPedido> items;
  final DateTime fecha;
  final double? subtotalDb;
  final double? ivaDb;
  final double? totalDb;
  DateTime? fechaEntrega;
  DateTime? fechaModificacion;
  EstadoPedido estado;
  EstadoAsignacionEntrega? estadoAsignacion;
  String origen;
  String observaciones;
  List<AbonoPedido> abonosPedido;
  bool entregado;

  PedidoModel({
    required this.id,
    required this.cliente,
    required List<ItemPedido> items,
    required this.fecha,
    this.subtotalDb,
    this.ivaDb,
    this.totalDb,
    this.fechaEntrega,
    this.fechaModificacion,
    this.estado = EstadoPedido.pendiente,
    this.estadoAsignacion,
    this.origen = 'pedido',
    this.observaciones = '',
    List<AbonoPedido>? abonosPedido,
    this.entregado = false,
  }) : abonosPedido = abonosPedido ?? [] {
    this.items = items;
  }

  factory PedidoModel.fromJson(
    Map<String, dynamic> json, {
    required ClienteModel cliente,
  }) {
    final productos = (json['productos'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ItemPedido.fromJson)
            .toList() ??
        [];

    final abonos = (json['abonos'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(AbonoPedido.fromJson)
            .toList() ??
        [];

    return PedidoModel(
      id: (json['id'] ?? '').toString(),
      cliente: cliente,
      items: productos,
      fecha: _toDate(json['fecha_pedido'] ?? json['fecha']),
      subtotalDb: json['subtotal'] != null ? _toDouble(json['subtotal']) : null,
      ivaDb: json['iva'] != null ? _toDouble(json['iva']) : null,
      totalDb: json['total'] != null ? _toDouble(json['total']) : null,
      fechaEntrega: json['fecha_entrega'] != null
          ? _toDate(json['fecha_entrega'])
          : null,
      estado: EstadoPedido.fromString((json['estado'] ?? '').toString()),
      estadoAsignacion: json['estado_asignacion'] != null
          ? EstadoAsignacionEntrega.fromString((json['estado_asignacion'] ?? '').toString())
          : null,
      origen: (json['origen'] ?? 'pedido').toString(),
      observaciones: (json['observaciones'] ?? '').toString(),
      abonosPedido: abonos,
    );
  }

  double get subtotal => subtotalDb ?? items.fold(0, (sum, item) => sum + item.subtotal);
  double get iva => ivaDb ?? (subtotal * 0.19).roundToDouble();
  double get total => totalDb ?? (subtotal + iva);
  double get totalAbonado => abonosPedido.fold(0, (sum, a) => sum + a.monto);
  double get saldoPendiente => (total - totalAbonado).clamp(0, double.infinity);
}

class AbonoModel {
  final String id;
  final String clienteId;
  final String clienteNombre;
  final double monto;
  final DateTime fecha;
  final String? observacion;
  final String? pedidoId;

  AbonoModel({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.monto,
    required this.fecha,
    this.observacion,
    this.pedidoId,
  });

  factory AbonoModel.fromJson(Map<String, dynamic> json) => AbonoModel(
        id: (json['id'] ?? '').toString(),
        clienteId: (json['cliente_id'] ?? json['clienteId'] ?? '').toString(),
        clienteNombre:
            (json['cliente_nombre'] ?? json['clienteNombre'] ?? '').toString(),
        monto: _toDouble(json['monto']),
        fecha: _toDate(json['fecha']),
        observacion: (json['observacion'] ?? json['tipo'])?.toString(),
        pedidoId: (json['pedido_id'] ?? json['pedidoId'])?.toString(),
      );
}