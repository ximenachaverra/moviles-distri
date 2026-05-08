const db = require('./src/config/database');

(async () => {
  try {
    // Check all schemas
    const schemas = await db.query(
      "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT LIKE 'pg_%' AND schema_name != 'information_schema' ORDER BY schema_name"
    );
    console.log('\n📦 Esquemas disponibles:');
    schemas.rows.forEach(s => console.log('   -', s.schema_name));

    // Check all tables in current schema
    const tables = await db.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'distriexpress' ORDER BY table_name"
    );
    console.log('\n📋 Tablas en schema "distriexpress":');
    tables.rows.forEach(t => console.log('   -', t.table_name));

    // Check all table names across all schemas
    const allTables = await db.query(
      "SELECT table_schema, table_name, (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=t.table_schema AND table_name=t.table_name) as columns FROM information_schema.tables t WHERE table_schema NOT LIKE 'pg_%' AND table_schema != 'information_schema' ORDER BY table_schema, table_name"
    );
    console.log('\n📊 Todas las tablas en AWS:');
    allTables.rows.forEach(t => console.log(`   - ${t.table_schema}.${t.table_name} (${t.columns} columns)`));

    // Search for any table that might contain client data
    const clientTables = await db.query(
      "SELECT table_schema, table_name FROM information_schema.tables WHERE table_name ILIKE '%cliente%' OR table_name ILIKE '%customer%' OR table_name ILIKE '%negocio%' ORDER BY table_schema, table_name"
    );
    if (clientTables.rows.length > 0) {
      console.log('\n🔍 Tablas que podrían contener clientes:');
      clientTables.rows.forEach(t => console.log(`   - ${t.table_schema}.${t.table_name}`));
    }

    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
