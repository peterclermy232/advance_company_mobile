# Backend Integration Guide

Complete alignment of the Advance Company Flutter mobile app with the Django REST Framework backend API.

## Documentation Based On

**Backend Repository:** Advance Company Management System
**Backend Stack:** Django, DRF, PostgreSQL, JWT Auth, Supabase Storage, Redis Cache
**Frontend:** Flutter mobile app with Riverpod state management

## Architecture Overview

### API Layer Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── api_endpoints.dart    # All backend endpoint definitions
│   ├── network/
│   │   ├── api_client.dart       # HTTP client with auth interceptor
│   │   └── interceptors.dart     # Token refresh, error handling
│   └── storage/
│       └── secure_storage.dart   # Token storage
├── data/
│   ├── services/                 # Domain-specific API services
│   │   ├── auth_service.dart
│   │   ├── financial_service.dart
│   │   ├── beneficiary_service.dart
│   │   ├── document_service.dart
│   │   ├── application_service.dart
│   │   ├── notification_service.dart
│   │   ├── report_service.dart
│   │   ├── admin_service.dart
│   │   ├── health_service.dart
│   │   └── README.md
│   ├── models/                   # DRF response models
│   └── providers/
│       ├── core_providers.dart   # Service instances
│       └── ...repository providers
└── config/
    └── api_config.dart           # Base URLs, timeouts
```

### Data Flow

```
UI Layer (Widgets)
    ↓
Riverpod Providers (StateNotifiers)
    ↓
Repositories (optional, data transformation)
    ↓
API Services (business logic, endpoint calls)
    ↓
ApiClient (HTTP client)
    ↓
Interceptors (token attach, refresh, error handling)
    ↓
Django REST Backend (/api/...)
```

## Backend Endpoints Reference

### Base URL

```
Production: https://advance-company-backend-v1-0-3.onrender.com/api
Development: http://10.0.2.2:8000/api (Android Emulator)
```

All paths below are relative to `/api`.

### 1. Authentication (`/auth/`)

**Public Endpoints:**
- `POST /auth/login/` - Login with email/password
- `POST /auth/register/` - User registration
- `POST /auth/verify-email/` - Email verification
- `POST /auth/resend-verification/` - Resend verification email
- `POST /auth/verify-2fa/` - 2FA verification
- `POST /auth/forgot-password/` - Initiate password reset
- `POST /auth/reset-password-confirm/` - Confirm password reset
- `POST /token/refresh/` - Refresh JWT access token

**Protected Endpoints:**
- `GET /auth/users/` - List all users (admin)
- `GET /auth/users/{uuid}/` - Get user by UUID
- `PATCH /auth/users/{uuid}/` - Update user profile
- `DELETE /auth/users/{uuid}/` - Delete user account
- `POST /auth/users/change_password/` - Change password
- `POST /auth/users/enable_2fa/` - Enable 2FA
- `POST /auth/users/confirm_2fa/` - Confirm 2FA setup
- `POST /auth/users/disable_2fa/` - Disable 2FA
- `POST /auth/users/regenerate_backup_codes/` - Get new backup codes
- `POST /auth/users/register_biometric/` - Register biometric device
- `GET /auth/users/biometric_devices/` - List biometric devices
- `DELETE /auth/users/{uuid}/biometric-devices/{device_id}/` - Delete device
- `DELETE /auth/users/delete_account/` - Delete account
- `POST /auth/users/upload_profile_photo/` - Upload profile photo
- `DELETE /auth/users/delete_profile_photo/` - Delete profile photo

**Service:** `AuthService`

```dart
final authService = ref.watch(authServiceProvider);

// Login
final response = await authService.login(
  email: 'user@example.com',
  password: 'StrongPassword123!',
);

// Register
await authService.register(
  email: 'newuser@example.com',
  phoneNumber: '0712345678',
  fullName: 'Jane Doe',
  password: 'StrongPassword123!',
  passwordConfirm: 'StrongPassword123!',
);

