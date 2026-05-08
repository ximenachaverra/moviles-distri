(async ()=>{
  try{
    const res = await fetch('http://localhost:5001/api/auth/login',{
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ email: 'promotor@correo.com', password: 'cualquiera' })
    });
    const txt = await res.text();
    console.log(txt);
  } catch(e){ console.error('ERROR', e); process.exit(1); }
})();
