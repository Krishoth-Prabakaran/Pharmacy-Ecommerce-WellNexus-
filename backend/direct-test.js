const bcrypt = require('bcrypt');

// The hash from your database for Rajesh
const storedHash = '$2b$10$3euPcmQFCiblsZeEu5s7p.9MUHjP2Kp5r5QsT4vB.g5QsU8UqYyby';

// The password you're trying to login with
const testPassword = 'password123';

async function testBcrypt() {
    console.log('Testing password match...');
    console.log('Stored hash:', storedHash);
    console.log('Test password:', testPassword);
    
    try {
        const isValid = await bcrypt.compare(testPassword, storedHash);
        console.log('Password match result:', isValid);
        
        // Let's also generate a fresh hash of the same password to compare
        const salt = await bcrypt.genSalt(10);
        const freshHash = await bcrypt.hash(testPassword, salt);
        console.log('\nFresh hash of same password:', freshHash);
        console.log('Note: Different salts produce different hashes, but they all should verify correctly');
        
    } catch (err) {
        console.error('Error:', err);
    }
}

testBcrypt();