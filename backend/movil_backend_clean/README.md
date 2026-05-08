# DistriExpress — Móvil Backend

API REST exclusiva para la app Flutter de **promotores** y **repartidores**.  
Comparte la misma base de datos PostgreSQL que el backend web, pero corre en un proceso y puerto separado.

---

## Requisitos

- Node.js ≥ 18
- La misma base de datos PostgreSQL del backend web

---

## Instalación

```bash
npm install
cp .env.example .env
# Edita .env con los datos de tu BD y el mismo JWT_SECRET del backend web
npm run dev   # desarrollo
npm start     # producción
```

> **Importante:** usa el **mismo `JWT_SECRET`** que el backend web.  
> Así un token generado en la web también funciona en la app móvil.

---

## Endpoints

### Autenticación

| Método | Ruta               | Descripción                                 | Auth |
|--------|--------------------|---------------------------------------------|------|
| POST   | `/api/auth/login`  | Login (solo promotor y repartidor)          | ❌   |
| GET    | `/api/auth/perfil` | Datos del usuario autenticado               | ✅   |
| PUT    | `/api/auth/perfil` | Actualizar nombre, apellido, celular        | ✅   |

**Body login:**
```json
{ "email": "juan@example.com", "password": "12345678" }
```
**Respuesta login:**
```json
{
  "token": "eyJ...",
  "usuario": {
    "id": 1, "nombre": "Juan", "apellido": "García",
    "email": "juan@example.com", "rol": "Repartidor"
  }
}
```

---

### Ruta del día

| Método | Ruta                                    | Descripción                              | Auth |
|--------|-----------------------------------------|------------------------------------------|------|
| GET    | `/api/ruta`                             | Ruta asignada + clientes + pedidos       | ✅   |
| GET    | `/api/ruta/cliente/:clienteId/pedidos`  | Pedidos activos de un cliente            | ✅   |

**Respuesta `/api/ruta`:**
```json
{
  "ruta": { "id": 1, "nombre": "Ruta Norte", "vendedor": "Juan García" },
  "clientes": [
    {
      "id": 5, "nombre": "Tienda El Sol", "direccion": "Calle 10 #5-20",
      "latitud": 6.2442, "longitud": -75.5812,
      "saldo_pendiente": 45000,
      "pedidos": [{ "id": 12, "estado": "Pendiente", "total": 120000, ... }]
    }
  ]
}
```

---

### Pedidos

| Método | Ruta                         | Descripción                                   | Rol              |
|--------|------------------------------|-----------------------------------------------|------------------|
| GET    | `/api/pedidos`               | Lista pedidos del vendedor (`?estado=&fecha=`) | Ambos            |
| GET    | `/api/pedidos/:id`           | Detalle de un pedido                          | Ambos            |
| POST   | `/api/pedidos`               | Crear pedido nuevo                            | Solo promotor    |
| PATCH  | `/api/pedidos/:id/check`     | Marcar/desmarcar producto entregado           | Ambos            |
| POST   | `/api/pedidos/:id/abono`     | Agregar abono a un pedido                     | Ambos            |

**Body crear pedido:**
```json
{
  "clienteId": 5,
  "clienteNombre": "Tienda El Sol",
  "clienteTelefono": "3001234567",
  "clienteDireccion": "Calle 10 #5-20",
  "fechaEntrega": "2024-02-20",
  "observaciones": "Entregar antes del mediodía",
  "productos": [
    { "id": 3, "nombre": "Arroz 500g", "precio": 2500, "cantidad": 10 }
  ],
  "abonos": [
    { "monto": 10000, "tipo": "Efectivo" }
  ]
}
```

**Body check producto:**
```json
{ "productoId": 3, "checked": true }
```
> `checked: true` = entregado (descuenta stock)  
> `checked: false` = revertir (devuelve stock)

**Body agregar abono:**
```json
{ "monto": 25000, "tipo": "Efectivo" }
```
> `tipo` puede ser: `"Efectivo"` o `"Transferencia"`

---

### Abonos

| Método | Ruta                             | Descripción                        | Auth |
|--------|----------------------------------|------------------------------------|------|
| GET    | `/api/abonos`                    | Abonos de hoy del usuario (`?fecha=`) | ✅   |
| GET    | `/api/abonos/resumen`            | Total cobrado hoy (para home)      | ✅   |
| GET    | `/api/abonos/cliente/:clienteId` | Historial de abonos de un cliente  | ✅   |

---

### Clientes

| Método | Ruta                | Descripción                             | Auth |
|--------|---------------------|-----------------------------------------|------|
| GET    | `/api/clientes`     | Lista clientes activos (`?q=busqueda`)  | ✅   |
| GET    | `/api/clientes/:id` | Detalle con saldo pendiente             | ✅   |

---

### Productos

| Método | Ruta              | Descripción                              | Auth |
|--------|-------------------|------------------------------------------|------|
| GET    | `/api/productos`  | Catálogo con stock > 0 (`?q=busqueda`)   | ✅   |

---

## Flujo de la app

### Repartidor
1. `POST /api/auth/login` → obtiene token
2. `GET /api/ruta` → carga la ruta del día con clientes y pedidos
3. Por cada cliente: `PATCH /api/pedidos/:id/check` → marca productos entregados
4. Si el cliente paga: `POST /api/pedidos/:id/abono` → registra el abono
5. `GET /api/abonos/resumen` → consulta total cobrado en el día

### Promotor
1. `POST /api/auth/login` → obtiene token
2. `GET /api/ruta` → ve su lista de clientes
3. `GET /api/clientes?q=nombre` → busca un cliente
4. `GET /api/productos` → selecciona productos
5. `POST /api/pedidos` → crea el pedido
6. `POST /api/pedidos/:id/abono` → registra abono si el cliente paga algo

---

## Lógica de estados del pedido

Los estados se calculan automáticamente en `checkProducto` y `agregarAbono`:

| Situación                                    | Estado              | Origen  |
|----------------------------------------------|---------------------|---------|
| Sin productos marcados                        | Pendiente           | pedido  |
| Algunos productos marcados                    | En proceso          | pedido  |
| Todos marcados, sin abono                     | Pendiente por pago  | pedido  |
| Todos marcados, con abono parcial             | Pendiente por pago  | venta   |
| Todos marcados, pagado completo               | Pagado              | venta   |
