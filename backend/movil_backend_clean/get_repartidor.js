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
    
    // Buscar repartidores existentes
    const result = await client.query(
      'SELECT id, email, nombre, apellido, rol_id FROM distriexpress.usuarios WHERE rol_id = 3 LIMIT 5'
    );
    
    console.log('\n👤 REPARTIDORES ENCONTRADOS:\n');
    if (result.rows.length === 0) {
      console.log('❌ No hay repartidores registrados');
    } else {
      result.rows.forEach((u, i) => {
        console.log(`${i+1}. ${u.email}`);
        console.log(`   Nombre: ${u.nombre} ${u.apellido}\n`);
      });
    }
    
    // Crear o actualizar usuario de prueba repartidor
    console.log('\n📝 Verificando usuario de prueba (repartidor@test.com)...');
    const checkResult = await client.query(
      'SELECT id FROM distriexpress.usuarios WHERE email = $1',
      ['repartidor@test.com']
    );

    if (checkResult.rows.length > 0) {
      console.log('✅ Usuario repartidor@test.com ya existe');
    } else {
      console.log('Creando repartidor de prueba...');
      const bcrypt = require('bcrypt');
      const hashedPwd = await bcrypt.hash('12345678', 10);
      const numero = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
      
      const insertResult = await client.query(`
        INSERT INTO distriexpress.usuarios 
          (nombre, apellido, tipo_documento, numero_documento, email, password_hash, rol_id, estado, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        RETURNING id, email, nombre, apellido;
      `, ['Test', 'Repartidor', 'CC', numero, 'repartidor@test.com', hashedPwd, 3, 'Activo']);
      
      console.log('✅ Usuario creado');
    }
    
    console.log('\n═══════════════════════════════════════════');
    console.log('📧 CREDENCIALES DE REPARTIDOR');
    console.log('═══════════════════════════════════════════');
    console.log('Email: repartidor@test.com');
    console.log('Contraseña: 12345678');
    console.log('═══════════════════════════════════════════\n');
    
    await client.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
