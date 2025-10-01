// Bump this on each deploy to force updates:
const CACHE = 'aurora-shell-v1';
const SHELL = [
  '/', '/manifest.webmanifest',
  '/icons/icon-192.png', '/icons/icon-512.png', '/icons/icon-512-maskable.png',
  '/theme.css'
];

self.addEventListener('install', (e) => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  // Never cache backend/model/tool calls
  if (url.pathname.startsWith('/api')) return;
  // Stale-while-revalidate for static/doc requests
  e.respondWith(
    caches.match(e.request).then(cached => {
      const fetchPromise = fetch(e.request).then(resp => {
        if (resp.ok && resp.type === 'basic') {
          const clone = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return resp;
      }).catch(() => cached);
      return cached || fetchPromise;
    })
  );
});
