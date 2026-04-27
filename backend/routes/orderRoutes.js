// backend/routes/orderRoutes.js
// =====================================================
// ORDER ROUTES
// =====================================================

const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

// Patient routes
router.post('/create', orderController.createOrder);
router.get('/my-orders', orderController.getMyOrders);
router.get('/:orderId', orderController.getOrderDetails);

// Pharmacy routes
router.put('/:orderId/status', orderController.updateOrderStatus);

module.exports = router;