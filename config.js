// Hanya isi URL proyek dan PUBLISHABLE KEY. Keduanya boleh berada di frontend.
// Jangan pernah masukkan secret key, service_role, password akun, atau password database.
window.LAB_CONFIG = {
  supabaseUrl: 'https://qvetnqzeiemuazrbjpbh.supabase.co/rest/v1/',
  publishableKey: 'sb_publishable_xdvt9Mr5Ey9IZsUe8n2Vjw_pQ1sZZ4r',
  // URL GitHub Pages final; jangan memakai slash wildcard.
  appUrl: 'https://nprd-rnd.github.io/Penerimaan-Sampel-/'
};

if ('serviceWorker' in navigator && location.protocol === 'https:') { navigator.serviceWorker.getRegistration().then(r => { if (r) r.update().catch(() => {}); }); }
