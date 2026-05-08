#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const cloudinary = require('cloudinary').v2;
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { query } = require('../src/config/database');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const MAP_FILE = path.join(__dirname, 'product-image-map.json');

function assertCloudinaryConfigured() {
  if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
    throw new Error('Cloudinary no está configurado en .env');
  }
}

function resolveImageUrl(entry) {
  if (entry.url && String(entry.url).trim()) {
    return String(entry.url).trim();
  }

  if (entry.public_id && String(entry.public_id).trim()) {
    return cloudinary.url(String(entry.public_id).trim(), {
      secure: true,
      transformation: [
        { width: 800, height: 800, crop: 'limit', quality: 'auto', fetch_format: 'auto' },
      ],
    });
  }

  return null;
}

async function main() {
  assertCloudinaryConfigured();

  if (!fs.existsSync(MAP_FILE)) {
    throw new Error(`No existe el archivo de mapeo: ${MAP_FILE}`);
  }

  const raw = fs.readFileSync(MAP_FILE, 'utf8');
  const entries = JSON.parse(raw);

  if (!Array.isArray(entries)) {
    throw new Error('El archivo product-image-map.json debe contener un array');
  }

  const current = await query('SELECT id, nombre, imagen_url FROM productos ORDER BY id');
  const byId = new Map(current.rows.map((row) => [Number(row.id), row]));

  const updates = [];

  for (const entry of entries) {
    const id = Number(entry.id);
    if (!id || !byId.has(id)) {
      console.log(`Saltando id inválido o inexistente: ${entry.id}`);
      continue;
    }

    const url = resolveImageUrl(entry);
    if (!url) {
      console.log(`Sin URL/public_id para producto ${id} (${entry.nombre || byId.get(id).nombre}), se omite.`);
      continue;
    }

    await query('UPDATE productos SET imagen_url = $1 WHERE id = $2', [url, id]);
    updates.push({ id, nombre: byId.get(id).nombre, url });
    console.log(`Actualizado producto ${id}: ${byId.get(id).nombre}`);
  }

  console.log('\nResumen:');
  if (updates.length === 0) {
    console.log('No hubo cambios.');
  } else {
    for (const u of updates) {
      console.log(`- ${u.id} ${u.nombre}`);
      console.log(`  ${u.url}`);
    }
  }
}

main().catch((err) => {
  console.error('Error actualizando imágenes:', err.message);
  process.exit(1);
});
