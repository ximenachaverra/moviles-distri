const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';
const ROLES_MOVIL = new Set(['promotor', 'repartidor']);

const normalizarRolMovil = (rolDb) => {
  const v = String(rolDb || '').toLowerCase();
  if (v.includes('promotor') || v.includes('vendedor')) return 'promotor';
  if (v.includes('repartidor') || v.includes('domiciliario')) return 'repartidor';
  return null;
};

const DEMO_USERS = {
  'promotor@correo.com': {
    nombre: 'Demo',
    apellido: 'Promotor',
    rol: 'promotor',
  },
  'cualquier@correo.com': {
    nombre: 'Demo',
    apellido: 'Repartidor',
    rol: 'repartidor',
  },
};

// Genera el JWT con 7 días de expiración (más largo que el web, pensado para móvil)
const generarToken = (usuario) =>
  jwt.sign(
    { id: usuario.id, email: usuario.email },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

const obtenerRolId = async (rolMovil) => {
  const candidatos =
    rolMovil === 'promotor'
        ? ['promotor', 'vendedor']
        : ['repartidor', 'domiciliario'];

  const { rows } = await query(
    `SELECT id, nombre
     FROM roles
     WHERE LOWER(nombre) = ANY($1::text[])
        OR LOWER(nombre) LIKE ANY($2::text[])
     ORDER BY CASE
       WHEN LOWER(nombre) = $3 THEN 0
       WHEN LOWER(nombre) = $4 THEN 1
       ELSE 2
     END
     LIMIT 1`,
    [
      candidatos,
      candidatos.map((c) => `%${c}%`),
      candidatos[0],
      candidatos[1],
    ]
  );

  return rows[0]?.id || null;
};

const crearUsuario = async ({ nombre, apellido, email, password, rol }) => {
  const rolId = await obtenerRolId(rol);
  if (!rolId) {
    const err = new Error(`No existe el rol "${rol}" en la base de datos`);
    err.statusCode = 400;
    throw err;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const numeroDocumento = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const { rows } = await query(
    `INSERT INTO usuarios (
       nombre, apellido, tipo_documento, numero_documento, email, password_hash, rol_id, estado
     )
     VALUES ($1, $2, 'CC', $3, LOWER($4), $5, $6, 'Activo')
     RETURNING id, nombre, apellido, email, celular, avatar_url`,
    [nombre, apellido, numeroDocumento, email, passwordHash, rolId]
  );

  return {
    ...rows[0],
    rol,
  };
};

const asegurarDemoUser = async (email) => {
  const key = (email || '').toLowerCase();
  const demo = DEMO_USERS[key];
  if (!demo) return;

  const { rows } = await query(
    `SELECT id FROM usuarios WHERE LOWER(email) = LOWER($1) LIMIT 1`,
    [key]
  );

  if (rows[0]) {
    const rolId = await obtenerRolId(demo.rol);
    if (rolId) {
      await query('UPDATE usuarios SET rol_id = $1 WHERE LOWER(email) = LOWER($2)', [rolId, key]);
    }
    return;
  }

  await crearUsuario({
    nombre: demo.nombre,
    apellido: demo.apellido,
    email: key,
    password: 'cualquiera',
    rol: demo.rol,
  });
};

// ── POST /api/auth/register ───────────────────────────────────────────────────
// Crea usuarios de tipo promotor o repartidor para la app móvil.
exports.register = async (req, res, next) => {
  try {
    const { nombre, apellido, email, password, rol } = req.body;

    if (!nombre || !apellido || !email || !password || !rol) {
      return res.status(400).json({
        error: 'Nombre, apellido, email, contraseña y rol son requeridos',
      });
    }

    const rolNormalizado = String(rol).toLowerCase();
    if (!ROLES_MOVIL.has(rolNormalizado)) {
      return res.status(400).json({
        error: 'Rol inválido. Usa promotor o repartidor',
      });
    }

    if (String(password).length < 6) {
      return res.status(400).json({ error: 'La contraseña debe tener mínimo 6 caracteres' });
    }

    const usuario = await crearUsuario({
      nombre,
      apellido,
      email,
      password,
      rol: rolNormalizado,
    });

    res.status(201).json({
      token: generarToken(usuario),
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        email: usuario.email,
        telefono: usuario.celular,
        celular: usuario.celular,
        avatarUrl: usuario.avatar_url,
        rol: rolNormalizado,
      },
    });
  } catch (e) {
    next(e);
  }
};

// ── POST /api/auth/login ───────────────────────────────────────────────────────
// Solo permite login a usuarios con rol "promotor" o "repartidor".
// Devuelve el token y los datos del usuario con su rol.
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email y contraseña requeridos' });
    }

    // Garantiza credenciales demo para pruebas en desarrollo.
    await asegurarDemoUser(email);

    // Busca el usuario con su rol
    const { rows } = await query(
      `SELECT u.*, r.nombre AS rol_nombre
       FROM usuarios u
       LEFT JOIN roles r ON u.rol_id = r.id
       WHERE LOWER(u.email) = LOWER($1)`,
      [email]
    );

    const usuario = rows[0];

    if (!usuario) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    if (usuario.estado !== 'Activo') {
      return res.status(401).json({ error: 'Cuenta inactiva' });
    }

    // Fuerza el rol demo correcto si entra con una cuenta de prueba.
    const demoRol = DEMO_USERS[String(email).toLowerCase()]?.rol;

    // Verifica que el rol sea para la app móvil (promotor o repartidor)
    const rol = demoRol || normalizarRolMovil(usuario.rol_nombre);
    if (!rol) {
      return res.status(403).json({
        error: 'Esta app es solo para promotores y repartidores',
      });
    }

    // Evita errores en runtime si el usuario no tiene hash almacenado.
    if (!usuario.password_hash) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    // Verifica la contraseña
    const passwordCorrecta = await bcrypt.compare(password, usuario.password_hash);
    if (!passwordCorrecta) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    // Actualiza la fecha del último login
    await query('UPDATE usuarios SET ultimo_login = NOW() WHERE id = $1', [usuario.id]);

    res.json({
      token: generarToken(usuario),
      usuario: {
        id:        usuario.id,
        nombre:    usuario.nombre,
        apellido:  usuario.apellido,
        email:     usuario.email,
        telefono:  usuario.celular,
        celular:   usuario.celular,
        avatarUrl: usuario.avatar_url,
        rol,
      },
    });
  } catch (e) {
    next(e);
  }
};

