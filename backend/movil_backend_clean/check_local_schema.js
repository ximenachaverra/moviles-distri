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
    // Check schemas
    const schemas = await local.query(`
      SELECT schema_name FROM information_schema.schemata 
      WHERE schema_name NOT LIKE 'pg_%' AND schema_name != 'information_schema'
      ORDER BY schema_name
    `);
    
    console.log('📦 Esquemas en BD local:');
    schemas.rows.forEach(s => console.log(`   - ${s.schema_name}`));

    // Check all tables
    const tables = await local.query(`
      SELECT table_schema, table_name FROM information_schema.tables 
      WHERE table_schema NOT LIKE 'pg_%' AND table_schema != 'information_schema'
      ORDER BY table_schema, table_name
    `);
    
    console.log('\n📋 Tablas en BD local:');
    let currentSchema = '';
    tables.rows.forEach(t => {
      if (t.table_schema !== currentSchema) {
        currentSchema = t.table_schema;
        console.log(`\n${currentSchema}:`);
      }
      console.log(`   - ${t.table_name}`);
    });

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
