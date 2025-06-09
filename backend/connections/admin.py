from django.contrib import admin
from django.utils import timezone
from django.contrib.auth.models import User
from django.contrib.admin.widgets import ForeignKeyRawIdWidget
from django.urls import reverse
from .models import Profile, FriendRequest, Friendship, Group, GroupInvitation

class TimeStampedAdmin(admin.ModelAdmin):
    """Base admin class for models with timestamps"""
    def get_created_time(self, obj):
        if obj.created_at:
            return obj.created_at.strftime("%Y-%m-%d %H:%M:%S")
        return "-"
    get_created_time.short_description = 'Created At'
    get_created_time.admin_order_field = 'created_at'

    def get_updated_time(self, obj):
        if obj.updated_at:
            return obj.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        return "-"
    get_updated_time.short_description = 'Updated At'
    get_updated_time.admin_order_field = 'updated_at'

class UserForeignKeyRawIdWidget(ForeignKeyRawIdWidget):
    def url_parameters(self):
        params = super().url_parameters()
        params['is_active'] = 'True'
        return params

    def label_for_value(self, value):
        try:
            user = User.objects.get(pk=value)
            return f'{user.username} ({user.email})'
        except User.DoesNotExist:
            return ''

@admin.register(Profile)
class ProfileAdmin(TimeStampedAdmin):
    list_display = ('id', 'user', 'profile_code', 'is_active', 'get_created_time', 'get_updated_time')
    list_filter = ('is_active', 'created_at', 'updated_at')
    search_fields = ('user__username', 'user__email', 'profile_code')
    readonly_fields = ('profile_code', 'get_created_time', 'get_updated_time')
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'

@admin.register(FriendRequest)
class FriendRequestAdmin(TimeStampedAdmin):
    list_display = ('id', 'from_user', 'to_user', 'status', 'get_created_time', 'get_updated_time')
    list_filter = ('status', 'created_at', 'updated_at')
    search_fields = ('from_user__username', 'to_user__username', 'from_user__email', 'to_user__email')
    raw_id_fields = ('from_user', 'to_user')
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name in ['from_user', 'to_user']:
            kwargs['widget'] = UserForeignKeyRawIdWidget(
                db_field.remote_field,
                self.admin_site,
                using=kwargs.get('using')
            )
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

@admin.register(Friendship)
class FriendshipAdmin(TimeStampedAdmin):
    list_display = ('id', 'user1', 'user2', 'get_created_time', 'get_updated_time')
    search_fields = ('user1__username', 'user2__username', 'user1__email', 'user2__email')
    raw_id_fields = ('user1', 'user2')
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name in ['user1', 'user2']:
            kwargs['widget'] = UserForeignKeyRawIdWidget(
                db_field.remote_field,
                self.admin_site,
                using=kwargs.get('using')
            )
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

    def get_friendship_duration(self, obj):
        if obj.created_at:
            duration = timezone.now() - obj.created_at
            days = duration.days
            if days > 365:
                years = days // 365
                return f"{years} year{'s' if years != 1 else ''}"
            elif days > 30:
                months = days // 30
                return f"{months} month{'s' if months != 1 else ''}"
            return f"{days} day{'s' if days != 1 else ''}"
        return "-"
    get_friendship_duration.short_description = 'Duration'

@admin.register(Group)
class GroupAdmin(TimeStampedAdmin):
    list_display = ('id', 'name', 'created_by', 'member_count', 'is_active', 'get_created_time', 'get_updated_time')
    list_filter = ('is_active', 'created_at', 'updated_at')
    search_fields = ('name', 'created_by__username', 'members__username')
    filter_horizontal = ('members',)
    raw_id_fields = ('created_by',)
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'

@admin.register(GroupInvitation)
class GroupInvitationAdmin(TimeStampedAdmin):
    list_display = ('id', 'group', 'invited_user', 'invited_by', 'status', 'get_expires_in', 'get_created_time', 'get_updated_time')
    list_filter = ('status', 'created_at', 'updated_at')
    search_fields = ('group__name', 'invited_user__username', 'invited_by__username')
    raw_id_fields = ('group', 'invited_user', 'invited_by')
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'

    def get_expires_in(self, obj):
        if obj.expires_at:
            if obj.expires_at < timezone.now():
                return "Expired"
            time_left = obj.expires_at - timezone.now()
            days = time_left.days
            hours = time_left.seconds // 3600
            if days > 0:
                return f"{days}d {hours}h left"
            return f"{hours}h left"
        return "No expiry"
    get_expires_in.short_description = 'Expires In'