// Get current user (requires auth)
final user = await authService.getCurrentUser();
```

### 2. Financial (`/financial/`)

**Accounts:**
- `GET /financial/accounts/` - List all accounts
- `GET /financial/accounts/{uuid}/` - Get account by UUID
- `GET /financial/accounts/my_account/` - Get current user's account

**Deposits (Monthly Fixed: KES 20,000):**
- `GET /financial/deposits/` - List deposits (paginated)
- `POST /financial/deposits/` - Create deposit
- `GET /financial/deposits/{uuid}/` - Get deposit by UUID
- `GET /financial/deposits/can_deposit/` - Check if can deposit
- `GET /financial/deposits/monthly_summary/` - Monthly summary
- `GET /financial/deposits/pending_approvals/` - Pending deposits (admin)
- `POST /financial/deposits/{uuid}/approve_deposit/` - Approve (admin)
- `POST /financial/deposits/{uuid}/reject_deposit/` - Reject (admin)

**Interest:**
- `GET /financial/interest/` - List interest records
- `GET /financial/interest/{uuid}/` - Get interest by UUID

**M-Pesa Callback:**
- `POST /financial/mpesa/callback/` - M-Pesa callback handler (public)

**Service:** `FinancialService`

```dart
final financialService = ref.watch(financialServiceProvider);

// Create deposit (KES 20,000 fixed, monthly limit applies)
final deposit = await financialService.createDeposit(
  paymentMethod: 'mpesa', // mpesa, bank, mansa_x
  mpesaPhone: '254712345678',
  notes: 'Monthly contribution',
);

// Check if can deposit this month
final canDep = await financialService.canDeposit();

// Get monthly summary
final summary = await financialService.getMonthlySummary();

// Admin: approve deposit
await financialService.approveDeposit(deposit.uuid);
```

### 3. Beneficiaries (`/beneficiary/`)

**CRUD:**
- `GET /beneficiary/` - List beneficiaries (paginated)
- `POST /beneficiary/` - Create beneficiary
- `GET /beneficiary/{uuid}/` - Get beneficiary
- `PATCH /beneficiary/{uuid}/` - Update beneficiary
- `DELETE /beneficiary/{uuid}/` - Delete beneficiary

**Verification:**
- `POST /beneficiary/{uuid}/verify/` - Verify (admin)
- `POST /beneficiary/{uuid}/reject/` - Reject (admin)
- `POST /beneficiary/{uuid}/mark_deceased/` - Mark deceased
- `GET /beneficiary/pending_verification/` - Pending (admin)

**Statistics:**
- `GET /beneficiary/statistics/` - Beneficiary stats

**Supported Relations:** spouse, child, parent, sibling, other
**Verification Statuses:** verified, pending, rejected
**Beneficiary Statuses:** active, deceased, removed

**Service:** `BeneficiaryService`

```dart
final beneficiaryService = ref.watch(beneficiaryServiceProvider);

// Create beneficiary with documents
final benef = await beneficiaryService.createBeneficiary(
  name: 'John Doe',
  relation: 'spouse',
  age: 35,
  gender: 'M',
  phoneNumber: '0712345678',
  profession: 'Engineer',
  salaryRange: '200000-300000',
  percentageAllocation: 50.0,
  identityDocumentPath: '/path/to/id.pdf',
  birthCertificatePath: '/path/to/birth.pdf',
);

// Get all (paginated)
final list = await beneficiaryService.getBeneficiaries(page: 1);

// Admin: verify
await beneficiaryService.verifyBeneficiary(benef.uuid);

