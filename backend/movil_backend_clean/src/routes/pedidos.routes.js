const router = require('express').Router();
const ctrl   = require('../controllers/pedidos.controller');
const { verificarToken, soloRol } = require('../middleware/auth');

// Todos los endpoints requieren autenticación
router.use(verificarToken);

// GET  /api/pedidos         — lista pedidos del vendedor autenticado
router.get('/', ctrl.listar);

// GET  /api/pedidos/:id     — detalle de un pedido
router.get('/:id', ctrl.obtener);

// POST /api/pedidos         — crear pedido (solo promotor)
router.post('/', soloRol('promotor'), ctrl.crear);

// PATCH /api/pedidos/:id/check  — marcar/desmarcar producto entregado (repartidor y promotor)
router.patch('/:id/check', ctrl.checkProducto);

// POST /api/pedidos/:id/abono   — agregar abono a un pedido (ambos roles)
router.post('/:id/abono', ctrl.agregarAbono);

module.exports = router;
