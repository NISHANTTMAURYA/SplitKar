from django.urls import path
from . import views

urlpatterns = [
    path('profile/lookup/<str:profile_code>/', views.lookup_profile_by_code, name='profile-lookup'),
    path('profile/list-others/', views.list_users_with_profiles, name='profile-list'),
    path('friend-request/pending/', views.list_pending_friend_requests, name='pending-friend-requests'),
    path('friend-request/send/', views.send_friend_request, name='send-friend-request'),
    path('friend-request/accept/', views.accept_friend_request, name='accept-friend-request'),
    path('friend-request/decline/', views.decline_friend_request, name='decline-friend-request'),
    path('friends/list/', views.get_friends_list, name='friends-list'),
]
