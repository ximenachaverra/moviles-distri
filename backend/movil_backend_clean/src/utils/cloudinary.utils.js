const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Sube una imagen a Cloudinary
 * @param {Buffer} fileBuffer - Buffer del archivo
 * @param {string} folder - Carpeta destino en Cloudinary (ej: 'distriexpress/productos')
 * @returns {Promise<string>} URL segura de la imagen
 */
const subirImagen = (fileBuffer, folder = 'distriexpress/productos') => {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        transformation: [{ width: 800, height: 800, crop: 'limit', quality: 'auto', format: 'webp' }],
      },
      (error, result) => {
        if (error) reject(error);
        else resolve(result.secure_url);
      }
    );
    stream.end(fileBuffer);
  });
};

/**
 * Elimina una imagen de Cloudinary por URL
 * @param {string} url - URL de Cloudinary
 */
const eliminarImagen = async (url) => {
  if (!url || !url.includes('cloudinary')) return;
  try {
    const parts = url.split('/upload/');
    if (parts[1]) {
      const publicId = parts[1].replace(/v\d+\//, '').replace(/\.[^.]+$/, '');
      await cloudinary.uploader.destroy(publicId);
    }
  } catch (e) { console.error('Error eliminando imagen:', e.message); }
};

module.exports = { subirImagen, eliminarImagen };
