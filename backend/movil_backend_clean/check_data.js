const db = require('./src/config/database');

(async () => {
  try {
    const clientes = await db.query('SELECT COUNT(*) as total FROM clientes');
    console.log('📦 Total clientes:', clientes.rows[0].total);

    const productos = await db.query('SELECT COUNT(*) as total FROM productos');
    console.log('📦 Total productos:', productos.rows[0].total);

    const productosConImagen = await db.query(
      "SELECT COUNT(*) as total FROM productos WHERE imagen_url IS NOT NULL AND imagen_url != ''"
    );
    console.log('🖼️  Productos con imagen_url:', productosConImagen.rows[0].total);

    // Sample products
    const samples = await db.query(
      "SELECT id, nombre, imagen_url FROM productos WHERE imagen_url IS NOT NULL LIMIT 3"
    );
    console.log('\n✅ Muestra de productos:');
    samples.rows.forEach(p => {
      console.log(`   - ${p.nombre}: ${p.imagen_url.substring(0, 60)}...`);
    });

    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
