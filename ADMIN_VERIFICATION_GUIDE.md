# Admin Verification System - Complete Guide

## Overview
The WellNexus admin panel includes a complete professional verification system for doctors and pharmacies. Admins can verify or reject registrations with optional notes.

## Backend Implementation ✅

### API Endpoints

#### Verify Doctor
```
PUT /api/admin/doctors/:doctorId/verify
Authorization: Bearer <admin_token>
Content-Type: application/json

Body:
{
  "isVerified": true,
  "notes": "License verified against state database" // Optional
}

Response:
{
  "success": true,
  "doctor": {
    "doctor_id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "is_verified": true,
    "verified_at": "2026-04-27T12:34:56Z",
    "verified_by": 5,  // Admin user_id
    "verification_notes": "License verified..."
  }
}
```

#### Verify Pharmacy
```
PUT /api/admin/pharmacies/:pharmacyId/verify
Authorization: Bearer <admin_token>
Content-Type: application/json

Body:
{
  "isVerified": true,
  "notes": "Location verified and licenses on file" // Optional
}

Response:
{
  "success": true,
  "pharmacy": {
    "pharmacy_id": 1,
    "pharmacy_name": "HealthCare Plus",
    "is_verified": true,
    "verified_at": "2026-04-27T12:34:56Z",
    "verified_by": 5,
    "verification_notes": "Location verified..."
  }
}
```

### Database Schema

#### Doctors Table Verification Fields
```sql
CREATE TABLE doctors (
  -- ... other fields ...
  is_verified boolean DEFAULT false,
  verified_at timestamp with time zone,
  verified_by integer REFERENCES users(user_id),
  verification_notes text,
  -- ... other fields ...
);
```

#### Pharmacies Table Verification Fields
```sql
CREATE TABLE pharmacies (
  -- ... other fields ...
  is_verified boolean DEFAULT false,
  verified_at timestamp with time zone,
  verified_by integer REFERENCES users(user_id),
  verification_notes text,
  -- ... other fields ...
);
```

### Backend Files
- **Routes**: `/backend/routes/adminRoutes.js`
  - Lines: Verification routes defined with admin auth middleware
  
- **Controller**: `/backend/controllers/adminController.js`
  - `verifyDoctor()` - Handles doctor verification requests
  - `verifyPharmacy()` - Handles pharmacy verification requests
  
- **Model**: `/backend/models/adminModel.js`
  - `verifyDoctor()` - SQL: Updates `is_verified`, `verified_at`, `verified_by`, `verification_notes`
  - `verifyPharmacy()` - SQL: Updates pharmacy verification fields

## Frontend Implementation ✅

### Admin Dashboard Views

#### Doctor Management View
File: `/frontend/lib/screens/admin_dashboard_screen.dart` (Lines 1279-1523)

Features:
- ✅ List all doctors with pagination
- ✅ Search doctors by name, specialization, phone
- ✅ Show verification status (badge: green=verified, orange=unverified)
- ✅ Verify/Unverify buttons
- ✅ Optional verification notes dialog

```dart
// Usage Example
_showVerificationDialog(doctorId, isVerified: true);
// Opens dialog where admin can:
// 1. Confirm verification action
// 2. Add optional notes
// 3. Submit to backend
```

#### Pharmacy Management View
File: `/frontend/lib/screens/admin_dashboard_screen.dart` (Lines 1524-1850)

Features:
- ✅ List all pharmacies with complete details
- ✅ Search by name, address, phone
- ✅ Show verification status with colored indicators
- ✅ Display stored verification notes
- ✅ Verify/Unverify with notes
- ✅ Full pagination support

### Admin Service
File: `/frontend/lib/services/admin_service.dart`

```dart
// Verify Doctor
Future<Map<String, dynamic>> verifyDoctor(
  int doctorId,
  bool isVerified, {
  String? notes,
}) async {
  // Makes PUT request to /api/admin/doctors/:doctorId/verify
  // Includes JWT token in Authorization header
}

// Verify Pharmacy
Future<Map<String, dynamic>> verifyPharmacy(
  int pharmacyId,
  bool isVerified, {
  String? notes,
}) async {
  // Makes PUT request to /api/admin/pharmacies/:pharmacyId/verify
  // Includes JWT token in Authorization header
}
```

## How to Use - Admin Step-by-Step

### 1. Login as Admin
- Navigate to login page
- Enter admin credentials (role must be 'admin')
- JWT token automatically stored in `shared_preferences`

### 2. Access Admin Dashboard
- Route: Navigate to `/admin` or tap "Admin Dashboard"
- Select "Doctors" or "Pharmacies" from left sidebar

### 3. Review Pending Verifications

#### For Doctors:
1. Look for doctors with orange "Unverified" badge
2. Review doctor details:
   - Name: Dr. [First] [Last]
   - Specialization (e.g., Cardiology)
   - License number
   - Education background
   - Clinic address
   - Experience years

