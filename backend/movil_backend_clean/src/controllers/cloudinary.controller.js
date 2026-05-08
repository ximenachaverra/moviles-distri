const axios = require('axios');
const crypto = require('crypto');

const CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME || 'ddfgyodh2';
const API_KEY = process.env.CLOUDINARY_API_KEY || '926673716136137';
const API_SECRET = process.env.CLOUDINARY_API_SECRET || '_rw-MNbO-SgAM4Q7x-urvNO0-mk';

// Obtiene el listado de imágenes desde la API de Cloudinary
exports.obtenerImagenesCloudinary = async (req, res, next) => {
  try {
    // Generar firma para autenticación con API de Cloudinary
    const timestamp = Math.floor(Date.now() / 1000);
    const params = {
      timestamp,
      type: 'upload', // Tipo de recursos (upload, facebook, etc.)
      prefix: 'distriexpress', // Filtrar solo imágenes con este prefijo
      max_results: 100,
    };

    const signString = Object.keys(params)
      .sort()
      .map(key => `${key}=${params[key]}`)
      .join('&');

    const signature = crypto
      .createHash('sha1')
      .update(signString + API_SECRET)
      .digest('hex');

    // Llamar a API de Cloudinary
    const url = `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/resources/image`;
    const response = await axios.get(url, {
      params: {
        ...params,
        api_key: API_KEY,
        signature,
      },
    });

    // Procesar respuesta
    const imagenes = response.data.resources.map(r => ({
      id: r.public_id,
      url: r.secure_url || `https://res.cloudinary.com/${CLOUD_NAME}/image/upload/${r.public_id}`,
      nombre: r.public_id.split('/').pop(),
      ancho: r.width,
      alto: r.height,
    }));

    res.json({
      total: response.data.resource_count,
      imagenes,
    });
  } catch (e) {
    next(e);
  }
};

// Obtiene una URL de imagen optimizada para productos
exports.optimizarUrlProducto = (publicId) => {
  if (!publicId) return null;
  return `https://res.cloudinary.com/${CLOUD_NAME}/image/upload/w_400,h_300,c_fill,q_auto/${publicId}`;
};

// Mapeo de productos a public_ids en Cloudinary
// Este mapeo se basa en los nombres/IDs conocidos de productos en la BD
const MAPEO_PRODUCTOS_CLOUDINARY = {
  // Búsqueda por nombre (case-insensitive partial match)
  'arroz': 'distriexpress/arroz',
  'azucar': 'distriexpress/azucar',
  'aceite': 'distriexpress/aceite',
  'harina': 'distriexpress/harina',
  'sal': 'distriexpress/sal',
  'leche': 'distriexpress/leche',
  'pan': 'distriexpress/pan',
  'huevo': 'distriexpress/huevo',
  'café': 'distriexpress/cafe',
  'chocolate': 'distriexpress/chocolate',
};

// Obtiene el public_id de Cloudinary para un producto basado en su nombre
exports.obtenerPublicIdProducto = (nombreProducto) => {
  if (!nombreProducto) return null;
  const nombreLower = nombreProducto.toLowerCase().trim();
  
  // Búsqueda directa
  if (MAPEO_PRODUCTOS_CLOUDINARY[nombreLower]) {
    return MAPEO_PRODUCTOS_CLOUDINARY[nombreLower];
  }
  
  // Búsqueda por palabra clave parcial
  for (const [clave, publicId] of Object.entries(MAPEO_PRODUCTOS_CLOUDINARY)) {
    if (nombreLower.includes(clave) || clave.includes(nombreLower)) {
      return publicId;
    }
  }
  
  // Si no hay mapeo específico, crear una URL genérica basada en el nombre
  const nombreSanitizado = nombreLower.replace(/[^a-z0-9]+/g, '_');
  return `distriexpress/${nombreSanitizado}`;
};
