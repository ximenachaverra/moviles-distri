const { query } = require('../config/database');

// Fecha actual en zona horaria Colombia
const fechaCO = () =>
  new Date().toLocaleDateString('en-CA', { timeZone: 'America/Bogota' });

// ── GET /api/movil/abonos ─────────────────────────────────────────────────────
// Lista los abonos registrados hoy por el usuario autenticado.
// Permite filtrar por fecha con ?fecha=2024-01-15
exports.listar = async (req, res, next) => {
  try {
    const { fecha } = req.query;
    const diaConsulta = fecha || fechaCO();

    // Trae los abonos vinculados a pedidos de los clientes del vendedor
    const { rows } = await query(
      `SELECT a.*, p.cliente_nombre, p.cliente_id
       FROM abonos a
       JOIN pedidos p ON p.id = a.pedido_id
       WHERE p.vendedor_id = $1
         AND a.fecha = $2
       ORDER BY a.id DESC`,
      [req.user.id, diaConsulta]
    );

    res.json(rows);
  } catch (e) {
    next(e);
  }
};

// ── GET /api/movil/abonos/cliente/:clienteId ──────────────────────────────────
// Historial completo de abonos de un cliente específico,
// agrupado por pedido.
exports.porCliente = async (req, res, next) => {
  try {
    const { clienteId } = req.params;

    const { rows } = await query(
      `SELECT a.*, p.total AS pedido_total
       FROM abonos a
       JOIN pedidos p ON p.id = a.pedido_id
       WHERE p.cliente_id = $1
       ORDER BY a.fecha DESC, a.id DESC`,
      [clienteId]
    );

    res.json(rows);
  } catch (e) {
    next(e);
  }
};

// ── GET /api/movil/abonos/resumen ─────────────────────────────────────────────
// Resumen de cobros del día para el usuario autenticado.
// Útil para el contador "Abonos hoy" del home screen.
exports.resumenHoy = async (req, res, next) => {
  try {
    const hoy = fechaCO();

    const { rows } = await query(
      `SELECT
         COUNT(a.id)             AS cantidad_abonos,
         COALESCE(SUM(a.monto), 0) AS total_cobrado
       FROM abonos a
       JOIN pedidos p ON p.id = a.pedido_id
       WHERE p.vendedor_id = $1
         AND a.fecha = $2`,
      [req.user.id, hoy]
    );

    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
};
