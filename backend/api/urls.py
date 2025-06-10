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

urlpatterns = [
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