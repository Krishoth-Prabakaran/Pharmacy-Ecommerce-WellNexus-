// backend/services/notificationService.js
// =====================================================
// NOTIFICATION SERVICE - Email & Push Notifications
// =====================================================

const nodemailer = require('nodemailer');
const pool = require('../config/db');

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: process.env.EMAIL_SECURE === 'true',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

class NotificationService {
  
  /**
   * Send appointment notification
   */
  async sendAppointmentNotification(data) {
    const { patientEmail, patientName, doctorEmail, doctorName, appointmentDate, appointmentTime, type } = data;

    let subject, html;

    if (type === 'new_appointment') {
      subject = `New Appointment Booking - ${appointmentDate}`;
      html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #6366F1;">New Appointment Request</h2>
          <p>Dear ${doctorName},</p>
          <p>A new appointment has been booked by patient. Here are the details:</p>
          <table style="border-collapse: collapse; width: 100%; margin: 16px 0;">
            <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Date:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">${appointmentDate}</td></tr>
            <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Time:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">${appointmentTime}</td></tr>
          </table>
          <p>Please log in to confirm or reschedule this appointment.</p>
          <a href="${process.env.FRONTEND_URL}/doctor/appointments" style="background-color: #6366F1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">View Appointments</a>
        </div>
      `;
    } else if (type === 'appointment_confirmed') {
      subject = `Appointment Confirmed - ${appointmentDate}`;
      html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #10B981;">Appointment Confirmed ✓</h2>
          <p>Dear ${patientName},</p>
          <p>Your appointment has been confirmed. Here are the details:</p>
          <table style="border-collapse: collapse; width: 100%; margin: 16px 0;">
            <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Date:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">${appointmentDate}</td></tr>
            <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Time:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">${appointmentTime}</td></tr>
          </table>
          <p>Please arrive on time for your appointment.</p>
        </div>
      `;
    }

    try {
      const to = doctorEmail || patientEmail;
      await transporter.sendMail({
        from: `"WellNexus Health" <${process.env.EMAIL_USER}>`,
        to,
        subject,
        html
      });
      
      // Store notification in database
      await this.storeNotification(data);
      
      console.log(`✅ ${type} notification sent`);
    } catch (error) {
      console.error('❌ Failed to send notification:', error);
    }
  }

  /**
   * Send order notification
   */
  async sendOrderNotification(data) {
    const { pharmacyEmail, pharmacyName, patientEmail, patientName, orderId, type } = data;

    let subject, html, to;

    if (type === 'new_order') {
      to = pharmacyEmail;
      subject = `New Order Received - Order #${orderId}`;
      html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #6366F1;">New Order Received</h2>
          <p>Dear ${pharmacyName},</p>
          <p>A new order has been placed. Order ID: #${orderId}</p>
          <p>Please process this order as soon as possible.</p>
          <a href="${process.env.FRONTEND_URL}/pharmacy/orders" style="background-color: #6366F1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">View Orders</a>
        </div>
      `;
    } else if (type === 'order_ready') {
      to = patientEmail;
      subject = `Your Order #${orderId} is Ready for Pickup`;
      html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #10B981;">Order Ready for Pickup ✓</h2>
          <p>Dear ${patientName},</p>
          <p>Great news! Your order #${orderId} is ready for pickup at ${pharmacyName}.</p>
          <p>Please bring your prescription when you come to collect your medicines.</p>
          <a href="${process.env.FRONTEND_URL}/patient/orders" style="background-color: #10B981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">View Order</a>
        </div>
      `;
    }

    try {
      await transporter.sendMail({
        from: `"WellNexus Health" <${process.env.EMAIL_USER}>`,
        to,
        subject,
        html
      });
      
      console.log(`✅ ${type} notification sent`);
    } catch (error) {
      console.error('❌ Failed to send order notification:', error);
    }
  }

  /**
   * Store notification in database for in-app display
   */
  async storeNotification(data) {
    try {
      await pool.query(
        `INSERT INTO notifications (user_id, title, message, type, data, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())`,
        [data.userId, data.title, data.message, data.type, JSON.stringify(data)]
      );
    } catch (error) {
      console.error('Error storing notification:', error);
    }
  }

  /**
   * Get user's notifications
   */
  async getUserNotifications(userId, limit = 20) {
    const result = await pool.query(
      `SELECT * FROM notifications 
       WHERE user_id = $1 
       ORDER BY created_at DESC 
       LIMIT $2`,
      [userId, limit]
    );
    return result.rows;
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId) {
    await pool.query(
      `UPDATE notifications SET is_read = true WHERE notification_id = $1`,
      [notificationId]
    );
  }
}

module.exports = new NotificationService();