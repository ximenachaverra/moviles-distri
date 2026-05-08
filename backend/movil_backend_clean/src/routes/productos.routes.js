const router = require('express').Router();
const ctrl = require('../controllers/productos.controller');

// GET /api/productos   — catálogo público de productos con imágenes (?q=busqueda)
// This endpoint is intentionally public so mobile clients can fetch product catalog without auth.
router.get('/', ctrl.listar);

module.exports = router;
