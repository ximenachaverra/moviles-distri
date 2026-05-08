const { Client } = require('pg');
const crypto = require('crypto');

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
    console.log('✅ Conectado a AWS RDS\n');

    // Get users
    const result = await client.query(`
      SELECT id, email, nombre, rol_id FROM distriexpress.usuarios LIMIT 10;
    `);
    
    console.log('👥 Usuarios en AWS RDS:');
    result.rows.forEach((u, i) => {
      console.log(`${i+1}. ${u.email} (${u.nombre}) - rol_id: ${u.rol_id}`);
    });

    if (result.rows.length === 0) {
      console.log('\n❌ No hay usuarios en AWS RDS. Creando usuario de prueba...\n');
      
      // Create test user
      const hashedPwd = crypto.createHash('sha256').update('12345678').digest('hex');
      const insertResult = await client.query(`
        INSERT INTO distriexpress.usuarios (email, password, nombre, rol_id, estado, created_at)
        VALUES ($1, $2, $3, $4, $5, NOW())
        RETURNING id, email, nombre;
      `, ['promotor@test.com', hashedPwd, 'Test Promotor', 1, 'activo']);
      
      console.log('✅ Usuario creado:');
      console.log('   Email: ' + insertResult.rows[0].email);
      console.log('   Nombre: ' + insertResult.rows[0].nombre);
      console.log('   Contraseña: 12345678\n');
    }

    // Get clients count
    const clientsResult = await client.query(`
      SELECT COUNT(*) as total FROM distriexpress.clientes;
    `);
    
    console.log(`\n📦 Total de clientes en AWS RDS: ${clientsResult.rows[0].total}`);
    
    // Show first 3 clients
    const clientsDetail = await client.query(`
      SELECT id, nombre_negocio, nombre_propietario, municipio, latitud, longitud 
      FROM distriexpress.clientes LIMIT 3;
    `);
    
    console.log('\n📋 Primeros 3 clientes:');
    clientsDetail.rows.forEach((c, i) => {
      console.log(`${i+1}. ${c.nombre_negocio || c.nombre_propietario} - ${c.municipio}`);
    });

    await client.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
