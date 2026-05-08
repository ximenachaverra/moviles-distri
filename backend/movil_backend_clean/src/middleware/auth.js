const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';

const normalizarRolMovil = (rolDb) => {
  const v = String(rolDb || '').toLowerCase();
  if (v.includes('promotor') || v.includes('vendedor')) return 'promotor';
  if (v.includes('repartidor') || v.includes('domiciliario')) return 'repartidor';
  return v;
};

// ── verificarToken ────────────────────────────────────────────────────────────
// Valida el Bearer token JWT en cada request protegido.
// Adjunta el usuario completo a req.user para uso en los controllers.
const verificarToken = async (req, res, next) => {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token requerido' });
  }

  try {
    const token = header.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);

    // Busca el usuario en la BD y verifica que esté activo
    const { rows } = await query(
      `SELECT u.id, u.nombre, u.apellido, u.email, u.celular, u.avatar_url,
              u.rol_id, u.estado, r.nombre AS rol_nombre
       FROM usuarios u
       LEFT JOIN roles r ON u.rol_id = r.id
       WHERE u.id = $1`,
      [decoded.id]
    );

    if (!rows[0] || rows[0].estado !== 'Activo') {
      return res.status(401).json({ error: 'Usuario no válido o inactivo' });
    }

    req.user = rows[0];
    next();
  } catch (e) {
    if (e.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expirado' });
    }
    return res.status(401).json({ error: 'Token inválido' });
  }
};

// ── soloRol ───────────────────────────────────────────────────────────────────
// Fábrica de middleware: restringe acceso a un rol específico por nombre.
// Uso: soloRol('promotor') o soloRol('repartidor')
const soloRol = (...rolesPermitidos) => (req, res, next) => {
  const rolDelUsuario = normalizarRolMovil(req.user.rol_nombre);
  const tienePermiso = rolesPermitidos.some(
    (r) => r.toLowerCase() === rolDelUsuario
  );

  if (!tienePermiso) {
    return res.status(403).json({
      error: `Acceso denegado. Se requiere rol: ${rolesPermitidos.join(' o ')}`,
    });
  }

  next();
};

module.exports = { verificarToken, soloRol };
