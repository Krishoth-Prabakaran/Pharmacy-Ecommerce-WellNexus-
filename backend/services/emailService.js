// backend/services/emailService.js
const nodemailer = require('nodemailer');

const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT) || 587,
    secure: process.env.EMAIL_SECURE === 'true',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

const transporter = createTransporter();

/**
 * Send OTP verification email
 */
exports.sendVerificationEmail = async (to, otp, username) => {
  console.log(`📧 Sending OTP ${otp} to: ${to}`);

  const mailOptions = {
    from: '"WellNexus Health" <wellnexus10@gmail.com>',
    to: to,
    subject: `${otp} is your WellNexus verification code`,
    html: `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <div style="text-align: center; margin-bottom: 20px;">
          <h1 style="color: #2196F3; margin: 0;">WellNexus</h1>
          <p style="color: #666; font-size: 14px;">Your Health Companion</p>
        </div>
        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center;">
          <h2 style="color: #333; margin-top: 0;">Verify Your Email</h2>
          <p style="color: #555;">Hello ${username}, use the code below to verify your account:</p>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #2196F3; margin: 20px 0; padding: 10px; background: #fff; border: 1px dashed #2196F3; display: inline-block;">
            ${otp}
          </div>
          <p style="color: #888; font-size: 12px;">This code will expire in 24 hours.</p>
        </div>
        <p style="color: #666; font-size: 13px; margin-top: 20px;">
          If you didn\'t request this, please ignore this email.
        </p>
      </div>
    `,
    text: `Your WellNexus verification code is: ${otp}`
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`✅ Email sent successfully! Message ID: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('❌ Email error:', error);
    console.error('Error details:', error.message);
    return { success: false, error: error.message };
  }
};

exports.sendWelcomeEmail = async (to, username) => {
  const mailOptions = {
    from: '"WellNexus" <wellnexus10@gmail.com>',
    to: to,
    subject: 'Welcome to WellNexus! 🎉',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
        <h2>Welcome, ${username}!</h2>
        <p>Your email has been verified successfully.</p>
        <p>You can now log in to your account and start using WellNexus.</p>
        <br>
        <p>Best regards,<br>WellNexus Team</p>
      </div>
    `
  };
  try {
    await transporter.sendMail(mailOptions);
    console.log(`✅ Welcome email sent to: ${to}`);
    return { success: true };
  } catch (error) {
    console.error('❌ Welcome email error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Test email configuration
 * @returns {Promise<Object>} - Test result
 */
exports.testEmailConfig = async () => {
  try {
    await transporter.verify();
    console.log('✅ Email transporter is configured correctly');
    return { success: true, message: 'Email configuration is valid' };
  } catch (error) {
    console.error('❌ Email transporter verification failed:', error);
    return { success: false, message: 'Email configuration is invalid', error: error.message };
  }
};