// Mark deceased
await beneficiaryService.markDeceased(
  benef.uuid,
  deathCertificatePath: '/path/to/death_cert.pdf',
  deathCertificateNumber: 'DC123456',
);
```

### 4. Documents (`/documents/`)

**CRUD:**
- `GET /documents/` - List documents (paginated)
- `POST /documents/` - Upload document
- `GET /documents/{uuid}/` - Get document
- `PATCH /documents/{uuid}/` - Update document
- `DELETE /documents/{uuid}/` - Delete document
- `GET /documents/{uuid}/view_url/` - Get view/download URL

**Verification (Admin):**
- `POST /documents/{uuid}/verify/` - Verify
- `POST /documents/{uuid}/reject/` - Reject

**Categories:** identity, beneficiary, birth_certificate, death_certificate, additional
**Statuses:** pending, verified, rejected
**Max Size:** 10MB

**Service:** `DocumentService`

```dart
final documentService = ref.watch(documentServiceProvider);

// Upload document
final doc = await documentService.uploadDocument(
  category: 'identity',
  title: 'National ID',
  filePath: '/path/to/id.pdf',
);

// Get view URL
final url = await documentService.getDocumentViewUrl(doc.uuid);

// Admin: verify
await documentService.verifyDocument(doc.uuid);
```

### 5. Applications (`/applications/`)

**CRUD:**
- `GET /applications/` - List applications (paginated)
- `POST /applications/` - Create application
- `GET /applications/{id}/` - Get application
- `PATCH /applications/{id}/` - Update application
- `DELETE /applications/{id}/` - Delete application

**Admin Actions:**
- `POST /applications/{id}/approve/` - Approve
- `POST /applications/{id}/reject/` - Reject with comments
- `POST /applications/{id}/review/` - Move to under_review

**Choices:**
- `GET /applications/choices/` - Available application types

**Types:** new_membership, membership_withdrawal, membership_transfer, loan, loan_top_up, loan_restructure, withdrawal, contribution_change, beneficiary_update, personal_details_change, next_of_kin_update, statement_request, other

**Statuses:** pending, under_review, approved, rejected

**Service:** `ApplicationService`

```dart
final appService = ref.watch(applicationServiceProvider);

// Submit application
final app = await appService.createApplication(
  applicationType: 'loan',
  reason: 'Business capital needed',
  supportingDocumentPath: '/path/to/business_plan.pdf',
);

// Admin: approve
await appService.approveApplication(app.id, adminComments: 'Approved');

// Admin: reject
await appService.rejectApplication(
  app.id,
  adminComments: 'Need more info',
);
```

### 6. Notifications (`/notifications/`)

- `GET /notifications/` - List all (paginated)
- `GET /notifications/{uuid}/` - Get notification
- `GET /notifications/unread/` - Unread only (paginated)
- `GET /notifications/unread_count/` - Count unread
- `GET /notifications/recent/` - Recent notifications
- `POST /notifications/{uuid}/mark_as_read/` - Mark read
- `POST /notifications/mark_all_as_read/` - Mark all read
- `DELETE /notifications/{uuid}/delete_notification/` - Delete one
- `DELETE /notifications/clear_all/` - Delete all

**Service:** `NotificationService`

```dart
final notificationService = ref.watch(notificationServiceProvider);

// Get unread count
final count = await notificationService.getUnreadCount();

// Get recent
final recent = await notificationService.getRecentNotifications(limit: 10);

// Mark all as read
await notificationService.markAllAsRead();
```

### 7. Reports (`/reports/`)

- `GET /reports/` - List reports (paginated)
- `GET /reports/{uuid}/` - Get report
- `POST /reports/generate_financial_report/` - Generate
- `POST /reports/generate_compensatory_report/` - Generate
- `POST /reports/generate_activity_report/` - Generate
- `POST /reports/{uuid}/resend_report_email/` - Email report
- `GET /reports/dashboard_summary/` - Dashboard data
- `GET /reports/summary/` - Report summary
- `GET /reports/deposit_trends/` - Trend data
- `GET /reports/activity-logs/` - Activity history (paginated)

**Service:** `ReportService`

```dart
final reportService = ref.watch(reportServiceProvider);

// Get dashboard
final dashboard = await reportService.getDashboardSummary();

