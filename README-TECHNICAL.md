# SplitKar - Technical Documentation 🛠️

<div align="center">

*SplitKar's High-Level Architecture*

[![Flutter Version](https://img.shields.io/badge/Flutter-^3.8.0-blue.svg)](https://flutter.dev/)
[![Django Version](https://img.shields.io/badge/Django-^4.2-green.svg)](https://www.djangoproject.com/)
[![DRF Version](https://img.shields.io/badge/DRF-^3.14-red.svg)](https://www.django-rest-framework.org/)

</div>

---

## Project Structure 📁

```
splitkar/
├── frontend/                 # Flutter App
│   ├── lib/
│   │   ├── screens/         # App screens
│   │   ├── widgets/         # Reusable widgets
│   │   ├── services/        # API services
│   │   ├── models/          # Data models
│   │   └── utils/           # Utilities
│   └── assets/              # App assets
└── backend/                 # Django Backend
    ├── api/                 # REST API
    ├── core/               # Core functionality
    ├── users/              # User management
    └── groups/             # Group management
```

## Tech Stack Overview 🏗️

### Frontend Architecture
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **UI Components**: Custom modular widgets
- **Caching**: Local caching with background sync

### Backend Architecture
- **Framework**: Django with Django REST Framework
- **Database**: 
  - Development: SQLite
  - Production: PostgreSQL (planned)
- **Authentication**: JWT + Google Sign-In
- **API Format**: REST (JSON)

## Authentication Flow 🔐
1. **Google Sign-In (Flutter)**
   - Implements Google Sign-In SDK
   - Retrieves Google ID token
2. **Token Exchange**
   - Flutter sends token to Django backend
   - Backend verifies with Google
3. **JWT Generation**
   - Backend generates JWT token
   - Token stored securely in Flutter
4. **Session Management**
   - Local cache for instant load
   - Background token refresh

## API Endpoints 🔌

### Authentication
```http
POST /auth/google/     # Google login
POST /auth/register/   # User registration
POST /auth/login/      # JWT login
POST /auth/validate/   # Token validation
POST /auth/token/refresh/  # Token refresh
```

### Profile Management
```http
GET  /profile/lookup/<code>/   # Profile lookup
GET  /profile/list-others/     # List other users
GET  /profile/list-all/        # List all users
GET  /profile/                 # Get profile details
POST /profile/update/          # Update profile
```

[View all endpoints in Postman Documentation](#)

## Admin Interface 💻

<div align="center">
  <img src="https://github.com/NISHANTTMAURYA/images/blob/main/admin-panel.png" alt="Admin Dashboard" width="800"/>
  <p><em>Django Admin Interface for User and Transaction Management</em></p>
</div>

## Mobile App Screenshots 📱

<div align="center">
  <table>
    <tr>
      <td><img src="https://github.com/NISHANTTMAURYA/images/blob/main/app1.jpeg" alt="Login Screen" width="250"/></td>
      <td><img src="https://github.com/NISHANTTMAURYA/images/blob/main/app2.jpeg" alt="Profile & Settings" width="250"/></td>
      <td><img src="https://github.com/NISHANTTMAURYA/images/blob/main/app3.jpeg" alt="Initial Groups & Friends" width="250"/></td>
    </tr>
    <tr>
      <td align="center"><em>Login with Google</em></td>
      <td align="center"><em>User Profile & App Settings</em></td>
      <td align="center"><em>Initial Groups & Friends View</em></td>
    </tr>
  </table>

  <table>
    <tr>
      <td><img src="https://github.com/NISHANTTMAURYA/images/blob/main/app4.jpeg" alt="Notifications" width="250"/></td>
      <td><img src="https://github.com/NISHANTTMAURYA/images/blob/main/app5.jpeg" alt="Active Groups" width="250"/></td>
    </tr>
    <tr>
      <td align="center"><em>Notification System</em></td>
      <td align="center"><em>Active Groups Management</em></td>
    </tr>
  </table>
  <p><em>SplitKar's modern and intuitive mobile interface showcasing key features</em></p>
</div>

## Flutter Dependencies 📦

### Core Dependencies
```yaml
dependencies:
  google_fonts: ^6.2.1
  google_sign_in: ^6.1.6
  http: ^1.1.0
  provider: ^6.1.5
  flutter_secure_storage: ^9.0.0
```

### UI & Animation
```yaml
dependencies:
  rive: ^0.13.20
  lottie: ^3.3.1
  stylish_bottom_bar: ^1.1.1
  cached_network_image: ^3.4.1
```

## Alert System Implementation 🔔

### Key Features
- Real-time updates with optimistic UI
- Per-alert state management
- Smooth animations
- Category-based filtering
- Memory efficient

### Best Practices
```dart
// Context Safety
void handleAction() async {
  if (!context.mounted) return;
  await someAsyncOperation();
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

// Efficient List Updates
ListView.builder(
  itemBuilder: (context, index) {
    return Selector<AlertService, bool>(
      selector: (_, service) => service.isProcessing(alert.id),
      builder: (context, isProcessing, child) => AlertCard(
        alert: alert,
        isProcessing: isProcessing,
      ),
    );
  },
)
```

## Deployment Strategy 🚀

### Backend
- **Platform Options**: Render, Railway, or Vercel
- **Database Migration**: SQLite → PostgreSQL
- **Scaling**: Horizontal scaling support planned

### Frontend
- **Current**: Development and testing phase
- **Target**: Google Play Store
- **Alternative**: Web deployment consideration

## Development Guidelines 📝

### Code Organization
- Modular component architecture
- Separate business logic from UI
- Reusable widgets for common elements
- Cached data with background refresh

### Performance Optimization
- Minimized API calls
- Local caching strategy
- Efficient state management
- Optimized list rendering

---

<div align="center">

### Contributing
Read our [Contributing Guidelines](CONTRIBUTING.md) to get started.

### License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

</div>

*Note: This technical documentation is continuously updated as new features and improvements are added to the codebase.* 