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
    // Check all records including inactive
    const allClientes = await local.query(`
      SELECT id, nombre_negocio, nombre_propietario, direccion, municipio, 
             departamento, locacion, estado, created_at
      FROM clientes
      ORDER BY id
    `);
    
    console.log(`📦 Total clientes (incluyendo inactivos): ${allClientes.rows.length}`);
    console.log('\n📋 Listado completo:');
    allClientes.rows.forEach((c, i) => {
      const nombre = c.nombre_negocio || c.nombre_propietario || 'Sin nombre';
      console.log(`   ${i+1}. [${c.id}] ${nombre}`);
      console.log(`      Dirección: ${c.direccion}`);
      console.log(`      Ubicación: ${c.municipio}, ${c.departamento}`);
      console.log(`      Estado: ${c.estado || 'activo'}`);
    });

    // Check productos
    const productos = await local.query(`
      SELECT id, nombre, imagen_url, stock, precio_venta FROM productos LIMIT 15
    `);
    console.log(`\n📦 Total productos: ${productos.rows.length}`);
    console.log('Primeros 5 productos:');
    productos.rows.slice(0, 5).forEach((p, i) => {
      console.log(`   ${i+1}. ${p.nombre} - Stock: ${p.stock}`);
      console.log(`      Imagen: ${p.imagen_url ? p.imagen_url.substring(0, 60) : 'SIN URL'}`);
    });

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
