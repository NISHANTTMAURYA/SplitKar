from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from .models import FriendRequest, Profile, Group, GroupInvitation, Friendship


class FriendRequestByCodeSerializer(serializers.Serializer):
    profile_code = serializers.CharField(required=True, max_length=20)
    
    def validate_profile_code(self, value):
        try:
            profile = Profile.objects.get(profile_code=value)
            if profile.user == self.context['request'].user:
                raise serializers.ValidationError(_("You cannot send a friend request to yourself."))
            return value
        except Profile.DoesNotExist:
            raise serializers.ValidationError(_("No user found with this profile code."))
    
    def create(self, validated_data):
        from_user = self.context['request'].user
        to_user = Profile.objects.get(profile_code=validated_data['profile_code']).user
        
        try:
            friend_request = FriendRequest.objects.send_request(from_user=from_user, to_user=to_user)
            return friend_request
        except ValidationError as e:
            raise serializers.ValidationError(str(e))

class ProfileLookupSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username')
    
    class Meta:
        model = Profile
        fields = ['username', 'profile_code']

class FriendRequestAcceptSerializer(serializers.Serializer):
    request_id = serializers.IntegerField(required=True)

    def validate_request_id(self, value):
        try:
            friend_request = FriendRequest.objects.get(id=value)
        except FriendRequest.DoesNotExist:
            raise serializers.ValidationError(_("Friend request not found."))

        # Ensure the request is addressed to the current user
        if friend_request.to_user != self.context['request'].user:
            raise serializers.ValidationError(_("You can only accept requests sent to you."))

        # Ensure the request is pending
        if friend_request.status != 'pending':
            raise serializers.ValidationError(_("This friend request is not pending."))

        self.instance = friend_request # Store the instance for use in save()
        return value

    def save(self, **kwargs):
        if not hasattr(self, 'instance'):
            raise serializers.ValidationError("Validator did not set instance.")
        friend_request = self.instance
        friend_request.accept()
        return friend_request

class FriendRequestDeclineSerializer(serializers.Serializer):
    request_id = serializers.IntegerField(required=True)

    def validate_request_id(self, value):
        try:
            friend_request = FriendRequest.objects.get(id=value)
        except FriendRequest.DoesNotExist:
            raise serializers.ValidationError(_("Friend request not found."))

        # Ensure the request is addressed to the current user
        if friend_request.to_user != self.context['request'].user:
            raise serializers.ValidationError(_("You can only decline requests sent to you."))

        # Ensure the request is pending
        if friend_request.status != 'pending':
            raise serializers.ValidationError(_("This friend request is not pending."))

        self.instance = friend_request # Store the instance for use in save()
        return value

    def save(self, **kwargs):
        if not hasattr(self, 'instance'):
            raise serializers.ValidationError("Validator did not set instance.")
        friend_request = self.instance
        friend_request.decline()
        return friend_request

class UserProfileListSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username')
    profile_code = serializers.CharField()
    
    class Meta:
        model = Profile
        fields = ['username', 'profile_code']

class PendingFriendRequestSerializer(serializers.ModelSerializer):
    from_username = serializers.CharField(source='from_user.username')
    to_username = serializers.CharField(source='to_user.username')
    request_id = serializers.IntegerField(source='id')
    
    class Meta:
        model = FriendRequest
        fields = ['request_id', 'from_username', 'to_username', 'created_at']

class FriendListSerializer(serializers.ModelSerializer):
    profile_code = serializers.CharField(source='profile.profile_code')
    profile_picture_url = serializers.CharField(source='profile.profile_picture_url', allow_null=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'profile_code', 'profile_picture_url']

class GroupCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Group
        fields = ['name', 'description']
        extra_kwargs = {
            'description': {'required': False}
        }
    
    def validate_name(self, value):
        if len(value.strip()) == 0:
            raise serializers.ValidationError("Group name cannot be empty")
        return value
    
    def create(self, validated_data):
        group = Group.objects.create(
            created_by=self.context['request'].user,
            **validated_data
        )
        # Add creator as a member
        group.members.add(self.context['request'].user)
        return group

class GroupInviteSerializer(serializers.Serializer):
    group_id = serializers.IntegerField(required=True)
    profile_codes = serializers.ListField(
        child=serializers.CharField(max_length=20),
        required=True,
        help_text="List of profile codes to invite to the group"
    )
    
    def validate_group_id(self, value):
        try:
            group = Group.objects.get(id=value)
            if group.created_by != self.context['request'].user:
                raise serializers.ValidationError("You can only invite members to groups you created")
            return value
        except Group.DoesNotExist:
            raise serializers.ValidationError("Group not found")
    
    def validate_profile_codes(self, value):
        if not value:
            raise serializers.ValidationError("At least one profile code must be specified")
        
        # Check if all profile codes exist
        existing_profiles = Profile.objects.filter(profile_code__in=value)
        existing_codes = set(existing_profiles.values_list('profile_code', flat=True))
        invalid_codes = set(value) - existing_codes
        if invalid_codes:
            raise serializers.ValidationError(f"Invalid profile codes: {invalid_codes}")
        
        # Check if any users are already members
        group = Group.objects.get(id=self.initial_data['group_id'])
        existing_members = set(group.members.filter(profile__profile_code__in=value).values_list('profile__profile_code', flat=True))
        if existing_members:
            raise serializers.ValidationError(f"Users with profile codes {existing_members} are already members of this group")
        
        # Check if trying to invite yourself
        current_user_profile_code = self.context['request'].user.profile.profile_code
        if current_user_profile_code in value:
            raise serializers.ValidationError("You cannot invite yourself to the group")
        
        return value
    
    def create(self, validated_data):
        group = Group.objects.get(id=validated_data['group_id'])
        profiles_to_invite = Profile.objects.filter(profile_code__in=validated_data['profile_codes'])
        
        invitations = []
        for profile in profiles_to_invite:
            invitation = GroupInvitation.objects.create(
                group=group,
                invited_user=profile.user,
                invited_by=self.context['request'].user
            )
            invitations.append(invitation)
        
        return invitations

