const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { query } = require('../src/config/database');

async function main() {
  console.log('Buscando productos con imagen_url NULL...');
  const res = await query("SELECT id, nombre FROM productos WHERE imagen_url IS NULL OR imagen_url = ''");
  const rows = res.rows;
  if (!rows || rows.length === 0) {
    console.log('No hay productos sin imagen_url.');
    process.exit(0);
  }

  const base = process.env.BASE_IMAGE_URL || '';
  const updated = [];

  for (const p of rows) {
    const id = p.id;
    let url;
    if (base) {
      url = `${base.replace(/\/$/, '')}/productos/${id}.jpg`;
    } else {
      // use placeholder service
      url = `https://via.placeholder.com/400x300.png?text=${encodeURIComponent(p.nombre || ('Producto+'+id))}`;
    }

    await query('UPDATE productos SET imagen_url = $1 WHERE id = $2', [url, id]);
    updated.push({ id, url });
    console.log(`Producto ${id} -> ${url}`);
  }

  const sel = await query('SELECT id, nombre, imagen_url FROM productos WHERE id = ANY($1)', [updated.map(u=>u.id)]);
  console.log('Updated products:');
  console.table(sel.rows);
  process.exit(0);
}

main().catch(err => { console.error(err); process.exit(1); });
