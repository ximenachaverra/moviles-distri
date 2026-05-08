const { Pool } = require('pg');

const local = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'distriexpress',
  user: 'postgres',
  password: 'root',
});

(async () => {
  try {
    await local.query('SET search_path TO distriexpress, public');

    // Check ruta_clientes table
    const rutaClientes = await local.query(`
      SELECT rc.*, c.nombre_negocio, c.nombre_propietario, r.nombre as ruta_nombre
      FROM ruta_clientes rc
      LEFT JOIN clientes c ON c.id = rc.cliente_id
      LEFT JOIN rutas r ON r.id = rc.ruta_id
      ORDER BY rc.ruta_id, rc.cliente_id
    `);
    
    console.log(`📦 Registros en ruta_clientes: ${rutaClientes.rows.length}\n`);
    rutaClientes.rows.forEach((rc, i) => {
      const nombre = rc.nombre_negocio || rc.nombre_propietario || 'Sin nombre';
      console.log(`${i+1}. Ruta: ${rc.ruta_nombre || 'SIN RUTA'} - Cliente: ${nombre}`);
    });

    // Check all rutas
    const rutas = await local.query('SELECT id, nombre FROM rutas');
    console.log(`\n🛣️  Total de rutas: ${rutas.rows.length}`);
    rutas.rows.forEach(r => console.log(`   - [${r.id}] ${r.nombre}`));

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
