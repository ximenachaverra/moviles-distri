const { query, pool } = require('../config/database');

// Fecha actual en zona horaria Colombia
const fechaCO = () =>
  new Date().toLocaleDateString('en-CA', { timeZone: 'America/Bogota' });

// Normaliza distintos formatos de fecha a YYYY-MM-DD
const normFecha = (f) => {
  if (!f) return null;
  if (/^\d{4}-\d{2}-\d{2}/.test(f)) return f.substring(0, 10);
  try {
    return new Date(f).toISOString().substring(0, 10);
  } catch {
    return null;
  }
};

// Calcula el estado y origen del pedido basado en checkboxes y abonos.
// Esta lógica es idéntica al backend web para mantener consistencia.
const calcularEstadoOrigen = (allChecked, anyChecked, totalAbonado, totalPedido) => {
  if (allChecked) {
    if (totalAbonado >= totalPedido) {
      return { estado: 'Pagado', origen: 'venta' };
    } else if (totalAbonado > 0) {
      return { estado: 'Pendiente por pago', origen: 'venta' };
    } else {
      return { estado: 'Pendiente por pago', origen: 'pedido' };
    }
  } else if (anyChecked) {
    return { estado: 'En proceso', origen: 'pedido' };
  } else {
    return { estado: 'Pendiente', origen: 'pedido' };
  }
};

// ── GET /api/movil/pedidos ────────────────────────────────────────────────────
// Lista los pedidos del promotor autenticado o TODOS si es repartidor.
// Parámetros opcionales: ?estado=Pendiente&fecha=2024-01-15
exports.listar = async (req, res, next) => {
  try {
    const { estado, fecha } = req.query;
    const vendedorNombre = `${req.user.nombre} ${req.user.apellido}`.trim();
    
    // Normalizar rol del usuario
    const rol = String(req.user.rol_nombre || '').toLowerCase();
    const esRepartidor = rol.includes('repartidor') || rol.includes('domiciliario');

    let sql = `
      SELECT p.*,
             COALESCE(SUM(a.monto), 0)            AS total_abonado,
             p.total - COALESCE(SUM(a.monto), 0)  AS saldo_pendiente
      FROM pedidos p
      LEFT JOIN abonos a ON a.pedido_id = p.id
    `;
    
    const params = [];
    
    // Si es repartidor, ver todos los pedidos. Si es promotor, solo los suyos.
    if (esRepartidor) {
      // El repartidor ve todos los pedidos
      sql += ` WHERE 1=1 `;
    } else {
      // El promotor solo ve sus pedidos
      sql += ` WHERE (
        p.vendedor_id = $1
        OR p.vendedor_id IS NULL
        OR (p.vendedor IS NOT NULL AND LOWER(TRIM(p.vendedor)) = LOWER(TRIM($2)))
      )`;
      params.push(req.user.id, vendedorNombre);
    }
    
    let paramIndex = params.length + 1;
    
    if (estado) {
      params.push(estado);
      sql += ` AND p.estado = $${paramIndex}`;
      paramIndex++;
    }

    if (fecha) {
      params.push(fecha);
      sql += ` AND p.fecha_pedido = $${paramIndex}`;
    }

    sql += ` GROUP BY p.id ORDER BY p.fecha_pedido DESC, p.id DESC`;

    const { rows: pedidos } = await query(sql, params);

    // Agrega productos y abonos a cada pedido
    for (const pedido of pedidos) {
      const [prods, abonos] = await Promise.all([
        query(`SELECT * FROM pedido_productos WHERE pedido_id = $1`, [pedido.id]),
        query(`SELECT * FROM abonos WHERE pedido_id = $1 ORDER BY fecha`, [pedido.id]),
      ]);
      pedido.productos = prods.rows;
      pedido.abonos = abonos.rows;
    }

    res.json(pedidos);
  } catch (e) {
    next(e);
  }
};

