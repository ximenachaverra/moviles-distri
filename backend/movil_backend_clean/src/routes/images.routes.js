const router = require('express').Router();
const { query } = require('../config/database');

// GET /images/producto/:id
// Proxies the producto.imagen_url so the web client can load images from localhost.
router.get('/producto/:id', async (req, res, next) => {
  try {
    const id = parseInt(req.params.id, 10);
    const { rows } = await query('SELECT imagen_url FROM productos WHERE id = $1', [id]);
    if (!rows || rows.length === 0) return res.status(404).send('Not found');
    const url = rows[0].imagen_url;
    if (!url) return res.status(404).send('No image');

    // Try to fetch remote image; if that fails (network blocked), return
    // a generated SVG placeholder containing the product name.
    try {
      const upstream = await fetch(url);
      if (upstream.ok) {
        const contentType = upstream.headers.get('content-type') || 'application/octet-stream';
        const cache = upstream.headers.get('cache-control') || 'public, max-age=3600';
        res.setHeader('Content-Type', contentType);
        res.setHeader('Cache-Control', cache);
        const body = upstream.body;
        if (body && body.pipe) return body.pipe(res);
        const buf = Buffer.from(await upstream.arrayBuffer());
        return res.send(buf);
      }
    } catch (err) {
      // fall through to generate SVG placeholder
    }

    // Upstream failed or returned non-ok — generate an inline SVG placeholder
    // with the product name (safe and no external network required).
    const nameRow = await query('SELECT nombre FROM productos WHERE id = $1', [id]);
    const name = (nameRow.rows && nameRow.rows[0] && nameRow.rows[0].nombre) ? String(nameRow.rows[0].nombre) : `Producto ${id}`;
    const svg = `<?xml version="1.0" encoding="UTF-8"?>\n` +
      `<svg xmlns='http://www.w3.org/2000/svg' width='400' height='300'>` +
      `<rect width='100%' height='100%' fill='#f3f4f6'/>` +
      `<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' fill='#374151' font-family='Arial, sans-serif' font-size='20'>` +
      `${escapeXml(name)}` +
      `</text></svg>`;
    res.setHeader('Content-Type', 'image/svg+xml');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    return res.send(svg);
  } catch (err) {
    next(err);
  }
});

// small helper to escape XML special chars
function escapeXml(str) {
  return String(str).replace(/[<>&"']/g, (c) => ({
    '<': '&lt;',
    '>': '&gt;',
    '&': '&amp;',
    '"': '&quot;',
    "'": '&apos;'
  }[c]));
}

module.exports = router;
