const { Pool } = require('pg');

const local = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'distriexpress',
  user: 'postgres',
  password: 'root',
});

const clientesNuevos = [
  {
    nombre_negocio: 'Supermercado Central',
    nombre_propietario: 'Carlos López',
    direccion: 'Carrera 45 #20-30',
    municipio: 'Medellín',
    departamento: 'Antioquia',
    locacion: 'Centro',
    telefono: '3001234567',
    latitud: 6.2442,
    longitud: -75.5812,
  },
  {
    nombre_negocio: 'Abarrotes Don Juan',
    nombre_propietario: 'Juan García',
    direccion: 'Avenida 33 #48-50',
    municipio: 'Sabaneta',
    departamento: 'Antioquia',
    locacion: 'Sabaneta',
    telefono: '3109876543',
    latitud: 6.1563,
    longitud: -75.5895,
  },
  {
    nombre_negocio: 'Tienda Familiar Los Andes',
    nombre_propietario: 'Rosa Martínez',
    direccion: 'Diagonal 75 #52-25',
    municipio: 'La Estrella',
    departamento: 'Antioquia',
    locacion: 'La Estrella',
    telefono: '3115554444',
    latitud: 6.1823,
    longitud: -75.6123,
  },
  {
    nombre_negocio: 'Minimarket Express',
    nombre_propietario: 'Pedro Sánchez',
    direccion: 'Calle 10 #65-40',
    municipio: 'Caldas',
    departamento: 'Antioquia',
    locacion: 'Caldas',
    telefono: '3125557777',
    latitud: 6.1234,
    longitud: -75.5456,
  },
  {
    nombre_negocio: 'Despensa del Barrio',
    nombre_propietario: 'Ana Rodríguez',
    direccion: 'Carrera 80 #35-12',
    municipio: 'Copacabana',
    departamento: 'Antioquia',
    locacion: 'Copacabana',
    telefono: '3139999888',
    latitud: 6.3234,
    longitud: -75.4567,
  },
  {
    nombre_negocio: 'Comercial Éxito',
    nombre_propietario: 'Fernando Díaz',
    direccion: 'Avenida 41 #78-99',
    municipio: 'Bello',
    departamento: 'Antioquia',
    locacion: 'Bello',
    telefono: '3001234111',
    latitud: 6.3456,
    longitud: -75.5234,
  },
];

(async () => {
  try {
    await local.query('SET search_path TO distriexpress, public');

    console.log('📤 Agregando 6 clientes nuevos...\n');

    for (const cliente of clientesNuevos) {
      const res = await local.query(`
        INSERT INTO clientes (
          nombre_negocio, nombre_propietario, direccion, municipio, 
          departamento, locacion, telefono, latitud, longitud
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, nombre_negocio, municipio
      `, [
        cliente.nombre_negocio,
        cliente.nombre_propietario,
        cliente.direccion,
        cliente.municipio,
        cliente.departamento,
        cliente.locacion,
        cliente.telefono,
        cliente.latitud,
        cliente.longitud,
      ]);
      
      const c = res.rows[0];
      console.log(`✅ Cliente ${c.id}: ${c.nombre_negocio} (${c.municipio})`);
    }

    // Verify total
    const totalRes = await local.query('SELECT COUNT(*) as total FROM clientes');
    console.log(`\n✅ Total de clientes en BD: ${totalRes.rows[0].total}`);

    await local.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    await local.end();
    process.exit(1);
  }
})();
