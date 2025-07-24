import http from 'k6/http';
import { sleep, check, group } from 'k6';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 users over 30 seconds
    { duration: '1m', target: 20 },   // Ramp up to 20 users over 1 minute
    { duration: '2m', target: 20 },   // Stay at 20 users for 2 minutes
    { duration: '30s', target: 0 },   // Ramp down to 0 users over 30 seconds
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.01'],   // Less than 1% of requests should fail
  },
};

const BASE_URL = 'http://localhost';

export default function () {
  group('Static endpoints', function () {
    // Test the root endpoint
    const rootRes = http.get(`${BASE_URL}/`);
    check(rootRes, {
      'root status is 200': (r) => r.status === 200,
      'root response time < 200ms': (r) => r.timings.duration < 200,
    });
    
    // Test the health endpoint
    const healthRes = http.get(`${BASE_URL}/health`);
    check(healthRes, {
      'health status is 200': (r) => r.status === 200,
      'health response has status ok': (r) => JSON.parse(r.body).status === 'ok',
    });
    
    sleep(1);
  });
  
  group('Book listing', function () {
    // Get all books
    const booksRes = http.get(`${BASE_URL}/books`);
    check(booksRes, {
      'books status is 200': (r) => r.status === 200,
      'books response is an array': (r) => Array.isArray(JSON.parse(r.body)),
      'books response time < 300ms': (r) => r.timings.duration < 300,
    });
    
    sleep(1);
  });
  
  group('Single book operations', function () {
    // Get a single book (valid ID)
    const bookId = randomIntBetween(1, 3);
    const bookRes = http.get(`${BASE_URL}/books/${bookId}`);
    check(bookRes, {
      'single book status is 200': (r) => r.status === 200,
      'single book has correct id': (r) => JSON.parse(r.body).id === bookId,
    });
    
    // Get a non-existent book
    const nonExistentId = 999;
    const nonExistentRes = http.get(`${BASE_URL}/books/${nonExistentId}`);
    check(nonExistentRes, {
      'non-existent book returns 404': (r) => r.status === 404,
    });
    
    sleep(1);
  });
  
  group('Error simulation', function () {
    // Occasionally hit the error endpoint to generate some errors
    if (Math.random() < 0.3) {  // 30% chance to hit the error endpoint
      const errorRes = http.get(`${BASE_URL}/error`);
      check(errorRes, {
        'error endpoint responded': (r) => r.status === 200 || r.status === 500,
      });
    }
    
    sleep(1);
  });
}
