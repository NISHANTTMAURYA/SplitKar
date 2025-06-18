from django.urls import path
from django.contrib.admin.views.autocomplete import AutocompleteJsonView
from . import views

app_name = 'connections'

urlpatterns = [
    path('profile/lookup/<str:profile_code>/', views.lookup_profile_by_code, name='profile-lookup'),
    path('profile/list-others/', views.list_users_with_profiles, name='profile-list'),
    path('profile/list-all/', views.list_all_users, name='profile-list-all'),
    path('friend-request/pending/', views.list_pending_friend_requests, name='pending-friend-requests'),
    path('friend-request/send/', views.send_friend_request, name='send-friend-request'),
    path('friend-request/accept/', views.accept_friend_request, name='accept-friend-request'),
    path('friend-request/decline/', views.decline_friend_request, name='decline-friend-request'),
    path('friends/list/', views.get_friends_list, name='friends-list'),
    path('friends/remove/', views.remove_friend, name='remove-friend'),
    path('group/create/', views.create_group, name='create-group'),
    path('group/invite/', views.invite_to_group, name='invite-to-group'),
    path('group/remove-member/', views.remove_group_member, name='remove-group-member'),
    path('group/invitation/pending/', views.list_pending_group_invitations, name='list-pending-group-invitations'),
    path('group/invitation/accept/', views.accept_group_invitation, name='accept-group-invitation'),
    path('group/invitation/decline/', views.decline_group_invitation, name='decline-group-invitation'),
    path('group/list/', views.list_user_groups, name='list-user-groups'),
    path('group/batch-create/', views.batch_create_group, name='batch-create-group'),
    path('admin/user-lookup/', AutocompleteJsonView.as_view(), name='admin-user-lookup'),
    path('group/details/<int:group_id>/', views.get_group_details, name='get-group-details'),
]
