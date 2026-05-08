const { query } = require('../config/database');
const { obtenerPublicIdProducto, optimizarUrlProducto } = require('./cloudinary.controller');

// ── GET /api/movil/productos ──────────────────────────────────────────────────
// Lista los productos disponibles (con stock > 0) para agregar a un pedido.
// Parámetro opcional: ?q=texto para búsqueda por nombre
exports.listar = async (req, res, next) => {
  try {
    const { q } = req.query;

    let sql = `
      SELECT p.id, p.nombre, p.precio_venta AS precio,
             p.stock, p.imagen_url, c.nombre AS categoria
      FROM productos p
      LEFT JOIN categorias c ON c.id = p.categoria_id
      -- Relajar filtros: devolver productos aunque el campo 'estado' o 'stock' varíe en la BD
      -- WHERE p.estado = 'Activo' AND p.stock > 0
    `;

    const params = [];
    if (q) {
      params.push(`%${q}%`);
      sql += ` AND LOWER(p.nombre) LIKE LOWER($1)`;
    }

    sql += ` ORDER BY p.nombre ASC`;

    const { rows } = await query(sql, params);
    
    // Enriquecer con imágenes de Cloudinary
    const productosConImagenes = rows.map(p => {
      // Obtener public_id de Cloudinary basado en el nombre del producto
      const publicId = obtenerPublicIdProducto(p.nombre);
      
      // Si hay URL de imagen en BD, usarla; si no, construir desde Cloudinary
      const imagenUrl = p.imagen_url && p.imagen_url.includes('cloudinary')
        ? p.imagen_url
        : (publicId ? optimizarUrlProducto(publicId) : null);
      
      return {
        ...p,
        imagen_url: imagenUrl
      };
    });
    
    res.json(productosConImagenes);
  } catch (e) {
    next(e);
  }
};
