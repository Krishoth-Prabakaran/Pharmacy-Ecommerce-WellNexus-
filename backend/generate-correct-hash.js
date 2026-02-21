const bcrypt = require('bcrypt');

async function generateCorrectHash() {
    const password = 'password123';
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(password, salt);
    
    console.log('=================================');
    console.log('PASSWORD:', password);
    console.log('NEW HASH:', hash);
    console.log('=================================');
    console.log('\nRun this SQL in Supabase:');
    console.log('---------------------------------');
    console.log(`UPDATE users SET password_hash = '${hash}' WHERE email = 'rajesh@example.com';`);
    console.log(`UPDATE users SET password_hash = '${hash}' WHERE email = 'priya@example.com';`);
    console.log(`UPDATE users SET password_hash = '${hash}' WHERE email = 'amit@example.com';`);
    console.log('---------------------------------');
    
    // Verify the hash works
    const verify = await bcrypt.compare(password, hash);
    console.log('\nVerification test:', verify ? '✅ CORRECT' : '❌ FAILED');
}

generateCorrectHash();