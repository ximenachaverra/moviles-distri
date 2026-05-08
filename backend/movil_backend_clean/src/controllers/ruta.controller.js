const { query } = require('../config/database');

// ── GET /api/movil/ruta ───────────────────────────────────────────────────────
// Devuelve la ruta asignada al usuario autenticado (promotor o repartidor).
// Incluye los clientes de la ruta con sus pedidos pendientes del día.
exports.miRuta = async (req, res, next) => {
  try {
    const usuarioId = req.user.id;

    // Busca la ruta asignada al vendedor (usa vendedor_id para unir)
    const { rows: rutas } = await query(
      `SELECT * FROM rutas WHERE vendedor_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [usuarioId]
    );

    // Si no tiene ruta asignada, devuelve estructura vacía
    if (!rutas[0]) {
      return res.json({ ruta: null, clientes: [] });
    }

    const ruta = rutas[0];

    // Trae los clientes de la ruta en orden
    const { rows: clientesRuta } = await query(
      `SELECT rc.orden, c.*,
              COALESCE(saldos.saldo_pendiente, 0) AS saldo_pendiente
       FROM ruta_clientes rc
       JOIN clientes c ON rc.cliente_id = c.id
       LEFT JOIN (
         SELECT p.cliente_id,
                SUM(p.total - COALESCE(ab.abonado, 0)) AS saldo_pendiente
         FROM pedidos p
         LEFT JOIN (
           SELECT pedido_id, SUM(monto) AS abonado FROM abonos GROUP BY pedido_id
         ) ab ON ab.pedido_id = p.id
         WHERE p.estado NOT IN ('Pagado', 'Anulado')
         GROUP BY p.cliente_id
       ) saldos ON saldos.cliente_id = c.id
       WHERE rc.ruta_id = $1
       ORDER BY rc.orden`,
      [ruta.id]
    );

    // Para cada cliente, trae sus pedidos pendientes
    for (const cliente of clientesRuta) {
      const { rows: pedidos } = await query(
        `SELECT p.*,
                COALESCE(SUM(a.monto), 0)            AS total_abonado,
                p.total - COALESCE(SUM(a.monto), 0)  AS saldo_pendiente
         FROM pedidos p
         LEFT JOIN abonos a ON a.pedido_id = p.id
         WHERE p.cliente_id = $1
           AND p.estado NOT IN ('Pagado', 'Anulado')
         GROUP BY p.id
         ORDER BY p.fecha_pedido DESC`,
        [cliente.id]
      );

      // Para cada pedido, agrega sus productos
      for (const pedido of pedidos) {
        const { rows: productos } = await query(
          `SELECT * FROM pedido_productos WHERE pedido_id = $1`,
          [pedido.id]
        );
        pedido.productos = productos;
      }

      cliente.pedidos = pedidos;
    }

    res.json({ ruta, clientes: clientesRuta });
  } catch (e) {
    next(e);
  }
};

// ── GET /api/movil/ruta/cliente/:clienteId/pedidos ────────────────────────────
// Devuelve todos los pedidos activos de un cliente específico,
// incluyendo productos y abonos registrados.
exports.pedidosCliente = async (req, res, next) => {
  try {
    const { clienteId } = req.params;

    const { rows: pedidos } = await query(
      `SELECT p.*,
              COALESCE(SUM(a.monto), 0)            AS total_abonado,
              p.total - COALESCE(SUM(a.monto), 0)  AS saldo_pendiente
       FROM pedidos p
       LEFT JOIN abonos a ON a.pedido_id = p.id
       WHERE p.cliente_id = $1
         AND p.estado NOT IN ('Anulado')
       GROUP BY p.id
       ORDER BY p.fecha_pedido DESC`,
      [clienteId]
    );

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
