require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const express      = require('express');
const helmet       = require('helmet');
const morgan       = require('morgan');
const { errorHandler } = require('./src/middleware/errorHandler');

const app = express();

console.log('1. Cargando seguridad...');
app.use(helmet({ crossOriginResourcePolicy: false }));

console.log('2. Cargando CORS...');
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

console.log('3. Cargando logs y parseo...');
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '5mb' }));

console.log('4. Cargando rutas...');
try {
  console.log('  4a. auth.routes...');
  app.use('/api/auth', require('./src/routes/auth.routes'));
  
  console.log('  4b. ruta.routes...');
  app.use('/api/ruta', require('./src/routes/ruta.routes'));
  
  console.log('  4c. pedidos.routes...');
  app.use('/api/pedidos', require('./src/routes/pedidos.routes'));
  
  console.log('  4d. abonos.routes...');
  app.use('/api/abonos', require('./src/routes/abonos.routes'));
  
  console.log('  4e. clientes.routes...');
  app.use('/api/clientes', require('./src/routes/clientes.routes'));
  
  console.log('  4f. productos.routes...');
  app.use('/api/productos', require('./src/routes/productos.routes'));
  
  console.log('  4g. images.routes...');
  app.use('/images', require('./src/routes/images.routes'));
} catch (err) {
  console.error('❌ Error cargando rutas:', err.message);
  process.exit(1);
}

console.log('5. Cargando health checks...');
app.get('/', (req, res) =>
  res.json({ api: 'DistriExpress Móvil Backend', version: '1.0.0', status: 'running' })
);
app.get('/api/health', (req, res) =>
  res.json({ status: 'ok', timestamp: new Date() })
);

console.log('6. Cargando 404 y errores...');
app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));
app.use(errorHandler);

console.log('7. Iniciando servidor...');
const PORT = process.env.PORT || 5001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n  DistriExpress Móvil Backend v1.0`);
  console.log(`  Puerto: ${PORT}`);
  console.log(`  Entorno: ${process.env.NODE_ENV || 'development'}\n`);
});
