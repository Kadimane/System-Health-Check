import http from 'k6/http';
import { check, sleep } from 'k6';

// Simulates salary-date spike: ramp to 500 users, hold, then ramp down
export const options = {
  stages: [
    { duration: '2m', target: 100 },   // warm up
    { duration: '5m', target: 500 },   // peak salary-date load
    { duration: '2m', target: 500 },   // hold peak
    { duration: '1m', target: 0 },     // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'],  // 95% of requests under 3s
    http_req_failed:   ['rate<0.05'],   // error rate under 5%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:80';

export default function () {
  const res = http.get(`${BASE_URL}/health`);
  check(res, {
    'status is 200':        (r) => r.status === 200,
    'response time < 3s':   (r) => r.timings.duration < 3000,
  });
  sleep(1);
}
