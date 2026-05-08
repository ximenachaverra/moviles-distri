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

    const usuarios = await local.query(`
      SELECT id, nombre, apellido, email, rol FROM usuarios LIMIT 10
    `);
    
    console.log('📦 Usuarios en BD local:');
    usuarios.rows.forEach((u, i) => {
      console.log(`   ${i+1}. ${u.nombre} ${u.apellido} (${u.email}) - Rol: ${u.rol}`);
    });

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
