const http = require('http');

function post(path, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);
    const options = {
      hostname: 'localhost',
      port: 5001,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = http.request(options, (res) => {
      let respData = '';
      res.on('data', chunk => respData += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(respData));
        } catch(e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function get(path, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5001,
      path: path,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`\n[DEBUG] GET ${path}`);
        console.log(`[DEBUG] Status: ${res.statusCode}`);
        try {
          resolve(JSON.parse(data));
        } catch(e) {
          console.log('[DEBUG] Response:', data);
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

(async () => {
  try {
    console.log('🔐 Iniciando sesión...\n');
    const loginRes = await post('/api/auth/login', {
      email: 'promotor@test.com',
      password: '12345678'
    });
    
    if (!loginRes.token) {
      throw new Error('Login failed: ' + JSON.stringify(loginRes));
    }
    
    const token = loginRes.token;
    console.log('✅ Sesión iniciada\n');

    // Get clients
    console.log('📦 Obteniendo CLIENTES desde AWS RDS...');
    const clientes = await get('/api/clientes', token);
    
    if (Array.isArray(clientes)) {
      console.log(`✅ TOTAL DE CLIENTES: ${clientes.length}\n`);
      console.log('📋 Listado:');
      clientes.forEach((c, i) => {
        console.log(`   ${i+1}. ${c.nombre} - ${c.zona}`);
      });
    } else {
      console.log('❌ Error:', clientes);
    }

    // Get Cloudinary images
    console.log('\n\n🖼️  Obteniendo IMÁGENES desde Cloudinary...');
    const imagenes = await get('/api/cloudinary/imagenes', token);
    
    if (imagenes.imagenes) {
      console.log(`✅ TOTAL DE IMÁGENES: ${imagenes.total}\n`);
      console.log('📸 Primeras 5 imágenes:');
      imagenes.imagenes.slice(0, 5).forEach((img, i) => {
        console.log(`   ${i+1}. ${img.nombre}`);
        console.log(`      URL: ${img.url.substring(0, 80)}...`);
      });
    } else {
      console.log('❌ Error:', imagenes);
    }

    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
