const path = require('path');
require('dotenv').config({ path: path.join(process.cwd(), '.env') });
const { query } = require('./src/config/database');

(async () => {
  try {
    const tables = await query("SELECT table_schema, table_name FROM information_schema.tables WHERE table_name = 'clientes' ORDER BY table_schema, table_name");
    console.log('TABLES', JSON.stringify(tables.rows, null, 2));
    for (const row of tables.rows) {
      const cnt = await query(`SELECT COUNT(*)::int AS total FROM ${row.table_schema}.clientes`);
      console.log(`${row.table_schema}: ${cnt.rows[0].total}`);
    }
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
})();
