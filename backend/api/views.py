from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import os

# Create your views here.

class GoogleLoginAPIView(APIView):
    def post(self, request):
        token = request.data.get('id_token')
        if not token:
            return Response({'error': 'No id_token provided'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            # Verify the token with Google
            idinfo = id_token.verify_oauth2_token(
                token,
                google_requests.Request(),
                os.environ.get('GOOGLE_CLIENT_ID') or '7120580451-cmn9dcuv9eo0la2path3u1uppeegh37f.apps.googleusercontent.com'
            )
            email = idinfo['email']
            first_name = idinfo.get('given_name', '')
            last_name = idinfo.get('family_name', '')
            # Get or create user
            user, created = User.objects.get_or_create(email=email, defaults={
                'username': email,
                'first_name': first_name,
                'last_name': last_name,
            })
            # Generate JWT
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                }
            })
        except ValueError:
            return Response({'error': 'Invalid id_token'}, status=status.HTTP_400_BAD_REQUEST)
