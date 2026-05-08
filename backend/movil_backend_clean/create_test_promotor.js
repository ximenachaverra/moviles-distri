const bcrypt = require('bcrypt');
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

    // Get vendor role (which maps to promotor)
    const roleRes = await local.query(
      `SELECT id FROM roles WHERE LOWER(nombre) LIKE '%vendedor%' LIMIT 1`
    );
    
    if (!roleRes.rows[0]) {
      console.error('❌ Rol Vendedor no encontrado');
      process.exit(1);
    }

    const rolId = roleRes.rows[0].id;
    const passwordHash = await bcrypt.hash('12345678', 10);
    
    // Create or update test promoter user
    const testEmail = 'test-promotor@test.com';
    
    const existRes = await local.query(
      'SELECT id FROM usuarios WHERE LOWER(email) = LOWER($1)',
      [testEmail]
    );

    let userId;
    if (existRes.rows[0]) {
      // Update existing
      userId = existRes.rows[0].id;
      await local.query(
        'UPDATE usuarios SET password_hash = $1, estado = $2 WHERE id = $3',
        [passwordHash, 'Activo', userId]
      );
      console.log(`✅ Usuario actualizado: ${testEmail} / 12345678`);
    } else {
      // Create new
      const createRes = await local.query(`
        INSERT INTO usuarios (nombre, apellido, tipo_documento, numero_documento, email, password_hash, rol_id, estado)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id
      `, ['Test', 'Promotor', 'CC', `${Date.now()}`, testEmail, passwordHash, rolId, 'Activo']);
      
      userId = createRes.rows[0].id;
      console.log(`✅ Usuario creado: ${testEmail} / 12345678`);
    }

    console.log(`\n🔐 Usa estas credenciales para probar:`);
    console.log(`   Email: ${testEmail}`);
    console.log(`   Password: 12345678`);

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
