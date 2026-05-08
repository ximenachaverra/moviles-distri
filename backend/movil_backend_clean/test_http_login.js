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
        console.log('Response:', respData);
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

(async () => {
  try {
    console.log('Intentando login...\n');
    const result = await post('/api/auth/login', {
      email: 'promotor@test.com',
      password: '12345678'
    });
    
    console.log('\n✅ Login exitoso');
    console.log('Token:', result.token?.substring(0, 30) + '...');
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
})();
