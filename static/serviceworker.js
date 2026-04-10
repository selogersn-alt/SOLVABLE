const CACHE_NAME = 'solvable-v1';
const urlsToCache = [
  '/',
  '/static/css/style.css',
  '/static/img/icon-192x192.png',
  '/static/img/icon-512x512.png',
  '/offline/'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
      .catch(() => caches.match('/offline/'))
  );
});
