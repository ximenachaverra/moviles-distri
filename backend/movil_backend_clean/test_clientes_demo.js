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
        try {
          resolve(JSON.parse(data));
        } catch(e) {
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
    console.log('🔐 Iniciando sesión con DEMO promotor...');
    const loginRes = await post('/api/auth/login', {
      email: 'promotor@correo.com',
      password: 'cualquier'
    });
    
    if (!loginRes.token) {
      console.log('❌ Login failed:', loginRes);
      process.exit(1);
    }
    
    const token = loginRes.token;
    console.log('✅ Sesión iniciada\n');

    // Get clients from API
    console.log('📦 Consultando /api/clientes...');
    const clientes = await get('/api/clientes', token);
    
    if (Array.isArray(clientes)) {
      console.log(`✅ CLIENTES RETORNADOS POR API: ${clientes.length}\n`);
      console.log('📋 Listado de clientes:');
      clientes.forEach((c, i) => {
        console.log(`   ${i+1}. [${c.id}] ${c.nombre} - ${c.zona}`);
      });
    } else {
      console.log('❌ Response:', clientes);
    }

    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
