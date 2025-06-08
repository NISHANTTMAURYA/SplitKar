from django.urls import path
from . import views

urlpatterns = [
    path('profile/lookup/<str:profile_code>/', views.lookup_profile_by_code, name='profile-lookup'),
    path('friend-request/send/', views.send_friend_request, name='send-friend-request'),
    path('friend-request/accept/', views.accept_friend_request, name='accept-friend-request'),
    path('friend-request/decline/', views.decline_friend_request, name='decline-friend-request'),
]
