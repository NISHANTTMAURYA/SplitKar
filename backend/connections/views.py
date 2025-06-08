from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Profile, FriendRequest
from .serializers import ProfileLookupSerializer, FriendRequestByCodeSerializer, FriendRequestAcceptSerializer, FriendRequestDeclineSerializer

# Create your views here.

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def lookup_profile_by_code(request, profile_code):
    """
    Lookup a user's profile by their profile code.
    Returns only the username and profile code.
    """
    try:
        profile = Profile.objects.get(profile_code=profile_code)
        serializer = ProfileLookupSerializer(profile)
        return Response(serializer.data)
    except Profile.DoesNotExist:
        return Response(
            {"error": "No user found with this profile code."},
            status=status.HTTP_404_NOT_FOUND
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_friend_request(request):
    """
    Send a friend request to a user using their profile code.
    """
    serializer = FriendRequestByCodeSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        try:
            friend_request = serializer.save()
            return Response({
                'message': 'Friend request sent successfully',
                'status': friend_request.status,
                'to_user': friend_request.to_user.username
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def accept_friend_request(request):
    """
    Accept a pending friend request.
    """
    serializer = FriendRequestAcceptSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        try:
            friend_request = serializer.save()
            return Response({
                'message': 'Friend request accepted successfully',
                'status': friend_request.status,
                'from_user': friend_request.from_user.username,
                'to_user': friend_request.to_user.username
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def decline_friend_request(request):
    """
    Decline a pending friend request.
    """
    serializer = FriendRequestDeclineSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        try:
            friend_request = serializer.save()
            return Response({
                'message': 'Friend request declined successfully',
                'status': friend_request.status,
                'from_user': friend_request.from_user.username,
                'to_user': friend_request.to_user.username
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
