const axios = require('axios');
const crypto = require('crypto');

const CLOUD_NAME = 'ddfgyodh2';
const API_KEY = '926673716136137';
const API_SECRET = '_rw-MNbO-SgAM4Q7x-urvNO0-mk';

(async () => {
  try {
    console.log('🔐 Probando autenticación con Cloudinary...\n');
    console.log('Cloud Name:', CLOUD_NAME);
    console.log('API Key:', API_KEY.substring(0, 10) + '...');
    console.log('API Secret:', API_SECRET.substring(0, 10) + '...\n');

    // Test 1: Sin firma (debería fallar)
    console.log('Test 1: Request sin firma');
    try {
      const res1 = await axios.get(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/resources/image`, {
        params: {
          max_results: 1
        }
      });
      console.log('✅ Funcionó sin firma (no debería)');
    } catch(e) {
      console.log('❌ Error (esperado):', e.response?.status, e.response?.data?.error?.message || e.message);
    }

    // Test 2: Con autenticación Basic Auth
    console.log('\nTest 2: Con Basic Auth');
    try {
      const auth = Buffer.from(`${API_KEY}:${API_SECRET}`).toString('base64');
      const res2 = await axios.get(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/resources/image`, {
        params: {
          prefix: 'distriexpress',
          max_results: 5
        },
        headers: {
          'Authorization': `Basic ${auth}`
        }
      });
      console.log('✅ Con Basic Auth funcionó!');
      console.log('Total recursos:', res2.data.resource_count);
    } catch(e) {
      console.log('❌ Error:', e.response?.status, e.response?.data?.error?.message || e.message);
    }

    // Test 3: Con firma en query params (sin prefix en la firma)
    console.log('\nTest 3: Con firma en query params (sin prefix)');
    try {
      const timestamp = Math.floor(Date.now() / 1000);
      const paramsParaFirma = {
        max_results: 5,
        timestamp,
        type: 'upload',
      };

      const signString = Object.keys(paramsParaFirma)
        .sort()
        .map(key => `${key}=${paramsParaFirma[key]}`)
        .join('&');

      const signature = crypto
        .createHash('sha1')
        .update(signString + API_SECRET)
        .digest('hex');

      console.log('Signature:', signature);
      
      const res3 = await axios.get(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/resources/image`, {
        params: {
          ...paramsParaFirma,
          prefix: 'distriexpress', // Agregar pero no incluir en firma
          api_key: API_KEY,
          signature,
        }
      });
      console.log('✅ Con firma funcionó!');
      console.log('Total recursos:', res3.data.resource_count);
    } catch(e) {
      console.log('❌ Error:', e.response?.status, e.response?.data?.error?.message || e.message);
    }
  } catch (e) {
    console.error('Error:', e.message);
  }
})();
