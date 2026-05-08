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
    console.log('🔐 Iniciando sesión con promotor...');
    const loginRes = await post('/api/auth/login', {
      email: 'ximenachaverra8@gmail.com',
      password: 'password'
    });
    
    if (!loginRes.token) {
      console.log('❌ No token. Response:', loginRes);
      // Try another user
      console.log('\n🔐 Intentando con otro usuario...');
      const loginRes2 = await post('/api/auth/login', {
        email: 'maria@distriexpress.com',
        password: 'password'
      });
      if (!loginRes2.token) {
        throw new Error('No se pudo obtener token. Respuesta: ' + JSON.stringify(loginRes2));
      }
      var token = loginRes2.token;
    } else {
      var token = loginRes.token;
    }
    
    console.log('✅ Sesión iniciada\n');

    // Get clients from API
    console.log('📦 Consultando /api/clientes desde API...');
    const clientes = await get('/api/clientes', token);
    
    if (Array.isArray(clientes)) {
      console.log(`✅ Clientes retornados por API: ${clientes.length}`);
      if (clientes.length > 0) {
        console.log('\n📋 Primeros 3 clientes:');
        clientes.slice(0, 3).forEach((c, i) => {
          console.log(`   ${i+1}. ${c.nombre} - ${c.zona}`);
        });
        console.log(`\n✅ Estructura de cliente:`);
        console.log(`   Campos: ${Object.keys(clientes[0]).join(', ')}`);
      }
    } else {
      console.log('❌ Response no es array:', clientes);
    }

    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
