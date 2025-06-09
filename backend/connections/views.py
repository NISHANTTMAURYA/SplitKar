from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Profile, FriendRequest, Friendship, Group, GroupInvitation
from .serializers import (
    ProfileLookupSerializer, FriendRequestByCodeSerializer, 
    FriendRequestAcceptSerializer, FriendRequestDeclineSerializer, 
    UserProfileListSerializer, PendingFriendRequestSerializer,
    FriendListSerializer, GroupCreateSerializer, GroupInviteSerializer,
    GroupInvitationAcceptSerializer, GroupInvitationDeclineSerializer,
    PendingGroupInvitationSerializer, UserGroupListSerializer, RemoveFriendSerializer
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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def remove_friend(request):
    """
    Remove a friend using their profile code.
    This will delete the friendship between the authenticated user and the specified friend.
    """
    serializer = RemoveFriendSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        try:
            result = serializer.save()
            return Response({
                'message': 'Friend removed successfully',
                'deleted_count': result['deleted_count']
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_group(request):
    """
    Create a new group.
    The authenticated user will automatically be added as a member and creator.
    Additional members can be added using member_ids in the request.
    """
    serializer = GroupCreateSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        group = serializer.save()
        return Response({
            'id': group.id,
            'name': group.name,
            'description': group.description,
            'created_by': group.created_by.username,
            'member_count': group.member_count,
            'created_at': group.created_at
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def invite_to_group(request):
    """
    Invite users to a group using their profile codes.
    Only the group creator can invite members.
    Returns a list of created invitations.
    """
    serializer = GroupInviteSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        invitations = serializer.save()
        return Response({
            'message': f'Successfully sent {len(invitations)} invitation(s)',
            'invitations': [
                {
                    'id': inv.id,
                    'group': inv.group.name,
                    'invited_user': inv.invited_user.username,
                    'profile_code': inv.invited_user.profile.profile_code,
                    'status': inv.status,
                    'created_at': inv.created_at
                }
                for inv in invitations
            ]
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def accept_group_invitation(request):
    """
    Accept a pending group invitation.
    The user will be added to the group's members upon acceptance.
    """
    serializer = GroupInvitationAcceptSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        invitation = serializer.save()
        return Response({
            'message': 'Successfully joined the group',
            'group': {
                'id': invitation.group.id,
                'name': invitation.group.name,
                'description': invitation.group.description,
                'member_count': invitation.group.member_count,
                'created_by': invitation.group.created_by.username
            },
            'invitation': {
                'id': invitation.id,
                'status': invitation.status,
                'accepted_at': invitation.updated_at
            }
        }, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def decline_group_invitation(request):
    """
    Decline a pending group invitation.
    """
    serializer = GroupInvitationDeclineSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        invitation = serializer.save()
        return Response({
            'message': 'Successfully declined the group invitation',
            'invitation': {
                'id': invitation.id,
                'group': invitation.group.name,
                'status': invitation.status,
                'declined_at': invitation.updated_at
            }
        }, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_pending_group_invitations(request):
    """
    List all pending group invitations for the current user (both sent and received).
    Returns a list of invitations with group details and user information.
    """
    # Get invitations sent by the current user
    sent_invitations = GroupInvitation.objects.filter(
        invited_by=request.user,
        status='pending'
    ).select_related('group', 'invited_user', 'invited_user__profile')
    
    # Get invitations received by the current user
    received_invitations = GroupInvitation.objects.filter(
        invited_user=request.user,
        status='pending'
    ).select_related('group', 'invited_by', 'invited_by__profile')
    
    # Serialize both querysets
    sent_data = PendingGroupInvitationSerializer(sent_invitations, many=True).data
    received_data = PendingGroupInvitationSerializer(received_invitations, many=True).data
    
    return Response({
        'sent_invitations': sent_data,
        'received_invitations': received_data,
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_user_groups(request):
    """
    List all groups that the authenticated user is a member of.
    Returns a list of groups with their details including:
    - Group ID, name, and description
    - Creator's username
    - Member count
    - Creation date
    - Whether the current user is the creator
    """
    # Get all groups where the user is a member
    user_groups = Group.objects.filter(members=request.user).select_related('created_by')
    
    # Serialize the groups
    serializer = UserGroupListSerializer(user_groups, many=True, context={'request': request})
    
    return Response({
        'groups': serializer.data,
        'total_groups': len(serializer.data)
    })
