# Implementación: Estados en Rutas y Entregas (Flutter)

## ✅ Cambios Realizados

### 1. **AppState** (`lib/data/models/app_state.dart`)

#### Nuevo Método: `toggleAtendidoCliente()`
```dart
Future<void> toggleAtendidoCliente(String clienteId, bool atendido)
```
- **Propósito**: Actualizar el estado individual de un cliente en una ruta (Promotor)
- **Endpoint**: `PATCH /api/ruta/:rutaId/clientes/:clienteId/atendido`
- **Payload**: `{'atendido': true/false}`
- **Características**:
  - Actualización optimista (UI se actualiza inmediatamente)
  - Revierte cambios si falla la sincronización con servidor
  - Obtiene rutaId de `_rutaActual`

#### Nuevo Método: `toggleEntregadoPedido()`
```dart
Future<void> toggleEntregadoPedido(String pedidoId, bool entregado)
```
- **Propósito**: Actualizar el estado individual de un pedido en una entrega (Repartidor)
- **Endpoint**: `PATCH /api/entregas/:entregaId/pedidos/:pedidoId/entregado`
- **Payload**: `{'entregado': true/false}`
- **Características**:
  - Actualización optimista (UI se actualiza inmediatamente)
  - Recalcula estado del cliente basado en los pedidos
  - Revierte cambios si falla la sincronización con servidor
  - Obtiene entregaId de `_rutaActual`

### 2. **ClienteCard** (`lib/core/widgets/common_widgets.dart`)

#### Parámetro Nuevo: `onToggleAtendido`
```dart
final Function(bool)? onToggleAtendido;
```

#### UI Mejorada:
- **Cliente Pendiente**: Muestra botón "Marcar" (naranja) para toggle a atendido
- **Cliente Atendido**: Muestra badge "Atendido" (verde), clickeable para revertir a pendiente
- El botón es interceptable (GestureDetector) para permitir toggle rápido sin abrir detalle

### 3. **PromotorHomeScreen** (`lib/presentation/pages/promotor/promotor_home_screen.dart`)

#### Cambio: Pasar callback `onToggleAtendido`
```dart
ClienteCard(
  cliente: cliente,
  onTap: () => Navigator.push(...),  // Abrir detalle
  onToggleAtendido: (atendido) async {
    await context.read<AppState>().toggleAtendidoCliente(cliente.id, atendido);
    // Mostrar feedback al usuario
  },
)
```

#### Resultado:
- Promotor puede hacer click directo en "Marcar" o "Atendido" para toggle rápido
- Sin necesidad de abrir detalle del cliente
- Snackbar con confirmación

### 4. **PromotorDetalleScreen** (`lib/presentation/pages/promotor/promotor_detalle_screen.dart`)

#### Cambio: Botón "ATENDIDO" mejorado
- **Anterior**: Abría diálogo de "¿Recibió abono?"
- **Ahora**: Usa `toggleAtendidoCliente()` directamente
- **Comportamiento**:
  - Atendido → Pendiente (click revierte)
  - Pendiente → Atendido (click marca)
  - Si se marca como atendido, vuelve atrás después de 1 segundo
  - Usa Consumer para obtener estado actualizado

### 5. **RepartidorDetalleScreen** (`lib/presentation/pages/repartidor/repartidor_detalle_screen.dart`)

#### Cambio: Botón "Entregado" mejorado
- **Anterior**: Llamaba a `_marcarEntregado()` (método eliminado)
- **Ahora**: Usa `toggleEntregadoPedido()` directamente
- **Comportamiento**:
  - Similar a Promotor: toggle entre entregado/pendiente
  - Recalcula estado del cliente
  - Si se marca como entregado, vuelve atrás después de 1 segundo
  - Usa Consumer para obtener estado actualizado del pedido

#### Cambio: Método `_marcarEntregado()` removido
- Ya no necesario con la nueva lógica de toggle

## 🔄 Flujo de Trabajo

### Para Promotor (Rutas):
1. **Pantalla Principal**: Ver lista de clientes con estado visual
2. **Toggle Rápido**: 
   - Click en "Marcar" → Cliente pasa a atendido (verde)
   - Click en "Atendido" → Cliente pasa a pendiente
