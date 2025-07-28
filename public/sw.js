// Service Worker for Nepal Air Quality Monitor
const CACHE_NAME = 'nepal-air-quality-v1';
const urlsToCache = [
  '/',
  '/map',
  '/rankings',
  '/manifest.json',
  // Add critical assets here
];

// Install event - cache resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return cache.addAll(urlsToCache);
      })
  );
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') {
    return;
  }

  // Skip chrome-extension and other non-http requests
  if (!event.request.url.startsWith('http')) {
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        return response || fetch(event.request)
          .then((fetchResponse) => {
            // Don't cache API responses or external requests
            if (!fetchResponse || fetchResponse.status !== 200 || fetchResponse.type !== 'basic') {
              return fetchResponse;
            }

            // Clone the response
            const responseToCache = fetchResponse.clone();

            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseToCache);
              });

            return fetchResponse;
          })
          .catch(() => {
            // Return offline page for navigation requests
            if (event.request.mode === 'navigate') {
              return caches.match('/');
            }
          });
      })
  );
});

// Background sync for data updates
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-air-quality-sync') {
    event.waitUntil(updateAirQualityData());
  }
});

// Push notification handler
self.addEventListener('push', (event) => {
  const options = {
    body: event.data ? event.data.text() : 'Air quality update available',
    icon: '/icon-192.png',
    badge: '/icon-72.png',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: 'View Details',
        icon: '/icon-current-location.png'
      },
      {
        action: 'close',
        title: 'Close',
        icon: '/icon-close.png'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('Nepal Air Quality', options)
  );
});

// Notification click handler
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Periodic background sync (requires registration)
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'air-quality-update') {
    event.waitUntil(updateAirQualityData());
  }
});

// Helper function to update air quality data
async function updateAirQualityData() {
  try {
    // Fetch latest air quality data
    const response = await fetch('/api/cities');
    if (response.ok) {
      const data = await response.json();
      
      // Store in IndexedDB or send notification if needed
      console.log('Background sync: Updated air quality data');
      
      // You could implement logic here to check for air quality alerts
      // and send push notifications if AQI exceeds certain thresholds
    }
  } catch (error) {
    console.error('Background sync failed:', error);
  }
}