// ── GET /api/auth/perfil ───────────────────────────────────────────────────────
// Devuelve el perfil del usuario autenticado.
exports.perfil = async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT u.id, u.nombre, u.apellido, u.email, u.celular,
              u.tipo_documento, u.numero_documento, u.avatar_url,
              r.nombre AS rol
       FROM usuarios u
       LEFT JOIN roles r ON u.rol_id = r.id
       WHERE u.id = $1`,
      [req.user.id]
    );

    if (!rows[0]) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const demoPerfilRol = DEMO_USERS[String(rows[0].email || '').toLowerCase()]?.rol;

    res.json({
      ...rows[0],
      rol: demoPerfilRol || normalizarRolMovil(rows[0].rol),
      telefono: rows[0].celular,
      avatarUrl: rows[0].avatar_url,
    });
  } catch (e) {
    next(e);
  }
};

// ── PUT /api/auth/perfil ───────────────────────────────────────────────────────
// Permite al usuario actualizar su nombre, apellido y celular.
exports.actualizarPerfil = async (req, res, next) => {
  try {
    const { nombre, apellido, celular } = req.body;

    await query(
      `UPDATE usuarios
       SET nombre   = COALESCE($1, nombre),
           apellido = COALESCE($2, apellido),
           celular  = COALESCE($3, celular)
       WHERE id = $4`,
      [nombre, apellido, celular, req.user.id]
    );

    res.json({ message: 'Perfil actualizado' });
  } catch (e) {
    next(e);
  }
};
