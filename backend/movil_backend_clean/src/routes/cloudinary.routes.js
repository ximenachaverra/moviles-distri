const router = require('express').Router();
const ctrl = require('../controllers/cloudinary.controller');

// GET /api/cloudinary/imagenes   — obtiene listado de imágenes desde Cloudinary
router.get('/imagenes', ctrl.obtenerImagenesCloudinary);

module.exports = router;
