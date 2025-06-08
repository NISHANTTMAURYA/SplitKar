from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Profile, FriendRequest, Friendship
from .serializers import (
    ProfileLookupSerializer, FriendRequestByCodeSerializer, 
    FriendRequestAcceptSerializer, FriendRequestDeclineSerializer, 
    UserProfileListSerializer, PendingFriendRequestSerializer,
    FriendListSerializer
)

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

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_users_with_profiles(request):
    """
    List all users with their profile codes, excluding the current user.
    Returns a list of users with their usernames and profile codes.
    """
    profiles = Profile.objects.select_related('user').exclude(user=request.user)
    serializer = UserProfileListSerializer(profiles, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_pending_friend_requests(request):
    """
    List all pending friend requests for the current user (both sent and received).
    """
    # Get requests sent by the current user
    sent_requests = FriendRequest.objects.filter(
        from_user=request.user,
        status='pending'
    ).select_related('to_user')
    
    # Get requests received by the current user
    received_requests = FriendRequest.objects.filter(
        to_user=request.user,
        status='pending'
    ).select_related('from_user')
    
    print(f"Current user: {request.user.username}")
    print(f"Current user ID: {request.user.id}")
    print(f"Sent requests count: {sent_requests.count()}")
    print(f"Received requests count: {received_requests.count()}")
    
    # Combine both querysets
    sent_data = PendingFriendRequestSerializer(sent_requests, many=True).data
    received_data = PendingFriendRequestSerializer(received_requests, many=True).data
    
    return Response({
        'sent_requests': sent_data,
        'received_requests': received_data,
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_friends_list(request):
    """
    Get a list of all friends for the authenticated user.
    Returns a list of friends with their usernames, profile codes, and profile pictures.
    """
    friends = Friendship.objects.friends_of(request.user)
    serializer = FriendListSerializer(friends, many=True)
    return Response(serializer.data)
