from django.contrib import admin
from .models import Profile, FriendRequest, Friendship, Group, GroupInvitation

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'profile_code', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('user__username', 'profile_code')
    readonly_fields = ('profile_code',)

@admin.register(FriendRequest)
class FriendRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'from_user', 'to_user', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('from_user__username', 'to_user__username')
    raw_id_fields = ('from_user', 'to_user')

@admin.register(Friendship)
class FriendshipAdmin(admin.ModelAdmin):
    list_display = ('user1', 'user2', 'created_at')
    search_fields = ('user1__username', 'user2__username')
    raw_id_fields = ('user1', 'user2')

@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_by', 'member_count', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('name', 'created_by__username')
    filter_horizontal = ('members',)
    raw_id_fields = ('created_by',)

@admin.register(GroupInvitation)
class GroupInvitationAdmin(admin.ModelAdmin):
    list_display = ('group', 'invited_user', 'invited_by', 'status', 'expires_at', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('group__name', 'invited_user__username', 'invited_by__username')
    raw_id_fields = ('group', 'invited_user', 'invited_by')
