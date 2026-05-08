const { query } = require('../config/database');

// ── GET /api/clientes ───────────────────────────────────────────────────────
// Lista los clientes disponibles para el promotor al crear un pedido.
// Parámetro opcional: ?q=texto para búsqueda por nombre o dirección
exports.listar = async (req, res, next) => {
  try {
    const { q } = req.query;

    let sql = `
      SELECT c.id,
             COALESCE(c.nombre_negocio, c.nombre_propietario, 'Cliente') AS nombre,
             c.direccion,
             COALESCE(c.municipio, c.departamento, c.locacion, '') AS zona,
             c.telefono,
             c.latitud AS lat,
             c.longitud AS lng
      FROM clientes c
    `;

    const params = [];
    if (q) {
      params.push(`%${q}%`);
      sql += ` WHERE (
        LOWER(c.nombre_negocio) LIKE LOWER($1) OR 
        LOWER(c.nombre_propietario) LIKE LOWER($1) OR 
        LOWER(c.direccion) LIKE LOWER($1)
      )`;
    }

    sql += ` ORDER BY COALESCE(c.nombre_negocio, c.nombre_propietario) ASC`;

    const { rows } = await query(sql, params);
    res.json(rows);
  } catch (e) {
    next(e);
  }
};

// ── GET /api/clientes/:id ───────────────────────────────────────────────────
// Detalle de un cliente con su saldo total pendiente.
exports.obtener = async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT c.id,
              COALESCE(c.nombre_negocio, c.nombre_propietario, 'Cliente') AS nombre,
              c.direccion,
              COALESCE(c.municipio, c.departamento, c.locacion, '') AS zona,
              c.telefono,
              c.latitud AS lat,
              c.longitud AS lng,
              COALESCE(saldos.saldo_pendiente, 0) AS saldo_pendiente
       FROM clientes c
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
       WHERE c.id = $1`,
      [req.params.id]
    );

    if (!rows[0]) {
      return res.status(404).json({ error: 'Cliente no encontrado' });
    }

    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
};
