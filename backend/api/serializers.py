from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from connections.models import Profile
from .models import AlertReadStatus

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password2 = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    email = serializers.EmailField(required=True)
    username = serializers.CharField(
        required=True,
        min_length=3,
        max_length=150
    )

    class Meta:
        model = User
        fields = ('username', 'email', 'password', 'password2', 'first_name', 'last_name')
        extra_kwargs = {
            'first_name': {'required': False},
            'last_name': {'required': False}
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError(_("A user with this email already exists."))
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError(_("A user with this username already exists."))
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": _("Password fields didn't match.")})
        
        # Additional password validation
        try:
            validate_password(attrs['password'])
        except ValidationError as e:
            raise serializers.ValidationError({"password": list(e.messages)})
        
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user

class UserLoginSerializer(serializers.Serializer):
    username_or_email = serializers.CharField(required=True)
    password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'}
    )

    def validate(self, attrs):
        username_or_email = attrs.get('username_or_email')
        password = attrs.get('password')

        if not username_or_email or not password:
            raise serializers.ValidationError(_("Both username/email and password are required."))

        return attrs 
    



class UserSerializer(serializers.ModelSerializer):
    profile_picture_url = serializers.SerializerMethodField()
    profile_code = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'profile_picture_url', 'profile_code']
    
    def get_profile_picture_url(self, obj):
        if hasattr(obj, 'profile') and obj.profile.profile_picture_url:
            return obj.profile.profile_picture_url
        return None

    def get_profile_code(self, obj):
        if hasattr(obj, 'profile'):
            return obj.profile.profile_code
        return None

class ProfileUpdateSerializer(serializers.ModelSerializer):
    username = serializers.CharField(
        required=True,
        min_length=3,
        max_length=150
    )

    class Meta:
        model = User
        fields = ('username', 'first_name', 'last_name')
        extra_kwargs = {
            'first_name': {'required': False},
            'last_name': {'required': False}
        }

    def validate_username(self, value):
        user = self.context['request'].user
        if User.objects.exclude(id=user.id).filter(username=value).exists():
            raise serializers.ValidationError(_("A user with this username already exists."))
        return value

class AlertReadStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = AlertReadStatus
        fields = ['alert_type', 'read_at', 'batch_id']

class MarkAlertReadSerializer(serializers.Serializer):
    alert_type = serializers.CharField()

class BatchAlertReadSerializer(serializers.Serializer):
    alert_types = serializers.ListField(
        child=serializers.CharField(),
        required=True
    )
    batch_id = serializers.CharField(required=False)