// ── GET /api/movil/pedidos/:id ────────────────────────────────────────────────
// Detalle de un pedido específico con sus productos y abonos.
exports.obtener = async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT p.*,
              COALESCE(SUM(a.monto), 0)            AS total_abonado,
              p.total - COALESCE(SUM(a.monto), 0)  AS saldo_pendiente
       FROM pedidos p
       LEFT JOIN abonos a ON a.pedido_id = p.id
       WHERE p.id = $1
       GROUP BY p.id`,
      [req.params.id]
    );

    if (!rows[0]) {
      return res.status(404).json({ error: 'Pedido no encontrado' });
    }

    const pedido = rows[0];
    const [prods, abonos] = await Promise.all([
      query(`SELECT * FROM pedido_productos WHERE pedido_id = $1`, [pedido.id]),
      query(`SELECT * FROM abonos WHERE pedido_id = $1 ORDER BY fecha`, [pedido.id]),
    ]);
    pedido.productos = prods.rows;
    pedido.abonos = abonos.rows;

    res.json(pedido);
  } catch (e) {
    next(e);
  }
};

// ── POST /api/movil/pedidos ───────────────────────────────────────────────────
// Crea un nuevo pedido desde la app del promotor.
// Solo el promotor puede crear pedidos; siempre se crean en estado Pendiente/pedido.
exports.crear = async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `SET search_path TO ${process.env.DB_SCHEMA || 'distriexpress'}, public`
    );

    const {
      clienteId,
      clienteNombre,
      clienteTelefono,
      clienteDireccion,
      fechaEntrega,
      observaciones,
      productos,
      abonos,
    } = req.body;

    // Validaciones básicas
    if (!clienteNombre) {
      return res.status(400).json({ error: 'Nombre del cliente requerido' });
    }
    if (!productos || !productos.length) {
      return res.status(400).json({ error: 'Agrega al menos un producto' });
    }

    // Verifica stock disponible para todos los productos
    for (const p of productos) {
      const { rows: stk } = await client.query(
        `SELECT stock, nombre FROM productos WHERE id = $1`,
        [p.id]
      );
      if (!stk[0]) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `Producto "${p.nombre}" no encontrado` });
      }
      if (stk[0].stock < p.cantidad) {
        await client.query('ROLLBACK');
        return res.status(400).json({
          error: `Stock insuficiente para "${stk[0].nombre}". Disponible: ${stk[0].stock}, Solicitado: ${p.cantidad}`,
        });
      }
    }

    // Calcula totales
    const subtotal = productos.reduce((s, p) => s + p.precio * p.cantidad, 0);
    const iva      = Math.round(subtotal * 0.19);
    const total    = subtotal + iva;

    // Validación: fechaEntrega no puede ser anterior a la fecha actual
    const fechaNorm = normFecha(fechaEntrega);
    if (fechaNorm && fechaNorm < fechaCO()) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'La fecha de entrega no puede ser anterior a hoy' });
    }

    // Los pedidos creados desde la app siempre nacen como Pendiente/pedido
    // (el repartidor los irá marcando durante la entrega)
    const estado = 'Pendiente';
    const origen = 'pedido';

    // Nombre del vendedor = nombre completo del usuario autenticado
    const vendedor = `${req.user.nombre} ${req.user.apellido}`;

    // Inserta el pedido
    const { rows } = await client.query(
      `INSERT INTO pedidos
         (cliente_id, cliente_nombre, cliente_telefono, cliente_direccion,
          vendedor, vendedor_id, fecha_pedido, fecha_entrega,
          subtotal, iva, total, estado, origen, observaciones)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
       RETURNING *`,
      [
        clienteId || null,
        clienteNombre,
        clienteTelefono,
        clienteDireccion,
        vendedor,
        req.user.id,
        fechaCO(),
        normFecha(fechaEntrega),
        subtotal,
        iva,
        total,
        estado,
        origen,
        observaciones,
      ]
    );

    const pedido = rows[0];

    // Inserta los productos del pedido (sin descontar stock aún)
    for (const p of productos) {
      await client.query(
        `INSERT INTO pedido_productos
           (pedido_id, producto_id, nombre, precio_unitario, cantidad, subtotal, checked)
         VALUES ($1,$2,$3,$4,$5,$6,false)`,
        [pedido.id, p.id, p.nombre, p.precio, p.cantidad, p.precio * p.cantidad]
      );
    }

    // Inserta abonos iniciales si los hay
    if (abonos && abonos.length) {
      for (const a of abonos) {
        await client.query(
          `INSERT INTO abonos (pedido_id, monto, tipo, fecha) VALUES ($1,$2,$3,$4)`,
          [pedido.id, a.monto, a.tipo || 'Efectivo', fechaCO()]
        );
      }
    }

    await client.query('COMMIT');

    pedido.productos = productos;
    pedido.abonos    = abonos || [];

    res.status(201).json(pedido);
  } catch (e) {
    await client.query('ROLLBACK');
    next(e);
  } finally {
    client.release();
  }
};

// ── PATCH /api/movil/pedidos/:id/check ───────────────────────────────────────
// Marca o desmarca un producto como entregado durante la ruta del repartidor.
// Descuenta o devuelve stock automáticamente y recalcula el estado del pedido.
exports.checkProducto = async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `SET search_path TO ${process.env.DB_SCHEMA || 'distriexpress'}, public`
    );

    const pedidoId  = req.params.id;
    const { productoId, checked } = req.body;

    // Verifica que el producto esté en el pedido
    const { rows: ppRows } = await client.query(
      `SELECT * FROM pedido_productos WHERE pedido_id = $1 AND producto_id = $2`,
      [pedidoId, productoId]
    );

    if (!ppRows[0]) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Producto no encontrado en este pedido' });
    }

    // Si el estado ya es el mismo, no hace nada
    if (ppRows[0].checked === checked) {
      await client.query('ROLLBACK');
      return res.json({ message: 'Sin cambios' });
    }

    const { rows: prodRows } = await client.query(
      `SELECT stock, nombre FROM productos WHERE id = $1`,
      [productoId]
    );

    if (!prodRows[0]) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Producto no existe' });
    }

    // Marcar = entregar → descontar stock
    // Desmarcar = revertir → devolver stock
    if (checked) {
      if (prodRows[0].stock < ppRows[0].cantidad) {
        await client.query('ROLLBACK');
        return res.status(400).json({
          error: `Stock insuficiente para "${prodRows[0].nombre}". Disponible: ${prodRows[0].stock}`,
        });
      }
      await client.query(
        `UPDATE productos SET stock = stock - $1 WHERE id = $2`,
        [ppRows[0].cantidad, productoId]
      );
    } else {
      await client.query(
        `UPDATE productos SET stock = stock + $1 WHERE id = $2`,
        [ppRows[0].cantidad, productoId]
      );
    }

    // Actualiza el check en pedido_productos
    await client.query(
      `UPDATE pedido_productos SET checked = $1 WHERE pedido_id = $2 AND producto_id = $3`,
      [checked, pedidoId, productoId]
    );

    // Recalcula estado/origen con los nuevos valores
    const { rows: todosProds } = await client.query(
      `SELECT checked FROM pedido_productos WHERE pedido_id = $1`,
      [pedidoId]
    );
    const allChecked = todosProds.length > 0 && todosProds.every((p) => p.checked);
    const anyChecked = todosProds.some((p) => p.checked);

    const { rows: pedidoRows } = await client.query(
      `SELECT total FROM pedidos WHERE id = $1`,
      [pedidoId]
    );
    const { rows: abonoRows } = await client.query(
      `SELECT COALESCE(SUM(monto), 0) AS total FROM abonos WHERE pedido_id = $1`,
      [pedidoId]
    );

    const totalAbonado = parseFloat(abonoRows[0].total);
    const { estado, origen } = calcularEstadoOrigen(
      allChecked,
      anyChecked,
      totalAbonado,
      parseFloat(pedidoRows[0].total)
    );

    // Actualiza estado y origen del pedido
    await client.query(
      `UPDATE pedidos SET estado = $1, origen = $2 WHERE id = $3`,
      [estado, origen, pedidoId]
    );

    await client.query('COMMIT');

    res.json({ message: 'OK', estado, origen });
  } catch (e) {
    await client.query('ROLLBACK');
    next(e);
  } finally {
    client.release();
  }
};

// ── POST /api/movil/pedidos/:id/abono ─────────────────────────────────────────
// Registra un abono a un pedido existente.
// Recalcula el estado del pedido automáticamente.
exports.agregarAbono = async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `SET search_path TO ${process.env.DB_SCHEMA || 'distriexpress'}, public`
    );

    const pedidoId = req.params.id;
    const { monto, tipo } = req.body;

    if (!monto || monto <= 0) {
      return res.status(400).json({ error: 'Monto inválido' });
    }

    const { rows: pedidoRows } = await client.query(
      `SELECT total FROM pedidos WHERE id = $1`,
      [pedidoId]
    );
    if (!pedidoRows[0]) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Pedido no encontrado' });
    }

    // Verifica que el monto no supere el saldo pendiente
    const { rows: abonadoRows } = await client.query(
      `SELECT COALESCE(SUM(monto), 0) AS total FROM abonos WHERE pedido_id = $1`,
      [pedidoId]
    );
    const yaAbonado = parseFloat(abonadoRows[0].total);
    const saldo     = parseFloat(pedidoRows[0].total) - yaAbonado;

    if (monto > saldo + 0.01) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'El monto supera el saldo pendiente' });
    }

    // Inserta el abono
    const { rows: nuevoAbono } = await client.query(
      `INSERT INTO abonos (pedido_id, monto, tipo, fecha) VALUES ($1,$2,$3,$4) RETURNING *`,
      [pedidoId, monto, tipo || 'Efectivo', fechaCO()]
    );

    // Recalcula el estado del pedido
    const { rows: todosProds } = await client.query(
      `SELECT checked FROM pedido_productos WHERE pedido_id = $1`,
      [pedidoId]
    );
    const allChecked   = todosProds.length > 0 && todosProds.every((p) => p.checked);
    const anyChecked   = todosProds.some((p) => p.checked);
    const totalAbonado = yaAbonado + monto;

    const { estado, origen } = calcularEstadoOrigen(
      allChecked,
      anyChecked,
      totalAbonado,
      parseFloat(pedidoRows[0].total)
    );

    await client.query(
      `UPDATE pedidos SET estado = $1, origen = $2 WHERE id = $3`,
      [estado, origen, pedidoId]
    );

    await client.query('COMMIT');

    res.status(201).json({ ...nuevoAbono[0], estado, origen });
  } catch (e) {
    await client.query('ROLLBACK');
    next(e);
  } finally {
    client.release();
  }
};
