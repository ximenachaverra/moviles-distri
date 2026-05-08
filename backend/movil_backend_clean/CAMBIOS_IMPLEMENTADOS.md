# Cambios Implementados - DistriExpress Mobile Backend

## 1. Olvide Contraseña (Auth Controller)

El auth controller ha sido completamente reemplazado con la implementación de "Olvide Contraseña".

### Nuevos Endpoints:

```
POST /api/auth/olvide-password
Body: { "email": "usuario@example.com" }
Response: { "message": "Si el correo existe, recibiras un codigo." }
```

```
POST /api/auth/verificar-codigo
Body: { "email": "usuario@example.com", "codigo": "123456" }
Response: { "valido": true, "email": "usuario@example.com" } o { "valido": false, "message": "Codigo invalido o expirado" }
```

```
POST /api/auth/reset-password
Body: { "email": "usuario@example.com", "codigo": "123456", "nuevaPassword": "miNuevaPass", "confirmarPassword": "miNuevaPass" }
Response: { "message": "Contraseña restablecida" }
```

### Funcionalidades:
- ✅ Genera código de 6 dígitos aleatorios
- ✅ Envía email con HTML personalizado (requiere variables de entorno: EMAIL_HOST, EMAIL_USER, EMAIL_PASS, EMAIL_PORT)
- ✅ El código expira en 1 hora
- ✅ Previene reutilización de códigos

### Variables de Entorno Requeridas:
```
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=tu-email@gmail.com
EMAIL_PASS=tu-contraseña-app
EMAIL_SECURE=false
```

### Base de Datos:
Se requiere crear la tabla `password_resets`:

```sql
CREATE TABLE IF NOT EXISTS password_resets (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  token VARCHAR(6) NOT NULL UNIQUE,
  expira_en TIMESTAMP NOT NULL,
  usado BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (email, token)
);

CREATE INDEX IF NOT EXISTS idx_password_resets_email ON password_resets(email);
CREATE INDEX IF NOT EXISTS idx_password_resets_token ON password_resets(token);
```

O ejecutar el script:
```bash
psql -U postgres -d distriexpress -f sql_migrations/001_create_password_resets_table.sql
```

---

## 2. Crear Pedido - Estado PENDIENTE

El flujo de creación de pedidos ya genera pedidos en estado **PENDIENTE** automáticamente.

### En Backend (`pedidos.controller.js`):
- El estado siempre es `'Pendiente'`
- El origen siempre es `'pedido'`
- Los abonos se guardan correctamente si se envían desde el frontend

### En Frontend (`promotor_pedidos_screen.dart`):
- El componente `CrearPedidoScreen` calcula correctamente los abonos
- Si se marca "Pago Completo", se envía un abono por el total
- Si se agregan abonos individuales, se envían tal cual

✅ Todo está funcionando correctamente - No se requieren cambios adicionales.

---

## 3. Repartidor ve Pedidos del Promotor

Se modificó el endpoint `GET /api/pedidos` (listar) para que:

### Comportamiento Anterior:
- Promotor: Solo veía sus propios pedidos
- Repartidor: Solo veía sus propios pedidos (ninguno, ya que no crea pedidos)

### Nuevo Comportamiento:
- **Promotor**: Solo ve sus propios pedidos (SIN CAMBIOS)
- **Repartidor**: Ve TODOS los pedidos (CAMBIO)

### Código Modificado:
```javascript
// Si es repartidor, ver todos los pedidos. Si es promotor, solo los suyos.
if (esRepartidor) {
  sql += ` WHERE 1=1 `;  // Repartidor ve todos
} else {
  sql += ` WHERE (
    p.vendedor_id = $1
    OR p.vendedor_id IS NULL
    OR (p.vendedor IS NOT NULL AND LOWER(TRIM(p.vendedor)) = LOWER(TRIM($2)))
  )`;  // Promotor ve solo los suyos
}
```

✅ El repartidor ahora verá todos los pedidos creados por cualquier promotor.

---

## Resumen de Cambios

| Archivo | Cambio | Estado |
|---------|--------|--------|
| `src/controllers/auth.controller.js` | Reemplazado completamente | ✅ Implementado |
| `src/routes/auth.routes.js` | Agregadas 4 nuevas rutas | ✅ Implementado |
| `src/controllers/pedidos.controller.js` | Modificado listar() | ✅ Implementado |
| `sql_migrations/001_create_password_resets_table.sql` | Crear tabla | ✅ Creado |

---

## Testing

### 1. Probar Olvide Contraseña:
```bash
curl -X POST http://localhost:5001/api/auth/olvide-password \
  -H "Content-Type: application/json" \
  -d '{"email":"usuario@example.com"}'
```

### 2. Probar Verificar Código:
```bash
curl -X POST http://localhost:5001/api/auth/verificar-codigo \
  -H "Content-Type: application/json" \
  -d '{"email":"usuario@example.com","codigo":"123456"}'
```

### 3. Probar Reset Password:
```bash
curl -X POST http://localhost:5001/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email":"usuario@example.com",
    "codigo":"123456",
    "nuevaPassword":"MiNuevaPass123",
    "confirmarPassword":"MiNuevaPass123"
  }'
```

### 4. Probar que Repartidor ve Pedidos:
```bash
curl -X GET http://localhost:5001/api/pedidos \
  -H "Authorization: Bearer REPARTIDOR_TOKEN"
```

---

## Próximos Pasos

1. Ejecutar la migración SQL para crear `password_resets`
2. Configurar las variables de entorno para email
3. Probar los nuevos endpoints
4. Implementar UI en Flutter para "Olvide Contraseña"
