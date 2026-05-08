require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const express      = require('express');
const helmet       = require('helmet');
const morgan       = require('morgan');
const { errorHandler } = require('./src/middleware/errorHandler');

const app = express();

// ── Seguridad básica ──────────────────────────────────────────────────────────
app.use(helmet({ crossOriginResourcePolicy: false }));

// ── CORS para la app móvil ────────────────────────────────────────────────────
// En producción reemplaza '*' por el origen real si usas un proxy/gateway
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

// ── Logs y parseo ─────────────────────────────────────────────────────────────
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '5mb' }));

// ── Rutas del API móvil ───────────────────────────────────────────────────────
app.use('/api/auth',      require('./src/routes/auth.routes'));
app.use('/api/ruta',      require('./src/routes/ruta.routes'));
app.use('/api/pedidos',   require('./src/routes/pedidos.routes'));
app.use('/api/abonos',    require('./src/routes/abonos.routes'));
app.use('/api/clientes',  require('./src/routes/clientes.routes'));
app.use('/api/productos',  require('./src/routes/productos.routes'));
app.use('/api/cloudinary', require('./src/routes/cloudinary.routes'));
// Image proxy for product images (helps web clients when external hosts are blocked)
app.use('/images', require('./src/routes/images.routes'));

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/', (req, res) =>
  res.json({ api: 'DistriExpress Móvil Backend', version: '1.0.0', status: 'running' })
);
app.get('/api/health', (req, res) =>
  res.json({ status: 'ok', timestamp: new Date() })
);

// ── 404 y errores globales ────────────────────────────────────────────────────
app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));
app.use(errorHandler);

// ── Arranque ──────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n  DistriExpress Móvil Backend v1.0`);
  console.log(`  Puerto: ${PORT}`);
  console.log(`  Entorno: ${process.env.NODE_ENV || 'development'}\n`);
});
