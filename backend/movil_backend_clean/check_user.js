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
    const result = await client.query(
      'SELECT u.id, u.email, u.rol_id, r.nombre FROM distriexpress.usuarios u LEFT JOIN distriexpress.roles r ON u.rol_id = r.id WHERE u.email = $1',
      ['promotor@test.com']
    );
    console.log('Usuario encontrado:');
    console.log(result.rows[0]);
    await client.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
