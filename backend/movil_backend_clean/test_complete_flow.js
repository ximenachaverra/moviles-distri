const http = require('http');

function request(method, path, data, token) {
  return new Promise((resolve, reject) => {
    const isPost = method === 'POST';
    const postData = isPost ? JSON.stringify(data) : null;
    const options = {
      hostname: 'localhost',
      port: 5001,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` }),
        ...(isPost && { 'Content-Length': Buffer.byteLength(postData) })
      }
    };

    const req = http.request(options, (res) => {
      let respData = '';
      res.on('data', chunk => respData += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(respData));
        } catch(e) {
          reject(new Error(`Parse error: ${respData}`));
        }
      });
    });

    req.on('error', reject);
    if (isPost) req.write(postData);
    req.end();
  });
}

(async () => {
  try {
    console.log('═══════════════════════════════════════════════\n');
    console.log('🚀 VERIFICACIÓN COMPLETA - AWS RDS + CLOUDINARY\n');
    console.log('═══════════════════════════════════════════════\n');

    // 1. Login
    console.log('1️⃣  AUTENTICACIÓN');
    console.log('─────────────────────────────────────────────────');
    const login = await request('POST', '/api/auth/login', {
      email: 'promotor@test.com',
      password: '12345678'
    });
    
    if (!login.token) throw new Error('Login falló: ' + JSON.stringify(login));
    const token = login.token;
    console.log('✅ Login exitoso');
    console.log('👤 Usuario:', login.usuario.nombre, login.usuario.apellido);
    console.log('🎯 Rol:', login.usuario.rol);
    console.log('');

    // 2. Clientes
    console.log('2️⃣  CLIENTES (AWS RDS)');
    console.log('─────────────────────────────────────────────────');
    const clientes = await request('GET', '/api/clientes', null, token);
    
    if (!Array.isArray(clientes)) throw new Error('Clientes no es array: ' + JSON.stringify(clientes));
    console.log(`✅ Total: ${clientes.length} clientes`);
    console.log('');
    console.log('📋 Listado:');
    clientes.forEach((c, i) => {
      console.log(`   ${i+1}. ${c.nombre.padEnd(25)} | ${c.zona}`);
    });
    console.log('');

    // 3. Productos (con imágenes de Cloudinary)
    console.log('3️⃣  PRODUCTOS (con imágenes Cloudinary)');
    console.log('─────────────────────────────────────────────────');
    const productos = await request('GET', '/api/productos', null, token);
    
    if (!Array.isArray(productos)) throw new Error('Productos no es array: ' + JSON.stringify(productos));
    console.log(`✅ Total: ${productos.length} productos`);
    console.log('');
    console.log('📦 Primeros 5 productos:');
    productos.slice(0, 5).forEach((p, i) => {
      console.log(`   ${i+1}. ${p.nombre.padEnd(25)} | $${p.precio}`);
      if (p.imagen_url) {
        const url = p.imagen_url;
        const urlCorta = url.length > 60 ? url.substring(0, 57) + '...' : url;
        console.log(`      🖼️  ${urlCorta}`);
      } else {
        console.log(`      ❌ Sin imagen`);
      }
    });
    console.log('');

    // Estadística de imágenes
    const conImagen = productos.filter(p => p.imagen_url).length;
    const sinImagen = productos.length - conImagen;
    console.log(`📊 Cobertura de imágenes: ${conImagen}/${productos.length} (${Math.round(conImagen/productos.length*100)}%)`);
    if (sinImagen > 0) {
      console.log(`   ⚠️  ${sinImagen} productos sin imagen`);
    }
    console.log('');

    console.log('═══════════════════════════════════════════════');
    console.log('✅ VERIFICACIÓN COMPLETADA EXITOSAMENTE');
    console.log('═══════════════════════════════════════════════\n');

    process.exit(0);
  } catch (e) {
    console.error('\n❌ ERROR:', e.message);
    console.error(e);
    process.exit(1);
  }
})();
