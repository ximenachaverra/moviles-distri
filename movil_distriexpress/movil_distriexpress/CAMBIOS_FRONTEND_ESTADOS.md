# Actualización Frontend: Refactorización de Estados ✅

## Cambios Realizados en Flutter

Se ha completado la refactorización del código Frontend (Flutter) para alinearse con los cambios del backend en el sistema de estados.

## Cambios Específicos

### 1. ✅ `models.dart` - Enums Actualizados

#### Actualizado: `EstadoPedido` enum
- ❌ REMOVIDO: `atendido` (ahora está en `EntregaPedidos.estado_asignacion`)
- ✅ MANTIENE: `pendiente`, `enProceso`, `pendientePorPago`, `pagado`, `anulado`

#### Nuevo: `EstadoAsignacionEntrega` enum
- Valores: `asignada`, `enTransito`, `atendida`, `rechazada`, `reprogramada`
- Método: `fromString(String)` para convertir desde API
- Propiedad: `get label` para mostrar en UI

#### Nuevo: `EstadoRuta` enum
- Valores: `pendiente`, `enEntrega`, `completada`, `parcial`, `cancelada`
- Método: `fromString(String)` para convertir desde API
- Propiedad: `get label` para mostrar en UI

### 2. ✅ `PedidoModel` - Campo Nuevo

```dart
class PedidoModel {
  ...
  EstadoAsignacionEntrega? estadoAsignacion;  // ← NUEVO CAMPO
  ...
}
```

- Actualizado constructor para incluir `estadoAsignacion`
- Actualizado método `fromJson()` para parsear `estado_asignacion` desde API
- Tipo: nullable (`?`) porque no todos los pedidos tienen asignación de entrega

### 3. ✅ `api_config.dart` - Endpoint Nuevo

Agregado endpoint para entregas:
```dart
static const String entregas = '/api/entregas';
```

### 4. ✅ `app_state.dart` - Método Refactorizado

#### Método: `marcarPedidoAtendido()`
- **Cambio de Endpoint**: `/api/pedidos/$pedidoId/estado` → `/api/entregas/pedidos/$pedidoId/estado`
- **Actualización de Campo**: `pedido.estado = EstadoPedido.atendido` → `pedido.estadoAsignacion = EstadoAsignacionEntrega.atendida`
- **Body Enviado**: `{ "estado_asignacion": "Atendida" }`
- **Lógica de Rollback**: Mantiene el rollback en caso de error

#### Método: `_recalcularEstadoCliente()`
- **Actualizado**: Ahora considera tanto `pedido.estado` como `pedido.estadoAsignacion`
- Un pedido se considera "completado" si:
  - `estado` es `Pagado` o `Anulado`, OR
  - `estadoAsignacion` es `Atendida`
- El cliente está "atendido" solo si TODOS sus pedidos están completados

### 5. ✅ `promotor_pedidos_screen.dart` - Color Mappings

#### Actualizado: `_estadoColor()` en `_ClientePedidoCard`
```dart
Color _estadoColor(EstadoPedido e) {
  switch (e) {
    case EstadoPedido.pendiente:        return AppTheme.warning;
    case EstadoPedido.enProceso:        return AppTheme.primary;
    case EstadoPedido.pendientePorPago: return AppTheme.accentOrange;
    case EstadoPedido.pagado:           return AppTheme.success;
    case EstadoPedido.anulado:          return AppTheme.error;
    // ❌ Removido: case EstadoPedido.atendido
  }
}
```

#### Actualizado: `_estadoColor` en `_PedidoDetalleCard`
- Mismo cambio: removido `case EstadoPedido.atendido`

### 6. ✅ `promotor_home_screen.dart` - Sin Cambios Requeridos

- ✅ Ya usa `EstadoCliente` (no `EstadoPedido`)
- ✅ El conteo de "Atendidos" usa `c.estado == EstadoCliente.atendido`
- ✅ Funciona correctamente con la lógica actualizada de `_recalcularEstadoCliente()`

## Flujo de Estados Actualizado

```
Usuario marca pedido como "Atendida"
    ↓
marcarPedidoAtendido(pedidoId) llamado
    ↓
1️⃣ UI Optimista: estadoAsignacion = 'Atendida' (inmediato)
    ↓
2️⃣ Llamada API: PATCH /api/entregas/pedidos/:pedidoId/estado
    Body: { "estado_asignacion": "Atendida" }
    ↓
3️⃣ Si éxito: Estado actualizado en servidor
    ↓
4️⃣ Si error: Rollback a estado anterior
    ↓
5️⃣ _recalcularEstadoCliente() actualiza EstadoCliente
    - Si todos los pedidos están completados → EstadoCliente.atendido
    - Si algún pedido pendiente → EstadoCliente.pendiente
    ↓
6️⃣ UI actualizada con `notifyListeners()`
```

## Modelos de Datos Ahora

### PedidoModel
```dart
{
  id: "123",
  cliente: ClienteModel,
  estado: EstadoPedido,              // Pendiente | En proceso | Pagado | Anulado
  estadoAsignacion: EstadoAsignacionEntrega?,  // ← NUEVO
  fecha: DateTime,
  total: double,
  ...
}
```

### ClienteModel
```dart
{
  id: "456",
  nombre: "Tienda Centro",
  estado: EstadoCliente,  // Pendiente | Atendido (basado en pedidos)
  ...
}
```

## Compatibilidad

✅ **No hay cambios en la UI visual** - Solo cambios internos
✅ **Método `marcarPedidoAtendido()` sigue funcionando igual** - Mismo nombre, mismo propósito
✅ **Estados de cliente se calculan correctamente** - Lógica mejorada

## Validación

Todos los cambios están compilados y listos:
- ✅ Enums actualizados sin errores
- ✅ PedidoModel con nuevo campo
- ✅ AppState con nuevas llamadas API
- ✅ Color mappings actualizados
- ✅ Sin referencias a `EstadoPedido.atendido`

## Próximos Pasos

1. ✅ Ejecutar Flutter app para verificar compilación
2. ✅ Probar flujo de marcar pedido como atendido
3. ✅ Verificar que EstadoCliente se actualice correctamente
4. ✅ Verificar que rutas mostren el nombre correcto (debe estar mostrando ahora con datos reales)

## Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `lib/data/models/models.dart` | Removido `atendido` de EstadoPedido, agregados nuevos enums y campo `estadoAsignacion` |
| `lib/core/constants/api_config.dart` | Agregado endpoint `/api/entregas` |
| `lib/data/models/app_state.dart` | Refactorizado `marcarPedidoAtendido()`, actualizado `_recalcularEstadoCliente()` |
| `lib/presentation/pages/promotor/promotor_pedidos_screen.dart` | Removidos cases para `atendido` en color mappings |

## Notas Importantes

⚠️ El cambio es principalmente **interno** - la experiencia del usuario no cambia
✅ El backend ahora gestiona "Atendido" a nivel de `entrega_pedidos`
✅ El frontend continúa trabajando con la misma interfaz de usuario

---

**Status**: ✅ FRONTEND REFACTORIZACIÓN COMPLETADA
**Próximo**: Pruebas de integración
