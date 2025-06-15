from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Profile, FriendRequest, Friendship, Group, GroupInvitation, User
from .serializers import (
    ProfileLookupSerializer, FriendRequestByCodeSerializer, 
    FriendRequestAcceptSerializer, FriendRequestDeclineSerializer, 
    UserProfileListSerializer, PendingFriendRequestSerializer,
    FriendListSerializer, GroupCreateSerializer, GroupInviteSerializer,
    GroupInvitationAcceptSerializer, GroupInvitationDeclineSerializer,
    PendingGroupInvitationSerializer, UserGroupListSerializer, RemoveFriendSerializer, RemoveGroupMemberSerializer
)
from django.db.models import Q

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
    List all users that are not friends with the current user.
    Returns a paginated list of users with their usernames, profile codes, and friend request status.
    Supports:
    - Pagination (page, page_size)
    - Search query (search)
    """
    # Get pagination parameters
    page = int(request.GET.get('page', 1))
    page_size = int(request.GET.get('page_size', 10))  # Smaller page size for testing
    search_query = request.GET.get('search', '').strip()
    
    # Calculate offset
    offset = (page - 1) * page_size
    
    # Get IDs of current user's friends
    friend_ids = set(friend.id for friend in Friendship.objects.friends_of(request.user))
    friend_ids.add(request.user.id)  # Add current user's ID to exclusion set
    
    # Base query for non-friend profiles
    profiles = Profile.objects.select_related('user').exclude(
        user_id__in=friend_ids
    ).filter(
        is_active=True  # Only show active profiles
    )
    
    # Apply search if provided
    if search_query:
        profiles = profiles.filter(
            Q(user__username__icontains=search_query) |
            Q(profile_code__icontains=search_query)
        )
    
    # Get total count for pagination
    total_count = profiles.count()
    
    # Apply pagination
    profiles = profiles[offset:offset + page_size]
    
    # Get pending friend requests in a single query
    pending_requests = FriendRequest.objects.filter(
        Q(from_user=request.user) | Q(to_user=request.user),
        status='pending'
    ).values_list('from_user_id', 'to_user_id')
    
    # Create sets for O(1) lookup
    sent_requests = {to_id for from_id, to_id in pending_requests if from_id == request.user.id}
    received_requests = {from_id for from_id, to_id in pending_requests if to_id == request.user.id}
    
    # Prepare response data efficiently
    response_data = {
        'users': [{
            'username': profile.user.username,
            'profile_code': profile.profile_code,
            'profile_picture_url': profile.profile_picture_url,
            'friend_request_status': (
                'sent' if profile.user.id in sent_requests
                else 'received' if profile.user.id in received_requests
                else 'none'
            )
        } for profile in profiles],
        'pagination': {
            'total_count': total_count,
            'page': page,
            'page_size': page_size,
            'total_pages': (total_count + page_size - 1) // page_size,
            'has_next': (offset + page_size) < total_count,
            'has_previous': page > 1
        }
    }
    
    return Response(response_data)

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
    
    For trip groups, the following fields are required:
    - destination
    - start_date
    - end_date
    - trip_status
    """
    serializer = GroupCreateSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        group = serializer.save()
        response_data = {
            'id': group.id,
            'name': group.name,
            'description': group.description,
            'created_by': group.created_by.username,
            'member_count': group.member_count,
            'created_at': group.created_at,
            'group_type': group.group_type
        }
        
        # Add trip details if it's a trip group
        if group.group_type == 'trip':
            response_data['trip_details'] = {
                'destination': group.destination,
                'start_date': group.start_date,
                'end_date': group.end_date,
                'trip_status': group.trip_status,
                'budget': group.budget
            }
            
        return Response(response_data, status=status.HTTP_201_CREATED)
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
    - Group type (regular/trip)
    - Trip details (if it's a trip group)
    """
    # Get all groups where the user is a member
    user_groups = Group.objects.filter(members=request.user).select_related('created_by').order_by('-created_at')
    
    # Serialize the groups
    serializer = UserGroupListSerializer(user_groups, many=True, context={'request': request})
    
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def remove_group_member(request):
    """
    Remove members from a group using their profile codes.
    Only the group creator can remove members.
    Returns information about the removed members.
    """
    serializer = RemoveGroupMemberSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        try:
            result = serializer.save()
            return Response({
                'message': f'Successfully removed {result["removed_count"]} member(s) from the group',
                'removed_count': result['removed_count'],
                'removed_users': result['removed_users']
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_all_users(request):
    """
    List all users except the current user, with pagination and search support.
    Returns all friends first, then paginates remaining users.
    """
    try:
        # Get pagination parameters
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 10))
        search_query = request.GET.get('search', '').strip()
        
        # Get current user's profile with error handling
        try:
            current_profile = request.user.profile
        except Profile.DoesNotExist:
            return Response(
                {'error': 'Profile not found for current user'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get friend IDs for current user
        try:
            friend_pairs = Friendship.objects.filter(
                Q(user1=request.user) | Q(user2=request.user)
            ).values_list('user1_id', 'user2_id')
            
            # Extract friend IDs from pairs
            friend_ids = set()
            for user1_id, user2_id in friend_pairs:
                friend_ids.add(user1_id if user1_id != request.user.id else user2_id)
        except Exception as e:
            print(f"Error getting friend IDs: {str(e)}")
            friend_ids = set()

        # Get pending friend request IDs
        try:
            pending_sent = set(FriendRequest.objects.filter(
                from_user=request.user,
                status='pending'
            ).values_list('to_user_id', flat=True))
            
            pending_received = set(FriendRequest.objects.filter(
                to_user=request.user,
                status='pending'
            ).values_list('from_user_id', flat=True))
        except Exception as e:
            print(f"Error getting pending friend requests: {str(e)}")
            pending_sent = set()
            pending_received = set()

        # Base queryset - all profiles except current user
        profiles = Profile.objects.exclude(id=current_profile.id)
        
        # Apply search if provided
        if search_query:
            profiles = profiles.filter(
                Q(user__username__icontains=search_query) |
                Q(profile_code__icontains=search_query)
            )

        # Get all friends first
        friend_profiles = profiles.filter(user_id__in=friend_ids).select_related('user')
        friend_data = []
        for profile in friend_profiles:
            try:
                user = profile.user
                friend_data.append({
                    'id': user.id,
                    'username': user.username,
                    'profile_code': profile.profile_code,
                    'profile_picture_url': profile.profile_picture_url,
                    'is_friend': True,
                    'friend_request_status': 'none',
                })
            except Exception as e:
                print(f"Error processing friend profile {profile.id}: {str(e)}")
                continue

        # Get non-friend profiles for pagination
        non_friend_profiles = profiles.exclude(user_id__in=friend_ids)
        total_non_friends = non_friend_profiles.count()
        
        # Calculate offset for non-friends
        offset = (page - 1) * page_size
        
        # Get paginated non-friend profiles
        non_friend_profiles = non_friend_profiles.select_related('user')[offset:offset + page_size]
        
        # Prepare non-friend data
        non_friend_data = []
        for profile in non_friend_profiles:
            try:
                user = profile.user
                friend_request_status = 'sent' if user.id in pending_sent else 'received' if user.id in pending_received else 'none'
                
                non_friend_data.append({
                    'id': user.id,
                    'username': user.username,
                    'profile_code': profile.profile_code,
                    'profile_picture_url': profile.profile_picture_url,
                    'is_friend': False,
                    'friend_request_status': friend_request_status,
                })
            except Exception as e:
                print(f"Error processing non-friend profile {profile.id}: {str(e)}")
                continue

        # Combine friends and paginated non-friends
        users_data = friend_data + non_friend_data
        
        # Calculate pagination info for non-friends
        total_pages = (total_non_friends + page_size - 1) // page_size
        has_next = page < total_pages
        
        return Response({
            'users': users_data,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_count': total_non_friends,  # Only count non-friends for pagination
                'total_pages': total_pages,
                'has_next': has_next,
                'friend_count': len(friend_data),  # Add friend count for frontend reference
            }
        })
        
    except Exception as e:
        print(f"Error in list_all_users: {str(e)}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# backend/connections/views.py
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def batch_create_group(request):
    """
    Create a group and invite members in a single request.
    """
    try:
        # Extract group data and member data
        group_data = {
            'name': request.data.get('name'),
            'description': request.data.get('description'),
            'group_type': request.data.get('group_type'),
            'created_by': request.user,
        }
        
        # Add trip details if it's a trip group
        if group_data['group_type'] == 'trip':
            group_data.update({
                'destination': request.data.get('destination'),
                'start_date': request.data.get('start_date'),
                'end_date': request.data.get('end_date'),
                'trip_status': request.data.get('trip_status'),
                'budget': request.data.get('budget'),
            })

        # Create the group
        group = Group.objects.create(**group_data)
        group.members.add(request.user)  # Add creator as member

        # Process invitations if any
        profile_codes = request.data.get('profile_codes', [])
        invitations = []
        
        if profile_codes:
            # Get profiles for the provided codes
            profiles = Profile.objects.filter(profile_code__in=profile_codes)
            
            # Create invitations
            for profile in profiles:
                invitation = GroupInvitation.objects.create(
                    group=group,
                    invited_by=request.user,
                    invited_user=profile.user,
                    status='pending'
                )
                invitations.append(invitation)

        return Response({
            'message': 'Group created and invitations sent successfully',
            'group': {
                'id': group.id,
                'name': group.name,
                'description': group.description,
                'member_count': group.member_count,
                'created_by': group.created_by.username,
                'group_type': group.group_type,
                'invitations_sent': len(invitations)
            }
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )