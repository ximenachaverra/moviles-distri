const db = require('./src/config/database');

(async () => {
  try {
    // Total clientes en tabla
    const totalClientes = await db.query('SELECT COUNT(*) as total FROM distriexpress.clientes');
    console.log('📦 Total registros en clientes:', totalClientes.rows[0].total);

    // All clients
    const clientes = await db.query(
      `SELECT id, nombre_negocio, nombre_propietario, direccion, municipio, departamento FROM distriexpress.clientes ORDER BY id`
    );
    console.log('\n📋 Todos los clientes:');
    clientes.rows.forEach((c, i) => {
      const nombre = c.nombre_negocio || c.nombre_propietario || 'Sin nombre';
      console.log(`   ${i + 1}. [${c.id}] ${nombre} - ${c.municipio}`);
    });

    // Check ruta_clientes relationship
    const rutaClientes = await db.query('SELECT COUNT(*) as total FROM distriexpress.ruta_clientes');
    console.log(`\n🔗 Registros en ruta_clientes: ${rutaClientes.rows[0].total}`);

    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
