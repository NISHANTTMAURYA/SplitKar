from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from .models import FriendRequest, Profile

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