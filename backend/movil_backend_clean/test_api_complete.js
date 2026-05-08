const http = require('http');

// Helper para hacer requests POST
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

// Helper para hacer requests GET
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
    // Login
    console.log('🔐 Iniciando sesión...');
    const loginRes = await post('/api/auth/login', {
      email: 'promotor@example.com',
      password: 'password123'
    });
    
    if (!loginRes.token) {
      throw new Error('No token received: ' + JSON.stringify(loginRes));
    }
    
    const token = loginRes.token;
    console.log('✅ Token obtenido\n');

    // Get clients
    console.log('📦 Obteniendo clientes...');
    const clientes = await get('/api/clientes', token);
    
    if (Array.isArray(clientes)) {
      console.log(`✅ Clientes recibidos: ${clientes.length}\n`);
      console.log('📋 Listado:');
      clientes.forEach((c, i) => {
        console.log(`   ${i+1}. ${c.nombre || c.nombre_negocio || 'Sin nombre'}`);
        console.log(`      Zona: ${c.zona}`);
      });
    } else {
      console.log('Response:', clientes);
    }

    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