// Generate report
final report = await reportService.generateFinancialReport(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
);

// Get trends
final trends = await reportService.getDepositTrends();
```

### 8. Admin Analytics (`/admin/analytics/`)

- `GET /admin/analytics/members/` - Member analytics (paginated)
- `GET /admin/analytics/summary/` - Summary stats
- `GET /admin/analytics/export/` - Export data (excel/pdf)

**Requirements:** Admin role

**Service:** `AdminService`

```dart
final adminService = ref.watch(adminServiceProvider);

// Get analytics
final analytics = await adminService.getAnalyticsSummary();

// Export
final export = await adminService.exportAnalytics(format: 'excel');
```

### 9. Health (`/health/`)

- `GET /health/` - Health check
- `GET /health/metrics/` - System metrics

**Service:** `HealthService`

```dart
final healthService = ref.watch(healthServiceProvider);

// Health check
final health = await healthService.health();
```

## Authentication & Token Management

### JWT Bearer Tokens

Storage in `SecureStorage`:
```dart
final storage = ref.watch(secureStorageProvider);

String? accessToken = await storage.getAccessToken();
String? refreshToken = await storage.getRefreshToken();
```

### Token Refresh

Automatically handled by `AuthInterceptor`:
```dart
// When 401 response received, interceptor:
// 1. Uses refresh token to get new access token
// 2. Retries original request
// 3. If refresh fails, redirects to login
```

Manual refresh:
```dart
final authService = ref.watch(authServiceProvider);
final newAccessToken = await authService.refreshToken(
  refreshToken: currentRefreshToken,
);
```

### Access Levels

**Public endpoints** (no token needed):
- Login, register, verify email, forgot password, health, metrics

**Protected endpoints** (token required):
- /auth/users/*, /financial/*, /beneficiary/*, /documents/*, /applications/*, /notifications/*, /reports/*

**Admin only:**
- /financial/deposits/pending_approvals/
- /financial/deposits/{uuid}/approve_deposit/
- /financial/deposits/{uuid}/reject_deposit/
- /beneficiary/{uuid}/verify/, /reject/
- /beneficiary/pending_verification/
- /documents/{uuid}/verify/, /reject/
- /applications/{id}/approve/, /reject/
- /admin/analytics/*

Check role in app:
```dart
final user = await authService.getCurrentUser();
if (user.role == 'admin') {
  // Show admin features
}
```

## File Uploads

All file uploads use `FormData` (multipart/form-data):

```dart
final formData = FormData.fromMap({
  'category': 'identity',
  'title': 'National ID',
  'file': await MultipartFile.fromFile(filePath),
});

final response = await documentService.uploadDocument(...);
```

**Important:**
- Do NOT manually set `Content-Type: multipart/form-data`
- Do NOT manually add `Authorization` header
- Both are handled by interceptors
- Max file size: 10MB
- Allowed types: PDF, JPG, JPEG, PNG

## Error Handling

Errors are normalized to `DioException` with friendly messages:

```dart
try {
  await authService.login(email, password);
} on DioException catch (e) {
  // e.message contains user-friendly error
  // e.response?.statusCode for HTTP status
  // e.response?.data for backend response body
  
  if (e.response?.statusCode == 401) {
    // Session expired
  } else if (e.response?.statusCode == 422) {
    // Validation error - check e.response?.data['errors']
  } else if (e.response?.statusCode == 500) {
    // Server error
  } else {
    // Connection error etc
  }
}
```

## Pagination

Most endpoints support pagination:

```dart
final response = await financialService.getDeposits(
  page: 1,
  pageSize: 20,
);

