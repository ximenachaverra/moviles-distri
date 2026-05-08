// Intercepta todos los errores que llegan con next(error)
// y devuelve una respuesta JSON limpia sin exponer stack traces en producción.
const errorHandler = (err, req, res, next) => {
  console.error(`[ERROR] ${req.method} ${req.path} →`, err.message);

  // Error de violación de unicidad en PostgreSQL (código 23505)
  if (err.code === '23505') {
    return res.status(409).json({ error: 'Registro duplicado' });
  }

  // Error de clave foránea en PostgreSQL (código 23503)
  if (err.code === '23503') {
    return res.status(400).json({ error: 'Referencia inválida en los datos' });
  }

  const statusCode = err.statusCode || 500;
  const message =
    process.env.NODE_ENV === 'production'
      ? 'Error interno del servidor'
      : err.message;

  res.status(statusCode).json({ error: message });
};

module.exports = { errorHandler };
