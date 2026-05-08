const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const cloudinary = require('cloudinary').v2;
const { query } = require('../src/config/database');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const FOLDER = process.env.CLOUDINARY_PRODUCTS_FOLDER || 'distriexpress/productos';

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function scoreMatch(productName, asset) {
  const product = normalizeText(productName);
  const publicId = normalizeText(asset.public_id);
  const original = normalizeText(asset.original_filename || '');

  if (!product || !publicId) return 0;
  if (product === publicId || product === original) return 100;
  if (publicId.includes(product) || product.includes(publicId)) return 80;
  if (original.includes(product) || product.includes(original)) return 70;

  const productWords = product.split(' ').filter(Boolean);
  const publicWords = publicId.split(' ').filter(Boolean);
  const common = productWords.filter((w) => publicWords.includes(w)).length;
  return common * 10;
}

async function listAssets(folder) {
  const all = [];
  let nextCursor;

  do {
    const result = await cloudinary.api.resources({
      type: 'upload',
      prefix: folder,
      max_results: 500,
      next_cursor: nextCursor,
      resource_type: 'image',
    });
    all.push(...(result.resources || []));
    nextCursor = result.next_cursor;
  } while (nextCursor);

  return all;
}

async function main() {
  if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
    console.error('Faltan credenciales de Cloudinary en .env');
    process.exit(1);
  }

  console.log(`Leyendo recursos de Cloudinary en carpeta: ${FOLDER}`);
  const assets = await listAssets(FOLDER);
  console.log(`Encontrados ${assets.length} recursos en Cloudinary.`);

  if (assets.length === 0) {
    console.log('No hay imágenes en la carpeta indicada.');
    process.exit(0);
  }

  const productosRes = await query('SELECT id, nombre, imagen_url FROM productos ORDER BY id');
  const productos = productosRes.rows;

  const updates = [];
  const usedAssets = new Set();

  for (const producto of productos) {
    const alreadyCloudinary = String(producto.imagen_url || '').includes('cloudinary.com');
    if (alreadyCloudinary) {
      console.log(`Saltando producto ${producto.id} (${producto.nombre}) porque ya tiene Cloudinary.`);
      continue;
    }

    let bestAsset = null;
    let bestScore = 0;

    for (const asset of assets) {
      if (usedAssets.has(asset.asset_id)) continue;
      const score = scoreMatch(producto.nombre, asset);
      if (score > bestScore) {
        bestScore = score;
        bestAsset = asset;
      }
    }

    if (bestAsset && bestScore >= 50) {
      await query('UPDATE productos SET imagen_url = $1 WHERE id = $2', [bestAsset.secure_url, producto.id]);
      usedAssets.add(bestAsset.asset_id);
      updates.push({ id: producto.id, nombre: producto.nombre, url: bestAsset.secure_url });
      console.log(`Actualizado: ${producto.nombre} -> ${bestAsset.public_id}`);
    } else {
      console.log(`Sin coincidencia: ${producto.nombre}`);
    }
  }

  console.log('\nResumen de cambios:');
  if (updates.length === 0) {
    console.log('No se actualizó ningún producto.');
  } else {
    for (const u of updates) {
      console.log(`- ${u.id}: ${u.nombre}`);
      console.log(`  ${u.url}`);
    }
  }

  process.exit(0);
}

main().catch((err) => {
  console.error('Error sincronizando imágenes de Cloudinary:', err.message);
  process.exit(1);
});
