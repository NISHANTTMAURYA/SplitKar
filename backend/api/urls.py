"""
API URL Configuration
-------------------
Optimization Notes:

1. API Versioning:
   - Current: No versioning
   - Needed: Add version prefix (e.g., /api/v1/)
   - Consider: Version deprecation strategy

2. Rate Limiting:
   - Current: No rate limiting
   - Needed: Add rate limiting middleware
   - Consider: Different limits for different endpoints

3. Security:
   - Add proper authentication checks
   - Implement request validation
   - Add proper CORS configuration

4. Performance:
   - Add proper caching headers
   - Implement request throttling
   - Add proper response compression

5. Documentation:
   - Add proper API documentation
   - Implement OpenAPI/Swagger
   - Add proper endpoint descriptions
"""

from django.urls import path, include
from .views import (
    GoogleLoginAPIView, 
    UserRegistrationAPIView, 
    UserLoginAPIView, 
    ProfileDetailsAPIView,
    CustomTokenRefreshView,
    ProfileUpdateAPIView,
    AlertReadStatusView,
    MarkAlertReadView,
    MarkAllAlertsReadView
)
from rest_framework_simplejwt.views import TokenVerifyView

# TODO: Add version prefix to all URLs
# TODO: Add rate limiting middleware
# TODO: Add proper authentication checks
# TODO: Add proper request validation
# TODO: Add proper CORS configuration

urlpatterns = [
    # TODO: Add version prefix (e.g., 'api/v1/')
    path('auth/google/', GoogleLoginAPIView.as_view(), name='google-login'),
    path('auth/register/', UserRegistrationAPIView.as_view(), name='user-register'),
    path('auth/login/', UserLoginAPIView.as_view(), name='user-login'),
    path('auth/validate/', TokenVerifyView.as_view(), name='token-verify'),
    path('auth/token/refresh/', CustomTokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', ProfileDetailsAPIView, name='profile-details'),
    path('profile/update/', ProfileUpdateAPIView.as_view(), name='profile-update'),
    path('alerts/read-status/', AlertReadStatusView.as_view(), name='alert-read-status'),
    path('alerts/mark-read/', MarkAlertReadView.as_view(), name='mark-alert-read'),
    path('alerts/mark-all-read/', MarkAllAlertsReadView.as_view(), name='mark-all-read'),
] 