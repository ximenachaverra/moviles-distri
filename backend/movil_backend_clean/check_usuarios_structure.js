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

    // Get usuarios table structure
    const columns = await local.query(`
      SELECT column_name, data_type FROM information_schema.columns 
      WHERE table_name = 'usuarios' ORDER BY ordinal_position
    `);
    
    console.log('📋 Estructura tabla usuarios:');
    columns.rows.forEach(c => console.log(`   - ${c.column_name}: ${c.data_type}`));

    // Get all usuarios
    const usuarios = await local.query('SELECT * FROM usuarios LIMIT 5');
    
    console.log('\n📦 Usuarios encontrados:');
    usuarios.rows.forEach((u, i) => {
      console.log(`\n   ${i+1}.`, JSON.stringify(u, null, 2).split('\n').slice(0, 10).join('\n      '));
    });

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
