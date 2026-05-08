const http = require('http');

http.get('http://localhost:5001/api/clientes', {headers: {'Authorization': 'Bearer test'}}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      console.log('\n📦 Clientes recibidos:', parsed.length);
      console.log('\n📋 Listado:');
      parsed.forEach((c, i) => {
        console.log(`   ${i+1}. ${c.nombre} - ${c.zona}`);
      });
      
      console.log('\n✅ Primeros clientes tienen campos corretos:');
      if (parsed[0]) {
        console.log(`   Campos: ${Object.keys(parsed[0]).join(', ')}`);
      }
    } catch(e) {
      console.log('Response:', data);
    }
    process.exit(0);
  });
}).on('error', e => {
  console.error('Error:', e.message);
  process.exit(1);
});
