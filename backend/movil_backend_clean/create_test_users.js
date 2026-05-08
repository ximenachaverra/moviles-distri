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

    // Get vendor role (maps to promotor)
    const vendedorRes = await local.query(
      `SELECT id FROM roles WHERE LOWER(nombre) LIKE '%vendedor%' LIMIT 1`
    );
    
    // Get domiciliario role (maps to repartidor)
    const domiciliarioRes = await local.query(
      `SELECT id FROM roles WHERE LOWER(nombre) LIKE '%domiciliario%' LIMIT 1`
    );

    if (!vendedorRes.rows[0] || !domiciliarioRes.rows[0]) {
      console.error('❌ Roles no encontrados');
      process.exit(1);
    }

    const vendedorRolId = vendedorRes.rows[0].id;
    const domiciliarioRolId = domiciliarioRes.rows[0].id;
    const passwordHash = await bcrypt.hash('12345678', 10);

    // Create test promoter
    const promotorEmail = 'promotor@test.com';
    const promotorExist = await local.query(
      'SELECT id FROM usuarios WHERE LOWER(email) = LOWER($1)',
      [promotorEmail]
    );

    if (promotorExist.rows[0]) {
      await local.query(
        'UPDATE usuarios SET password_hash = $1, rol_id = $2, estado = $3 WHERE id = $4',
        [passwordHash, vendedorRolId, 'Activo', promotorExist.rows[0].id]
      );
      console.log(`✅ Promotor actualizado`);
    } else {
      await local.query(`
        INSERT INTO usuarios (nombre, apellido, tipo_documento, numero_documento, email, password_hash, rol_id, estado)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, ['Test', 'Promotor', 'CC', `${Date.now()}`, promotorEmail, passwordHash, vendedorRolId, 'Activo']);
      console.log(`✅ Promotor creado`);
    }

    // Create test repartidor
    const repartidorEmail = 'repartidor@test.com';
    const repartidorExist = await local.query(
      'SELECT id FROM usuarios WHERE LOWER(email) = LOWER($1)',
      [repartidorEmail]
    );

    if (repartidorExist.rows[0]) {
      await local.query(
        'UPDATE usuarios SET password_hash = $1, rol_id = $2, estado = $3 WHERE id = $4',
        [passwordHash, domiciliarioRolId, 'Activo', repartidorExist.rows[0].id]
      );
      console.log(`✅ Repartidor actualizado`);
    } else {
      await local.query(`
        INSERT INTO usuarios (nombre, apellido, tipo_documento, numero_documento, email, password_hash, rol_id, estado)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, ['Test', 'Repartidor', 'CC', `${Date.now()}`, repartidorEmail, passwordHash, domiciliarioRolId, 'Activo']);
      console.log(`✅ Repartidor creado`);
    }

    console.log(`\n🔐 Credenciales de prueba:\n`);
    console.log(`📦 PROMOTOR:`);
    console.log(`   Email: ${promotorEmail}`);
    console.log(`   Password: 12345678\n`);
    console.log(`🚚 REPARTIDOR:`);
    console.log(`   Email: ${repartidorEmail}`);
    console.log(`   Password: 12345678`);

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