class GroupInvitationAcceptSerializer(serializers.Serializer):
    invitation_id = serializers.IntegerField(required=True)
    
    def validate_invitation_id(self, value):
        try:
            invitation = GroupInvitation.objects.get(id=value)
            if invitation.invited_user != self.context['request'].user:
                raise serializers.ValidationError("You can only accept invitations sent to you")
            if invitation.status != 'pending':
                raise serializers.ValidationError("This invitation is no longer pending")
            if invitation.is_expired:
                raise serializers.ValidationError("This invitation has expired")
            self.instance = invitation  # Store for use in save()
            return value
        except GroupInvitation.DoesNotExist:
            raise serializers.ValidationError("Invitation not found")
    
    def save(self, **kwargs):
        if not hasattr(self, 'instance'):
            raise serializers.ValidationError("Validator did not set instance")
        
        invitation = self.instance
        invitation.status = 'accepted'
        invitation.save()
        
        # Add user to group members
        invitation.group.members.add(invitation.invited_user)
        
        return invitation

class GroupInvitationDeclineSerializer(serializers.Serializer):
    invitation_id = serializers.IntegerField(required=True)
    
    def validate_invitation_id(self, value):
        try:
            invitation = GroupInvitation.objects.get(id=value)
            if invitation.invited_user != self.context['request'].user:
                raise serializers.ValidationError("You can only decline invitations sent to you")
            if invitation.status != 'pending':
                raise serializers.ValidationError("This invitation is no longer pending")
            if invitation.is_expired:
                raise serializers.ValidationError("This invitation has expired")
            self.instance = invitation  # Store for use in save()
            return value
        except GroupInvitation.DoesNotExist:
            raise serializers.ValidationError("Invitation not found")
    
    def save(self, **kwargs):
        if not hasattr(self, 'instance'):
            raise serializers.ValidationError("Validator did not set instance")
        
        invitation = self.instance
        invitation.status = 'declined'
        invitation.save()
        return invitation

class PendingGroupInvitationSerializer(serializers.ModelSerializer):
    invitation_id = serializers.IntegerField(source='id')
    group_name = serializers.CharField(source='group.name')
    group_id = serializers.IntegerField(source='group.id')
    group_description = serializers.CharField(source='group.description')
    invited_by_username = serializers.CharField(source='invited_by.username')
    invited_by_profile_code = serializers.CharField(source='invited_by.profile.profile_code')
    invited_user_username = serializers.CharField(source='invited_user.username')
    invited_user_profile_code = serializers.CharField(source='invited_user.profile.profile_code')
    
    class Meta:
        model = GroupInvitation
        fields = [
            'invitation_id',
            'group_id',
            'group_name',
            'group_description',
            'invited_by_username',
            'invited_by_profile_code',
            'invited_user_username',
            'invited_user_profile_code',
            'status',
            'created_at',
            'expires_at'
        ]

class UserGroupListSerializer(serializers.ModelSerializer):
    created_by = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()
    is_creator = serializers.SerializerMethodField()

    class Meta:
        model = Group
        fields = ['id', 'name', 'description', 'created_by', 'member_count', 'created_at', 'is_creator']

    def get_created_by(self, obj):
        return obj.created_by.username

    def get_member_count(self, obj):
        return obj.members.count()

    def get_is_creator(self, obj):
        request = self.context.get('request')
        if request and request.user:
            return obj.created_by == request.user
        return False

class RemoveFriendSerializer(serializers.Serializer):
    profile_code = serializers.CharField(required=True, max_length=20)
    
    def validate_profile_code(self, value):
        try:
            profile = Profile.objects.get(profile_code=value)
            if profile.user == self.context['request'].user:
                raise serializers.ValidationError(_("You cannot remove yourself as a friend."))
            
            # Check if they are actually friends
            if not Friendship.objects.are_friends(self.context['request'].user, profile.user):
                raise serializers.ValidationError(_("This user is not your friend."))
            
            return value
        except Profile.DoesNotExist:
            raise serializers.ValidationError(_("No user found with this profile code."))
    
    def save(self, **kwargs):
        from .models import Friendship
        from_user = self.context['request'].user
        to_user = Profile.objects.get(profile_code=self.validated_data['profile_code']).user
        
        # Remove the friendship
        deleted_count = Friendship.objects.delete_friendship(from_user, to_user)
        return {'deleted_count': deleted_count} 