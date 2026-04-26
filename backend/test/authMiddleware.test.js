const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const { authenticate } = require('../middleware/authMiddleware');

// Set test environment variables
process.env.JWT_SECRET = 'test-secret';

// Create a test app
const app = express();
app.use(express.json());

// Protected route
app.get('/protected', authenticate, (req, res) => {
  res.json({ success: true, user: req.user });
});

// Unprotected route
app.get('/public', (req, res) => {
  res.json({ success: true, message: 'Public route' });
});

const JWT_SECRET = process.env.JWT_SECRET;

describe('Authentication Middleware', () => {
  test('should allow access with valid JWT token', async () => {
    const token = jwt.sign({ user_id: 1, role: 'doctor' }, JWT_SECRET);

    const response = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.user.user_id).toBe(1);
    expect(response.body.user.role).toBe('doctor');
  });

  test('should deny access without token', async () => {
    const response = await request(app).get('/protected');

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toContain('Authorization token is required');
  });

  test('should deny access with invalid token', async () => {
    const response = await request(app)
      .get('/protected')
      .set('Authorization', 'Bearer invalid-token');

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toContain('Invalid or expired token');
  });

  test('should allow access to public routes without token', async () => {
    const response = await request(app).get('/public');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
  });
});