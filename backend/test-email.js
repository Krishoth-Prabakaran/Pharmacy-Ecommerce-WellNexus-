require('dotenv').config();
const emailService = require('./services/emailService');

async function testEmail() {
  console.log('=================================');
  console.log('Testing Email Configuration');
  console.log('=================================');
  console.log('EMAIL_USER:', process.env.EMAIL_USER);
  console.log('EMAIL_HOST:', process.env.EMAIL_HOST);
  console.log('EMAIL_PORT:', process.env.EMAIL_PORT);
  console.log('EMAIL_PASS:', process.env.EMAIL_PASS ? '✓ Set' : '✗ Not set');
  console.log('=================================\n');
  
  console.log('1. Testing transporter configuration...');
  const configResult = await emailService.testEmailConfig();
  console.log('   Result:', configResult.success ? '✅ OK' : '❌ FAILED');
  if (!configResult.success) {
    console.log('   Error:', configResult.error);
    console.log('\n💡 SOLUTION:');
    console.log('   1. Go to https://myaccount.google.com/apppasswords');
    console.log('   2. Generate an App Password for "Mail"');
    console.log('   3. Copy the 16-character password');
    console.log('   4. Update EMAIL_PASS in .env file');
    return;
  }
  
  console.log('\n2. Sending test email...');
  const sendResult = await emailService.sendVerificationEmail(
    process.env.EMAIL_USER,
    '123456',
    'TestUser'
  );
  
  if (sendResult.success) {
    console.log('   ✅ Test email sent successfully!');
    console.log('   Message ID:', sendResult.messageId);
    console.log('   Check your inbox at:', process.env.EMAIL_USER);
  } else {
    console.log('   ❌ Failed to send test email');
    console.log('   Error:', sendResult.error);
  }
}

testEmail();