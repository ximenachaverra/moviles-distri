(async ()=>{
  try{
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6OCwiZW1haWwiOiJwcm9tb3RvckBjb3JyZW8uY29tIiwiaWF0IjoxNzc3MzIxMDM4LCJleHAiOjE3Nzc5MjU4Mzh9.upFoPl-eZxJVMjT4T7VySBcAUrC3fGhCCURgxZ3vjr8';
    const headers = { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token };

    const cRes = await fetch('http://localhost:5001/api/clientes',{ headers });
    const clientes = await cRes.json();
    console.log('clientes:', clientes.length);

    const pRes = await fetch('http://localhost:5001/api/productos',{ headers });
    const productos = await pRes.json();
    console.log('productos:', productos.length);

    console.log('clientes sample:', JSON.stringify(clientes.slice(0,3), null, 2));
    console.log('productos sample:', JSON.stringify(productos.slice(0,3), null, 2));
  } catch(e){ console.error('ERROR', e); process.exit(1); }
})();
