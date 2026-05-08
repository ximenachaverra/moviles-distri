const router = require('express').Router();
const ctrl   = require('../controllers/auth.controller');
const { verificarToken } = require('../middleware/auth');

// POST /api/auth/register   — crear cuenta (promotor/repartidor)
router.post('/register', ctrl.register);

// POST /api/auth/login   — login para promotor y repartidor
router.post('/login', ctrl.login);

// GET  /api/auth/perfil  — datos del usuario autenticado
router.get('/perfil', verificarToken, ctrl.perfil);

// PUT  /api/auth/perfil  — actualizar nombre, apellido, celular
router.put('/perfil', verificarToken, ctrl.actualizarPerfil);

module.exports = router;
