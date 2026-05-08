const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { query } = require('../src/config/database');

async function main() {
  console.log('Conectando a la base de datos, buscando clientes sin coordenadas...');
  const res = await query('SELECT id, nombre_negocio, direccion, municipio, departamento FROM clientes WHERE latitud IS NULL OR longitud IS NULL');
  const rows = res.rows;
  if (!rows || rows.length === 0) {
    console.log('No hay clientes con latitud/longitud nulas. Nada que actualizar.');
    process.exit(0);
  }

  const baseLat = parseFloat(process.env.BASE_LAT || '13.7000');
  const baseLng = parseFloat(process.env.BASE_LNG || '-89.2000');
  console.log(`Base coords: ${baseLat}, ${baseLng}. Encontrados ${rows.length} clientes.`);

  const updatedIds = [];
  for (const r of rows) {
    const id = r.id;
    const offset = ((id % 10) + 1) * 0.0008 + ((id % 7) * 0.0001);
    const lat = baseLat + ((id % 2 === 0) ? offset : -offset);
    const lng = baseLng + ((id % 3 === 0) ? -offset : offset);

    await query('UPDATE clientes SET latitud = $1, longitud = $2 WHERE id = $3', [lat, lng, id]);
    updatedIds.push(id);
    console.log(`Updated id=${id} -> lat=${lat.toFixed(6)}, lng=${lng.toFixed(6)}`);
  }

  const sel = await query('SELECT id, nombre_negocio, latitud, longitud FROM clientes WHERE id = ANY($1)', [updatedIds]);
  console.log('Registros actualizados:');
  console.table(sel.rows);
  process.exit(0);
}

main().catch(err => {
  console.error('Error durante la actualización:', err);
  process.exit(1);
});
