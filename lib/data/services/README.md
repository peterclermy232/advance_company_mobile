// lib/data/services/README.md
# Backend API Services

Comprehensive API service layer aligned with the Advance Company Django REST Framework backend.

## Overview

The services directory contains domain-specific API clients that wrap the `ApiClient` and handle communication with backend endpoints. Each service corresponds to a major backend module:

- **auth_service.dart** - Authentication, user management, 2FA, biometrics
- **financial_service.dart** - Accounts, deposits, interest
- **beneficiary_service.dart** - Beneficiary CRUD and verification
- **document_service.dart** - Document uploads and verification
- **application_service.dart** - Application submissions and admin review
- **notification_service.dart** - Notification retrieval and management
- **report_service.dart** - Report generation and analytics
- **admin_service.dart** - Admin analytics (admin only)
- **health_service.dart** - Health checks and metrics

## Backend API Structure

All endpoints are relative to `/api` base URL:

```
https://advance-company-backend-v1-0-3.onrender.com/api
```

### Authentication Model

JWT Bearer tokens via `djangorestframework-simplejwt`:

```json
{
  "tokens": {
    "access": "...",      // 30 minute lifetime
    "refresh": "..."      // 7 day lifetime
  }
}
```

Authenticated requests include:
```http
Authorization: Bearer <access_token>
```

Refresh endpoint:
```http
POST /api/token/refresh/
Body: { "refresh": "<refresh_token>" }
```

### Standard Response Shapes

**Wrapped responses (Auth, some CRUD):**
```json
{
  "success": true,
  "message": "User-friendly message",
  "toast_type": "success",
  "data": {}
}
```

**Raw DRF responses (most viewsets):**
```json
{
  "uuid": "...",
  "email": "....",
  "created_at": "..."
}
```

**Paginated responses:**
```json
{
  "count": 100,
  "next": "https://...",
  "previous": "https://...",
  "results": [...]
}
```

## Usage Examples

### Authentication

```dart
// Login
final authService = AuthService(apiClient: apiClient);

final response = await authService.login(
  email: 'user@example.com',
  password: 'StrongPassword123!',
);

// Tokens are automatically stored by the ApiClient interceptor
// Access current user
final user = await authService.getCurrentUser();
```

### Financial Management

```dart
final financialService = FinancialService(apiClient: apiClient);

// Get user's account
final account = await financialService.getMyAccount();

// Check if can deposit
final canDeposit = await financialService.canDeposit();

// Create monthly deposit (KES 20,000 fixed)
final deposit = await financialService.createDeposit(
  paymentMethod: 'mpesa',
  mpesaPhone: '254712345678',
  notes: 'Monthly contribution',
);

// Get monthly summary
final summary = await financialService.getMonthlySummary();
```

### Beneficiary Management

```dart
final beneficiaryService = BeneficiaryService(apiClient: apiClient);

// Create beneficiary (with document uploads)
final beneficiary = await beneficiaryService.createBeneficiary(
  name: 'John Spouse',
  relation: 'spouse',
  age: 35,
  gender: 'M',
  phoneNumber: '0712345678',
  profession: 'Engineer',
  salaryRange: '200000-300000',
  percentageAllocation: 50.0,
  identityDocumentPath: '/path/to/id.pdf',
);

// Get all beneficiaries
final benefs = await beneficiaryService.getBeneficiaries(page: 1);

// Update beneficiary
await beneficiaryService.updateBeneficiary(
  beneficiary.uuid,
  percentageAllocation: 60.0,
);

// Mark as deceased
await beneficiaryService.markDeceased(
  beneficiary.uuid,
  deathCertificatePath: '/path/to/cert.pdf',
  deathCertificateNumber: 'CERT123',
);
```

### Document Management

```dart
final documentService = DocumentService(apiClient: apiClient);

// Upload document (FormData with file)
final doc = await documentService.uploadDocument(
  category: 'identity',
  title: 'National ID',
  filePath: '/path/to/id.pdf',
);

// Get document view URL (for display/download)
final viewUrl = await documentService.getDocumentViewUrl(doc.uuid);
```

### Application Submission

