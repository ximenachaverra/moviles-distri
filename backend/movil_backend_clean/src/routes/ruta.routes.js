const router = require('express').Router();
const ctrl   = require('../controllers/ruta.controller');
const { verificarToken } = require('../middleware/auth');

// Todos los endpoints de ruta requieren autenticación
router.use(verificarToken);

// GET /api/ruta               — ruta asignada al usuario con sus clientes y pedidos
router.get('/', ctrl.miRuta);

// GET /api/ruta/cliente/:id/pedidos — pedidos activos de un cliente en la ruta
router.get('/cliente/:clienteId/pedidos', ctrl.pedidosCliente);

module.exports = router;
