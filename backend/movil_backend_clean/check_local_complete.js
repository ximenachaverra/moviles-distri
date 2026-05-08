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

    const allClientes = await local.query(`
      SELECT id, nombre_negocio, nombre_propietario, direccion, municipio, 
             departamento, latitud, longitud
      FROM clientes
      ORDER BY id
    `);
    
    console.log(`📦 Total clientes en BD local: ${allClientes.rows.length}\n`);
    allClientes.rows.forEach((c, i) => {
      const nombre = c.nombre_negocio || c.nombre_propietario || 'Sin nombre';
      console.log(`${i+1}. [${c.id}] ${nombre}`);
      console.log(`   📍 ${c.municipio}, ${c.departamento}`);
      console.log(`   📌 ${c.direccion}`);
      console.log(`   🧭 ${c.latitud}, ${c.longitud}`);
    });

    const productos = await local.query(`
      SELECT COUNT(*) as total FROM productos
    `);
    console.log(`\n📦 Total productos: ${productos.rows[0].total}`);

    const productosConImg = await local.query(`
      SELECT COUNT(*) as total FROM productos WHERE imagen_url IS NOT NULL AND imagen_url != ''
    `);
    console.log(`🖼️  Productos con imagen_url: ${productosConImg.rows[0].total}`);

    const samples = await local.query(`
      SELECT id, nombre, imagen_url FROM productos WHERE imagen_url IS NOT NULL LIMIT 3
    `);
    console.log('\n✅ Muestra de productos:');
    samples.rows.forEach(p => {
      console.log(`   - [${p.id}] ${p.nombre}`);
      console.log(`      URL: ${p.imagen_url.substring(0, 80)}...`);
    });

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
