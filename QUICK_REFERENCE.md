# WellNexus Developer Quick Reference

## 🚀 Quick Start

### Backend
```bash
cd backend
npm install
npm install nodemon -D
export DATABASE_URL="postgres://user:pass@localhost:5432/wellnexus"
export JWT_SECRET="your-secret-key"
npx nodemon server.js
# Server runs on http://localhost:5000
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
# Or for web: flutter run -d chrome
```

## 📡 API Response Format (STANDARDIZED)

All endpoints should now return:

```json
{
  "success": true|false,
  "message": "Human-readable message",
  "data": null|object|array
}
```

**Example Success**:
```json
{
  "success": true,
  "message": "User fetched successfully",
  "data": {
    "user_id": 1,
    "email": "test@example.com",
    "role": "patient"
  }
}
```

**Example Error**:
```json
{
  "success": false,
  "message": "User not found"
}
```

## 🔑 Key Fixed Files

| File | Changes | Status |
|------|---------|--------|
| `frontend/lib/main.dart` | Fixed routing logic | ✅ |
| `frontend/lib/screens/pharmacy_register_screen.dart` | Added state variables & methods | ✅ |
| `frontend/lib/services/auth_service.dart` | Improved URL documentation | ✅ |
| `backend/routes/patientRoutes.js` | Fixed route ordering | ✅ |
| `backend/controllers/doctorController.js` | Added role validation | ✅ |
| `backend/routes/appointmentRoutes.js` | Added doctor_id param | ✅ |
| `backend/utils/apiResponse.js` | NEW - Response standardization | ✅ |

## 🔐 Platform-Specific URLs

### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api/auth';
```

### iOS Simulator
```dart
static const String baseUrl = 'http://localhost:5000/api/auth';
```

### Physical Device
```dart
// Replace 192.168.1.100 with your computer's IP
static const String baseUrl = 'http://192.168.1.100:5000/api/auth';
```

## 🛡️ Security Reminders

⚠️ **NOT YET FIXED**:
- JWT stored in SharedPreferences (plain text) - use `flutter_secure_storage`
- Password reset token not generated
- No input sanitization

## 📚 Useful Endpoints

### Auth
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/register` - Register new user
- `POST /api/auth/verify-email` - Verify OTP
- `POST /api/auth/forgot-password` - Reset password

### Patients
- `GET /api/patients/dashboard/:userId` - Get patient dashboard
- `POST /api/patients/details` - Save patient details
- `GET /api/patients/:userId/check` - Check if has details

### Doctors
- `POST /api/doctors/register` - Register doctor (requires user_id or email/password)
- `GET /api/doctors/:doctorId` - Get doctor details
- `GET /api/doctors/specialization/:spec` - Get doctors by specialty

### Pharmacies
- `POST /api/pharmacies/register` - Register pharmacy (with branches array)
- `GET /api/pharmacies/:pharmacyId` - Get pharmacy details
- `GET /api/pharmacies/:pharmacyId/branches` - Get all branches

### Appointments
- `POST /api/appointments` - Create appointment
- `GET /api/appointments/doctor/:doctorId` - Get doctor appointments
- `PUT /api/appointments/:id/status` - Update appointment status

## 🐛 Common Issues & Solutions

### "Cannot connect to server"
- Ensure backend is running: `npx nodemon server.js`
- Check port is 5000: `lsof -i :5000`
- Use correct platform URL (see above)

### "CORS policy error"
- Backend CORS is configured for localhost
- For physical device, add IP to `allowedOrigins` in server.js

### "Email not verified"
- Check OTP was sent to email
- Verify email in database: `SELECT * FROM users WHERE email = 'test@example.com';`

### "Route not found"
- Check route ordering in router files
- Specific routes MUST come before generic routes
- Example: `/dashboard/:id` before `/:id`

## 🔧 Response Utility Usage

```javascript
// In controllers
const ApiResponse = require('../utils/apiResponse');

// Success response
const { statusCode, response } = ApiResponse.success(doctorData, 'Doctor fetched');
res.status(statusCode).json(response);

// Error response
const { statusCode, response } = ApiResponse.error('Doctor not found', 404);
res.status(statusCode).json(response);

// Paginated response
const { statusCode, response } = ApiResponse.paginated(
  doctors, 
  totalCount, 
  currentPage, 
  pageSize, 
  'Doctors fetched'
);
res.status(statusCode).json(response);
```

## 📊 Testing Checklist

- [ ] Patient can register and complete profile
- [ ] Doctor can register with specialization
- [ ] Pharmacist can register with branches
- [ ] Login works for all roles
- [ ] Password reset flow works
- [ ] Role-based routing works
- [ ] API returns standardized responses
- [ ] Appointment creation works
- [ ] No console errors on navigation

## 📞 Support

For detailed information on fixes applied, see `FIX_SUMMARY.md`
For session notes on work in progress, see `/memories/session/fixes_applied.md`