#### For Pharmacies:
1. Look for pharmacies with orange "Unverified" badge
2. Review pharmacy details:
   - Pharmacy name
   - Location/Address
   - Phone number
   - Email
   - Branch information

### 4. Verify or Reject

Click the **"Verify"** button (green) or **"Unverify"** button (red):

1. Dialog appears asking for confirmation
2. Optionally enter verification notes, e.g.:
   ```
   "Doctor's license verified with Medical Board registry.
    No complaints on file. Approved for patient consultations."
   ```
3. Click "Verify" or "Unverify" to submit
4. Success message appears
5. List refreshes automatically
6. Professional now has verified badge (green)

## Data Flow

```
Admin User
    ↓
[Verify Button Clicked]
    ↓
Front-end Dialog
(Confirmation + Optional Notes)
    ↓
AdminService.verifyDoctor/verifyPharmacy()
    ↓
HTTP PUT Request
/api/admin/doctors/:id/verify
OR
/api/admin/pharmacies/:id/verify
(JWT Token in Authorization header)
    ↓
Backend Routes (adminRoutes.js)
    ↓
Admin Controller
    ↓
Admin Model
    ↓
Database Update
(Set is_verified, verified_at, verified_by, verification_notes)
    ↓
Response with updated record
    ↓
Frontend: Show success message
    ↓
Frontend: Reload list (automatic refresh)
    ↓
Updated list shown to admin
```

## Verification States

### Unverified
- Badge: Orange "Unverified"
- Icon: pending_icon
- Button: Green "Verify"
- Database: `is_verified = false`, `verified_at = NULL`

### Verified
- Badge: Green "Verified"
- Icon: verified_icon
- Button: Red "Unverify"
- Database: `is_verified = true`, `verified_at = [timestamp]`, `verified_by = [admin_id]`

### With Notes
- Notes displayed under doctor/pharmacy card
- Notes only shown if set during verification
- Can be updated by re-verifying/un-verifying

## Testing the Feature

### Prerequisites
1. ✅ Backend running on http://localhost:5000
2. ✅ Database connected with SSL properly configured
3. ✅ Admin user account exists
4. ✅ Doctor(s) and Pharmacy(ies) to verify exist in database

### Test Steps

#### 1. Test Backend Endpoint (curl)
```bash
# Get admin token
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'

# Response: { "token": "eyJhbGc...", "role": "admin", ... }

# Verify a doctor
curl -X PUT http://localhost:5000/api/admin/doctors/1/verify \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{"isVerified":true,"notes":"License verified"}'

# Response: { "success": true, "doctor": {...} }
```

#### 2. Test Frontend UI
1. Start Flutter app: `flutter run`
2. Login with admin account
3. Navigate to Admin Dashboard → Doctors
4. Click "Verify" button on any unverified doctor
5. Enter optional notes in dialog
6. Click "Verify"
7. Should see success message
8. List should refresh and show green verified badge

## Troubleshooting

### Issue: "Access denied. Admin privileges required"
- **Cause**: User doesn't have admin role
- **Fix**: Ensure user record has `role = 'admin'` in users table

### Issue: "Failed to verify doctor" error
- **Cause**: Database connection or query error
- **Fix**: 
  1. Check DATABASE_URL in .env
  2. Verify NODE_TLS_REJECT_UNAUTHORIZED=0 is set
  3. Check backend logs for detailed error

### Issue: Verification button doesn't appear
- **Cause**: Frontend not rendering doctor/pharmacy management view
- **Fix**:
  1. Check if using correct admin account
  2. Check if AdminService is properly initialized
  3. Verify JWT token is valid and not expired

### Issue: Verified status doesn't persist
- **Cause**: Frontend not refreshing or backend didn't save
- **Fix**:
  1. Check HTTP response status (should be 200)
  2. Check database directly: `SELECT is_verified FROM doctors WHERE doctor_id = 1;`
  3. Manually refresh: Click refresh button in top-right

## Security Considerations

1. **Authentication**: All verification endpoints require valid JWT token
2. **Authorization**: Only users with `role = 'admin'` can verify
3. **Audit Trail**: `verified_by` field tracks which admin performed verification
4. **Timestamps**: `verified_at` records when verification occurred
5. **Notes**: Optional notes provide audit trail for approval decision

## Related Features

- **User Management**: Deactivate/activate users
- **Reset Password**: Admin can reset user passwords
- **Delete Users**: Admin can delete user accounts
- **Disputes**: Handle complaints/disputes from users
- **Analytics**: View professional statistics and activity

## Notes for Developers

- Verification endpoint returns full updated record on success
- Frontend handles both `name`/`pharmacy_name` field variations
- Pharmacy response includes branch information
- Doctor response includes specialization and education
- All timestamps are in ISO 8601 format (UTC)
- Optional notes parameter can be null or empty string
- Maximum 20 records per page (configurable via limit param)