3. **Detalle**:
   - Click en cliente abre detalle
   - Botón "ATENDIDO" en la parte inferior permite toggle

### Para Repartidor (Entregas):
1. **Pantalla Principal**: Ver lista de clientes con progreso
2. **Detalle**:
   - Click en cliente abre detalle con pedidos
   - Botón "Entregado" permite toggle del pedido
   - Recalcula automáticamente estado general

## 📊 Indicadores Visuales

### Cliente/Pedido Pendiente:
- Avatar: Icono gris (store/package)
- Border: Gris claro
- Badge: "Marcar" (naranja con border)

### Cliente/Pedido Atendido:
- Avatar: Check circle verde
- Border: Verde claro, más grueso
- Badge: "Atendido" (verde sólido) o "Entregado" (verde sólido)
- Background: Verde muy claro (transparencia)

## 🧪 Pruebas Manuales

### Test 1: Toggle desde Pantalla Principal (Promotor)
1. Ir a Rutas (Promotor)
2. Click en "Marcar" de un cliente pendiente
3. ✅ Cliente cambia a atendido (verde)
4. ✅ Snackbar muestra confirmación
5. Click en "Atendido" del mismo cliente
6. ✅ Cliente cambia a pendiente (gris)

### Test 2: Toggle desde Detalle (Promotor)
1. Ir a Rutas → Click en cliente
2. En detalle, click botón "ATENDIDO"
3. ✅ Cliente se marca como atendido
4. ✅ Después de 1 seg, pantalla vuelve atrás
5. ✅ En lista, cliente aparece como atendido

### Test 3: Toggle Pedido (Repartidor)
1. Ir a Entregas → Click en cliente
2. En detalle, click botón "Entregado"
3. ✅ Pedido se marca como entregado
4. ✅ Color del botón cambia a verde
5. ✅ Después de 1 seg, pantalla vuelve atrás

### Test 4: Cálculo Automático de Estado General
1. Promotor/Repartidor con 3 clientes/pedidos
2. Marcar como atendido/entregado: 1, 2, 3
3. ✅ Barra de progreso actualiza: 33%, 66%, 100%
4. ✅ Cuando 100%, se muestra "Completada"

### Test 5: Error Handling
1. Desconectar la red o simular error
2. Click en toggle
3. ✅ Snackbar muestra error
4. ✅ UI revierte a estado anterior
5. ✅ App no se congela

### Test 6: Persistencia de Datos
1. Marcar cliente/pedido como atendido
2. Cerrar y reabrir la app
3. ✅ Estado persiste (servidor lo guardó)
4. ✅ No hay pérdida de datos

## 📝 Notas Técnicas

- **Optimistic UI**: Cambios se muestran inmediatamente, se sincronizan en background
- **Revert on Error**: Si servidor rechaza, UI vuelve a estado anterior
- **Endpoints**: Requieren rutaId/entregaId que se obtienen de `_rutaActual`
- **Backend Esperado**: 
  - PATCH `/api/ruta/:rutaId/clientes/:clienteId/atendido` → Promotor
  - PATCH `/api/entregas/:entregaId/pedidos/:pedidoId/entregado` → Repartidor

## ⚠️ Posibles Problemas

### 1. "Ruta ID no disponible"
- **Causa**: `_rutaActual` no está cargado o es null
- **Solución**: Asegurar que `fetchClientes()` carga la ruta correctamente

### 2. Botón no responde
- **Causa**: Estado no se está actualizando
- **Solución**: Verificar que `notifyListeners()` se llama después de cambios

### 3. Error al compilar
- **Causa**: Imports faltantes
- **Solución**: `import 'package:provider/provider.dart'` debe estar presente

## 🔮 Mejoras Futuras

1. **Batch Operations**: Marcar múltiples clientes/pedidos a la vez
2. **Undo**: Deshacer último cambio sin recargar
3. **Sync Indicator**: Mostrar indicador mientras sincroniza
4. **Long Press Menu**: Menú con opciones adicionales
5. **Animations**: Transiciones suaves al cambiar estado

---

**Fecha**: 2026-06-03  
**Versión**: 1.0  
**Status**: ✅ Implementado
