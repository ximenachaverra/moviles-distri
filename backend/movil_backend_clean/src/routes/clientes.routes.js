const router = require('express').Router();
const ctrl   = require('../controllers/clientes.controller');
const { verificarToken } = require('../middleware/auth');

router.use(verificarToken);

// GET /api/clientes       — lista de clientes activos (?q=busqueda)
router.get('/', ctrl.listar);

// GET /api/clientes/:id   — detalle de un cliente con saldo pendiente
router.get('/:id', ctrl.obtener);

module.exports = router;
