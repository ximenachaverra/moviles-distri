#!/usr/bin/env node
/**
 * Script para cargar imágenes de muestra a Cloudinary y actualizar la BD.
 * Uso: node scripts/upload_sample_images.js
 *
 * Antes de ejecutar:
 * 1. Crea una cuenta en https://cloudinary.com (free tier disponible)
 * 2. Copia tus credenciales: https://console.cloudinary.com/settings/api
 * 3. Rellena CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET en .env
 * 4. Ejecuta: npm install --save cloudinary
 * 5. Ejecuta este script: node scripts/upload_sample_images.js
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { subirImagen } = require('../src/utils/cloudinary.utils');
const { query } = require('../src/config/database');

async function main() {
  // Verificar credenciales
  if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY) {
    console.error(
      '❌ Error: Credenciales de Cloudinary no configuradas en .env\n' +
      'Sigue estos pasos:\n' +
      '1. Abre https://cloudinary.com/users/register/free\n' +
      '2. Copia tu Cloud Name desde https://console.cloudinary.com/settings/api\n' +
      '3. Genera un API Key y Secret\n' +
      '4. Rellena .env con:\n' +
      '   CLOUDINARY_CLOUD_NAME=tu_cloud_name\n' +
      '   CLOUDINARY_API_KEY=tu_api_key\n' +
      '   CLOUDINARY_API_SECRET=tu_api_secret\n' +
      '5. Vuelve a ejecutar este script.'
    );
    process.exit(1);
  }

  console.log('📦 Cargando imágenes de muestra a Cloudinary...');

  // Imágenes de muestra: SVG simple con nombre del producto
  const productos = [
    { id: 1, nombre: 'Arroz Integral Orgánico', color: '#f59e0b' },
    { id: 2, nombre: 'Aceite de Oliva Extra Virgen', color: '#10b981' },
    { id: 3, nombre: 'Quinoa Real Premium', color: '#f97316' },
    { id: 4, nombre: 'Sal Marina Fina', color: '#0ea5e9' },
    { id: 5, nombre: 'Pasta Fusilli Integral', color: '#d946ef' },
    { id: 6, nombre: 'Lentejas Rojas', color: '#ef4444' },
    { id: 7, nombre: 'Miel de Abeja Pura', color: '#f59e0b' },
    { id: 8, nombre: 'Avena en Hojuelas', color: '#8b5cf6' },
    { id: 9, nombre: 'Vinagre Balsámico', color: '#6366f1' },
    { id: 10, nombre: 'Garbanzos Secos', color: '#ec4899' },
  ];

  const uploaded = [];

  for (const prod of productos) {
    try {
      // Generar SVG simple como imagen de muestra
      const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800">
        <rect width="100%" height="100%" fill="${prod.color}"/>
        <text x="400" y="400" dominant-baseline="middle" text-anchor="middle" 
              fill="white" font-family="Arial" font-size="48" font-weight="bold">
          ${prod.nombre.substring(0, 30)}
        </text>
      </svg>`;

      const buffer = Buffer.from(svg);
      const cloudinaryUrl = await subirImagen(buffer, 'distriexpress/productos');
      console.log(`✅ Producto ${prod.id}: ${prod.nombre}`);

      // Actualizar BD con la URL de Cloudinary
      await query('UPDATE productos SET imagen_url = $1 WHERE id = $2', [cloudinaryUrl, prod.id]);
      uploaded.push({ id: prod.id, url: cloudinaryUrl });
    } catch (err) {
      console.error(`❌ Error subiendo producto ${prod.id}:`, err.message);
    }
  }

  console.log(`\n✅ Carga completada: ${uploaded.length}/${productos.length} imágenes actualizadas`);
  uploaded.forEach(u => console.log(`  ${u.url}`));
  process.exit(0);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