```dart
final appService = ApplicationService(apiClient: apiClient);

// Submit application
final app = await appService.createApplication(
  applicationType: 'loan',
  reason: 'Need business capital',
  supportingDocumentPath: '/path/to/business_plan.pdf',
);

// Track status
print('Status: ${app.status}'); // pending, under_review, approved, rejected
```

### Notifications

```dart
final notificationService = NotificationService(apiClient: apiClient);

// Get unread count
final unreadCount = await notificationService.getUnreadCount();

// Get recent notifications
final recent = await notificationService.getRecentNotifications(limit: 5);

// Mark as read
await notificationService.markAsRead(notification.uuid);

// Mark all as read
await notificationService.markAllAsRead();
```

### Reports & Analytics

```dart
final reportService = ReportService(apiClient: apiClient);

// Get dashboard summary
final dashboard = await reportService.getDashboardSummary();
print('Total deposits: ${dashboard['total_deposits']}');

// Generate financial report
final report = await reportService.generateFinancialReport(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
);

// Get deposit trends
final trends = await reportService.getDepositTrends();
```

### Admin Features

```dart
final adminService = AdminService(apiClient: apiClient);

// Get members analytics
final analytics = await adminService.getMembersAnalytics(page: 1);

// Export to Excel
final export = await adminService.exportAnalytics(format: 'excel');
```

## Important Notes

### IDs and UUIDs

- All user-side resources use UUIDs (user, beneficiary, document, etc.)
- Application IDs are numeric
- Always use string types for IDs in models
- Pass IDs as strings in method parameters

### File Uploads

- All file uploads use `FormData` (multipart/form-data)
- Do NOT manually set Content-Type header
- Do NOT include `Authorization` header manually (interceptor handles it)
- Supported formats: PDF, JPG, JPEG, PNG
- Max file size: 10MB

Example:
```dart
final formData = FormData.fromMap({
  'category': 'identity',
  'title': 'National ID',
  'file': await MultipartFile.fromFile(filePath),
});
```

### Error Handling

The `ApiClient` normalizes errors into `DioException`:

```dart
try {
  await authService.login(...);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Unauthorized - token expired
  } else if (e.response?.statusCode == 422) {
    // Validation error
    print(e.response?.data['errors']);
  } else {
    print(e.message); // User-friendly error
  }
}
```

### Pagination

Many endpoints support pagination:

```dart
final response = await beneficiaryService.getBeneficiaries(
  page: 2,
  pageSize: 50,
);

// Response structure:
// {
//   "count": 100,
//   "next": "https://...",
//   "previous": "https://...",
//   "results": [...]
// }
```

### Role-Based Access

- **User endpoints:** `/beneficiary/`, `/financial/deposits/`, etc.
- **Admin endpoints:** `/financial/deposits/pending_approvals/`, `/admin/analytics/`, etc.

Use role from user model:
```dart
final user = await authService.getCurrentUser();
if (user.role == 'admin') {
  // Show admin features
}
```

## Integration Checklist

- [ ] Instantiate all services with the `ApiClient`
- [ ] Provide services via Riverpod providers
- [ ] Update interceptor to auto-attach Bearer tokens
- [ ] Implement token refresh on 401 responses
- [ ] Handle both wrapped and raw DRF responses
- [ ] Use FormData for all file uploads
- [ ] Normalize error messages for UI display
- [ ] Handle pagination for list endpoints
- [ ] Store tokens securely (flutter_secure_storage)
- [ ] Test upload, login, refresh, and approval flows

## Development Mode

To use local backend:

1. Update `lib/config/api_config.dart`:
```dart
static const bool _isProduction = false;

// Set devBaseUrl to your backend:
// Android Emulator: http://10.0.2.2:8000/api
// iOS Simulator: http://127.0.0.1:8000/api
// Physical device: http://<PC-IP>:8000/api
static const String devBaseUrl = 'http://10.0.2.2:8000/api';
```

2. Ensure backend is running:
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

3. For CORS, ensure Django settings include Flutter app origin:
```python
CORS_ALLOWED_ORIGINS = [
    'http://localhost:4200',
    'http://10.0.2.2:8000',
    # Add your device IP if needed
]
```