// Response structure:
final count = response['count'];
final next = response['next']; // null if last page
final previous = response['previous'];
final results = response['results']; // List of items
```

## Response Patterns

**Pattern 1: Wrapped response (Auth, some CRUD)**
```json
{
  "success": true,
  "message": "Operation successful",
  "toast_type": "success",
  "data": { "uuid": "...", ... }
}
```

**Pattern 2: Raw DRF response (most viewsets)**
```json
{
  "uuid": "...",
  "email": "...",
  "created_at": "..."
}
```

**Pattern 3: Paginated response (list endpoints)**
```json
{
  "count": 100,
  "next": "https://...",
  "previous": "https://...",
  "results": [...]
}
```

Services normalize these automatically.

## Development Setup

### 1. Local Backend

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

### 2. Update API Config

Edit `lib/config/api_config.dart`:

```dart
static const bool _isProduction = false;

// For Android Emulator:
static const String devBaseUrl = 'http://10.0.2.2:8000/api';

// For iOS Simulator:
static const String devBaseUrl = 'http://127.0.0.1:8000/api';

// For physical device (replace with your PC IP):
static const String devBaseUrl = 'http://192.168.1.100:8000/api';
```

### 3. Configure CORS

Backend `settings.py`:
```python
CORS_ALLOWED_ORIGINS = [
    'http://localhost:4200',
    'http://10.0.2.2:8000',
    'http://127.0.0.1:8000',
    'http://192.168.1.100:8000',
]
```

### 4. Run Flutter App

```bash
flutter pub get
flutter run
```

## Integration Checklist

- [ ] Verify `/api` base URL configuration
- [ ] Test JWT token storage and retrieval
- [ ] Test token refresh on 401 responses
- [ ] Test login/register flows
- [ ] Test file uploads (documents, beneficiary docs)
- [ ] Test list endpoints with pagination
- [ ] Test admin features (verify, reject, approve)
- [ ] Test notifications polling or WebSocket
- [ ] Test error handling and user-friendly messages
- [ ] Test CORS in development mode
- [ ] Verify secure storage encryption
- [ ] Test offline fallback or connectivity aware UI
- [ ] Test role-based route protection (admin routes)
- [ ] Test deep links and app navigation
- [ ] Performance test with slow/high-latency connections

## Common Issues & Solutions

### Cannot connect to backend

**Android Emulator:**
```dart
// Use 10.0.2.2 instead of localhost or 127.0.0.1
devBaseUrl = 'http://10.0.2.2:8000/api';
```

**iOS Simulator:**
```dart
// Use 127.0.0.1
devBaseUrl = 'http://127.0.0.1:8000/api';
```

**Physical Device:**
```dart
// Use your PC's LAN IP (check with `ipconfig` or `ifconfig`)
devBaseUrl = 'http://192.168.1.100:8000/api';
// Also allow in Android: android:usesCleartextTraffic="true"
```

### CORS errors

Ensure Django `CORS_ALLOWED_ORIGINS` includes Flutter app origin:
```python
CORS_ALLOWED_ORIGINS = [
    'http://10.0.2.2:8000',  # Android Emulator
    'http://127.0.0.1:8000', # iOS Simulator
]
```

### 401 Unauthorized but token present

Check token expiry:
```dart
final storage = ref.watch(secureStorageProvider);
final token = await storage.getAccessToken();
// Token valid? (30 minute lifetime)
// Is refresh token still valid? (7 day lifetime)
```

### File upload failing

```dart
// Always use FormData
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(path),
});

// NOT this:
// headers: {'Content-Type': 'multipart/form-data'} // Let Dio handle it
```

## References

- **Backend Docs:** See BACKEND_DOCUMENTATION_REFERENCE.md
- **API Endpoints:** All endpoints defined in `lib/core/constants/api_endpoints.dart`
- **Services:** See `lib/data/services/` and their inline documentation
- **Models:** See `lib/data/models/`
- **Providers:** See `lib/data/providers/core_providers.dart`

## Support

For questions or issues:
1. Check backend logs: `python manage.py check_system`
2. Check interceptor output in Flutter debugger
3. Review service-specific README in `lib/data/services/README.md`
4. Verify endpoint URL matches backend documentation
