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

    // Get all usuarios with their roles
    const usuarios = await local.query(`
      SELECT u.id, u.nombre, u.apellido, u.email, r.nombre as rol_nombre
      FROM usuarios u
      LEFT JOIN roles r ON r.id = u.rol_id
      ORDER BY u.id
      LIMIT 15
    `);
    
    console.log('📦 Usuarios en BD local con roles:');
    usuarios.rows.forEach((u, i) => {
      console.log(`   ${i+1}. ${u.nombre} ${u.apellido} (${u.email}) - Rol: ${u.rol_nombre || 'SIN ROL'}`);
    });

    // Find promoter users
    const promotores = await local.query(`
      SELECT u.id, u.nombre, u.apellido, u.email
      FROM usuarios u
      LEFT JOIN roles r ON r.id = u.rol_id
      WHERE r.nombre = 'Promotor' OR r.nombre ILIKE '%promotor%'
      LIMIT 5
    `);
    
    console.log('\n✅ Promotores encontrados:');
    if (promotores.rows.length > 0) {
      promotores.rows.forEach(p => {
        console.log(`   - ${p.email}`);
      });
    } else {
      console.log('   (ninguno encontrado)');
    }

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
