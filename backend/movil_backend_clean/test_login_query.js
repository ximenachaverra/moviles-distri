const { Client } = require('pg');

const client = new Client({
  host: 'distriexpress-db.czsuiq8yqt9q.us-east-2.rds.amazonaws.com',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'pRmG79cerW1K76DX9fAX',
  ssl: { rejectUnauthorized: false }
});

(async () => {
  try {
    await client.connect();
    const result = await client.query(`
      SELECT u.*, r.nombre AS rol_nombre
      FROM distriexpress.usuarios u
      LEFT JOIN distriexpress.roles r ON u.rol_id = r.id
      WHERE LOWER(u.email) = LOWER($1)
    `, ['promotor@test.com']);
    
    if (result.rows.length === 0) {
      console.log('❌ Usuario no encontrado');
    } else {
      const u = result.rows[0];
      console.log('✅ Usuario encontrado:');
      console.log('  Email:', u.email);
      console.log('  rol_id:', u.rol_id);
      console.log('  rol_nombre:', u.rol_nombre);
      console.log('  estado:', u.estado);
      
      // Test password
      const bcrypt = require('bcrypt');
      const match = await bcrypt.compare('12345678', u.password_hash);
      console.log('  password_hash valid:', match);
    }
    await client.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
