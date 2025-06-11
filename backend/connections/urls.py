from django.urls import path
from django.contrib.admin.views.autocomplete import AutocompleteJsonView
from . import views

app_name = 'connections'

urlpatterns = [
    path('profile/lookup/<str:profile_code>/', views.lookup_profile_by_code, name='profile-lookup'),
    path('profile/list-others/', views.list_users_with_profiles, name='profile-list'),
    path('friend-request/pending/', views.list_pending_friend_requests, name='pending-friend-requests'),
    path('friend-request/send/', views.send_friend_request, name='send-friend-request'),
    path('friend-request/accept/', views.accept_friend_request, name='accept-friend-request'),
    path('friend-request/decline/', views.decline_friend_request, name='decline-friend-request'),
    path('friends/list/', views.get_friends_list, name='friends-list'),
    path('friends/remove/', views.remove_friend, name='remove-friend'),
    path('groups/create/', views.create_group, name='create-group'),
    path('groups/invite/', views.invite_to_group, name='invite-to-group'),
    path('groups/remove-member/', views.remove_group_member, name='remove-group-member'),
    path('groups/invitation/pending/', views.list_pending_group_invitations, name='list-pending-group-invitations'),
    path('groups/invitation/accept/', views.accept_group_invitation, name='accept-group-invitation'),
    path('groups/invitation/decline/', views.decline_group_invitation, name='decline-group-invitation'),
    path('groups/list/', views.list_user_groups, name='list-user-groups'),
    path('admin/user-lookup/', AutocompleteJsonView.as_view(), name='admin-user-lookup'),
]
