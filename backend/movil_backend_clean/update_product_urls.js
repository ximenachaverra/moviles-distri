const { Pool } = require('pg');

const local = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'distriexpress',
  user: 'postgres',
  password: 'root',
});

// Cloudinary URLs for product images
const cloudinaryUrls = {
  1: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/arroz',
  2: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/aceite',
  3: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/quinoa',
  4: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/frijoles',
  5: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/lentejas',
  6: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/pasta',
  7: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/azucar',
  8: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/cafe',
  9: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/sal',
  10: 'https://res.cloudinary.com/ddfgyodh2/image/upload/w_400,h_300,c_fill/v1/food/harina',
};

(async () => {
  try {
    await local.query('SET search_path TO distriexpress, public');

    console.log('📤 Actualizando URLs de productos en BD local...\n');

    let updated = 0;
    for (const [id, url] of Object.entries(cloudinaryUrls)) {
      await local.query(
        'UPDATE productos SET imagen_url = $1 WHERE id = $2',
        [url, parseInt(id)]
      );
      updated++;
      console.log(`✅ Producto ${id}: ${url}`);
    }

    console.log(`\n✅ ${updated} productos actualizados con URLs de Cloudinary`);

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
