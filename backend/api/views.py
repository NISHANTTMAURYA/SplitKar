from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import os
from .serializers import UserRegistrationSerializer, UserLoginSerializer, UserSerializer
from django.contrib.auth import authenticate
from django.db.models import Q
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import permission_classes, api_view
from rest_framework.exceptions import AuthenticationFailed
from connections.models import Profile


# Helper function to generate tokens and user data response
def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'profile_picture_url': user.profile.profile_picture_url
        }
    }

# Create your views here.

class GoogleLoginAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        token = request.data.get('id_token')
        profile_picture_url = request.data.get('profile_picture_url')
        print('Received id_token:', token[:40] + '...' if token else None)
        google_client_id = os.environ.get('GOOGLE_CLIENT_ID') or '7120580451-cmn9dcuv9eo0la2path3u1uppeegh37f.apps.googleusercontent.com'
        print('GOOGLE_CLIENT_ID used for verification:', google_client_id)
        if not token:
            return Response(
                {'error': _('No id_token provided')},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            # Verify the token with Google
            idinfo = id_token.verify_oauth2_token(
                token,
                google_requests.Request(),
                google_client_id
            )
            print('Token verification succeeded. idinfo:', idinfo)
            print('Token audience (aud):', idinfo.get('aud'))
            email = idinfo['email']
            first_name = idinfo.get('given_name', '')
            last_name = idinfo.get('family_name', '')
            
            # Check if user with this email already exists
            try:
                user = User.objects.get(email=email)
                # Update user info if needed
                if user.first_name != first_name or user.last_name != last_name:
                    user.first_name = first_name
                    user.last_name = last_name
                    user.save()
            except User.DoesNotExist:
                # Create new user
                username = email.split('@')[0]  # Use part before @ as username
                base_username = username
                counter = 1
                
                # Ensure unique username
                while User.objects.filter(username=username).exists():
                    username = f"{base_username}{counter}"
                    counter += 1
                
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    first_name=first_name,
                    last_name=last_name
                )
            
            # Update profile picture if provided (for both new and existing users)
            if profile_picture_url:
                user.profile.update_profile_picture(profile_picture_url)
            
            # Generate JWT and return response
            return Response(get_tokens_for_user(user))

        except ValueError as e:
            print('Token verification error:', e)
            return Response(
                {'error': _('Invalid id_token')},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            print('Unexpected error during Google token verification:', e)
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class UserRegistrationAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            serializer = UserRegistrationSerializer(data=request.data)
            if serializer.is_valid():
                user = serializer.save()
                # Handle profile picture URL if provided
                profile_picture_url = request.data.get('profile_picture_url')
                if profile_picture_url:
                    user.profile.update_profile_picture(profile_picture_url)
                # Generate JWT and return response
                return Response(get_tokens_for_user(user), status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except ValidationError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class UserLoginAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            serializer = UserLoginSerializer(data=request.data)
            if serializer.is_valid():
                username_or_email = serializer.validated_data['username_or_email']
                password = serializer.validated_data['password']
                
                # Try to find user by username or email
                try:
                    user = User.objects.get(Q(username=username_or_email) | Q(email=username_or_email))
                    
                    # Check if the user account has a usable password
                    if not user.has_usable_password():
                         raise AuthenticationFailed(_('This account was created using Google Sign-In. Please use the "Sign in with Google" option.'))

                    user = authenticate(username=user.username, password=password)
                    
                    if user:
                        # Handle profile picture URL if provided
                        profile_picture_url = request.data.get('profile_picture_url')
                        if profile_picture_url:
                            user.profile.update_profile_picture(profile_picture_url)
                        # Generate JWT and return response
                        return Response(get_tokens_for_user(user))
                    
                    # If user is found but authenticate fails (wrong password for usable password account)
                    raise AuthenticationFailed(_('Invalid credentials'))

                except User.DoesNotExist:
                    # If user is not found at all
                    raise AuthenticationFailed(_('Invalid credentials'))

            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except AuthenticationFailed as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@permission_classes([IsAuthenticated])
@api_view(['GET'])
def ProfileDetailsAPIView(request):
    user = request.user
    serializer = UserSerializer(user)
    return Response(serializer.data)
