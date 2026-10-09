'use strict';
// Naikkan versi CACHE saat mengubah file yang disimpan offline.
const CACHE = 'lab-sample-pages-v2';
const SCOPE = self.registration.scope;
const INDEX = new URL('index.html', SCOPE).href;
const ASSETS = [SCOPE, INDEX];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(ASSETS)));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(
    keys.filter(key => key.startsWith('lab-sample-pages-') && key !== CACHE)
      .map(key => caches.delete(key))
  )).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || !event.request.url.startsWith(SCOPE)) return;
  const isPage = event.request.mode === 'navigate' &&
    (url.href === SCOPE || url.pathname === new URL(INDEX).pathname);
  if (!isPage && url.href !== INDEX) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    try {
      const response = await fetch(event.request);
      if (response.ok) {
        await cache.put(INDEX, response.clone());
        return response;
      }
      const saved = await cache.match(INDEX);
      return saved || response;
    } catch (error) {
      const saved = await cache.match(INDEX);
      if (saved) return saved;
      throw error;
    }
  })());
});
