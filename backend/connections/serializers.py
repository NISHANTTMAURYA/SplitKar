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