const router = require('express').Router();
const ctrl   = require('../controllers/abonos.controller');
const { verificarToken } = require('../middleware/auth');

router.use(verificarToken);

// GET /api/abonos                       — abonos de hoy del usuario (?fecha=YYYY-MM-DD)
router.get('/', ctrl.listar);

// GET /api/abonos/resumen               — contador para el home screen (cantidad y total del día)
router.get('/resumen', ctrl.resumenHoy);

// GET /api/abonos/cliente/:clienteId    — historial de abonos de un cliente
router.get('/cliente/:clienteId', ctrl.porCliente);

module.exports = router;
