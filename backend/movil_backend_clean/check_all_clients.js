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

    // Get ALL clients including inactive ones
    const allClientes = await local.query(`
      SELECT id, nombre_negocio, nombre_propietario, direccion, municipio, 
             departamento, locacion, estado, created_at
      FROM clientes
      ORDER BY id
    `);
    
    console.log(`📦 TODOS los clientes en BD (incluyendo inactivos): ${allClientes.rows.length}\n`);
    allClientes.rows.forEach((c, i) => {
      const nombre = c.nombre_negocio || c.nombre_propietario || 'Sin nombre';
      console.log(`${i+1}. [${c.id}] ${nombre}`);
      console.log(`   📍 ${c.municipio}, ${c.departamento}`);
      console.log(`   Estado: ${c.estado || 'Activo'}`);
    });

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
