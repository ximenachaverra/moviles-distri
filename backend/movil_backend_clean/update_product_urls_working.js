const { Pool } = require('pg');

const local = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'distriexpress',
  user: 'postgres',
  password: 'root',
});

// Valid placeholder URLs that actually work
const placeholderUrls = {
  1: 'https://picsum.photos/400/300?random=1',
  2: 'https://picsum.photos/400/300?random=2',
  3: 'https://picsum.photos/400/300?random=3',
  4: 'https://picsum.photos/400/300?random=4',
  5: 'https://picsum.photos/400/300?random=5',
  6: 'https://picsum.photos/400/300?random=6',
  7: 'https://picsum.photos/400/300?random=7',
  8: 'https://picsum.photos/400/300?random=8',
  9: 'https://picsum.photos/400/300?random=9',
  10: 'https://picsum.photos/400/300?random=10',
};

(async () => {
  try {
    await local.query('SET search_path TO distriexpress, public');

    console.log('📤 Actualizando URLs de productos con imágenes que funcionan...\n');

    let updated = 0;
    for (const [id, url] of Object.entries(placeholderUrls)) {
      await local.query(
        'UPDATE productos SET imagen_url = $1 WHERE id = $2',
        [url, parseInt(id)]
      );
      updated++;
      console.log(`✅ Producto ${id}: ${url}`);
    }

    console.log(`\n✅ ${updated} productos actualizados con imágenes que funcionan`);

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
