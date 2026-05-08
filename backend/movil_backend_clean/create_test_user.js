const { Client } = require('pg');
const bcrypt = require('bcrypt');

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
    
    // Hash password with bcrypt (same as backend)
    const hashedPwd = await bcrypt.hash('12345678', 10);
    
    // Check if user exists
    const checkResult = await client.query(
      'SELECT id FROM distriexpress.usuarios WHERE email = $1',
      ['promotor@test.com']
    );

    let userId;
    if (checkResult.rows.length > 0) {
      console.log('✅ Usuario promotor@test.com ya existe');
      userId = checkResult.rows[0].id;
    } else {
      console.log('📝 Creando usuario promotor@test.com...');
      const numero = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const insertResult = await client.query(`
        INSERT INTO distriexpress.usuarios 
          (nombre, apellido, tipo_documento, numero_documento, email, password_hash, rol_id, estado, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        RETURNING id;
      `, ['Test', 'Promotor', 'CC', numero, 'promotor@test.com', hashedPwd, 1, 'Activo']);
      
      userId = insertResult.rows[0].id;
      console.log('✅ Usuario creado con éxito');
    }

    console.log(`
Credenciales de prueba:
📧 Email: promotor@test.com
🔐 Contraseña: 12345678
    `);

    await client.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
