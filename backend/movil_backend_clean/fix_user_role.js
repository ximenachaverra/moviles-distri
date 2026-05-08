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
    await client.query('UPDATE distriexpress.usuarios SET rol_id = 2 WHERE email = $1', ['promotor@test.com']);
    console.log('✅ Rol actualizado a Promotor (rol_id = 2)');
    await client.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
