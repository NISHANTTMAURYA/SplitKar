from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django.contrib.auth.models import User
from decimal import Decimal
from .models import Expense, ExpensePayment, ExpenseShare, ExpenseCategory, UserTotalBalance, Balance
from .serializers import AddExpenseSerializer, UserSerializer, AddFriendExpenseSerializer, UserTotalBalanceSerializer, ExpenseListSerializer, BalanceSerializer, EditExpenseSerializer
from connections.models import Group
from django.db import models
from django.db.models import Q

@api_view(['GET'])
@permission_classes([AllowAny])
def list_expense_categories(request):
    """
    List all active expense categories
    """
    categories = ExpenseCategory.objects.filter(is_active=True).order_by('name')
    data = [
        {
            'id': cat.id,
            'name': cat.name,
            'icon': cat.icon,
            'color': cat.color
        }
        for cat in categories
    ]
    return Response(data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_expense(request):
    """
    Add an expense with equal or percentage splitting between specified users in a group
    Now supports multiple payers.
    """
    serializer = AddExpenseSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            expense = serializer.save()
            user_ids = serializer.validated_data['user_ids']
            group_id = serializer.validated_data['group_id']
            split_type = serializer.validated_data.get('split_type', 'equal')
            users = User.objects.filter(id__in=user_ids)
            group = Group.objects.get(id=group_id)
            total_amount = serializer.validated_data['total_amount']
            splits = request.data.get('splits')
            payments = serializer.validated_data['payments']
            response_users = []
            if split_type == 'equal':
                split_amount = total_amount / len(users)
                for user in users:
                    response_users.append({
                        'id': user.id,
                        'username': user.username,
                        'first_name': user.first_name,
                        'last_name': user.last_name,
                        'amount_owed': str(split_amount)
                    })
            elif split_type == 'percentage' and splits:
                for s in splits:
                    share_user = User.objects.get(id=s['user_id'])
                    percentage = Decimal(s['percentage'])
                    owed = (total_amount * percentage / 100).quantize(Decimal('0.01'))
                    response_users.append({
                        'id': share_user.id,
                        'username': share_user.username,
                        'first_name': share_user.first_name,
                        'last_name': share_user.last_name,
                        'percentage': str(percentage),
                        'amount_owed': str(owed)
                    })
            response_payers = []
            for payment in payments:
                payer = User.objects.get(id=payment['payer_id'])
                response_payers.append({
                    'id': payer.id,
                    'username': payer.username,
                    'first_name': payer.first_name,
                    'last_name': payer.last_name,
                    'amount_paid': str(payment['amount_paid'])
                })
            response_data = {
                'message': 'Expense created successfully',
                'expense_id': expense.expense_id,
                'description': expense.description,
                'total_amount': str(expense.total_amount),
                'split_type': split_type,
                'num_users': len(users),
                'group': {
                    'id': group.id,
                    'name': group.name,
                    'description': group.description
                },
                'users': response_users,
                'payers': response_payers
            }
            return Response(response_data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response(
                {
                    'error': 'Failed to create expense',
                    'detail': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    else:
        return Response(
            {
                'error': 'Invalid data',
                'detail': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_friend_expense(request):
    """
    Add an expense split among friends (not a group)
    """
    serializer = AddFriendExpenseSerializer(
        data=request.data,
        context={'request': request}
    )
    if serializer.is_valid():
        try:
            expense = serializer.save()
            friend_ids = serializer.validated_data['friend_ids']
            split_type = serializer.validated_data.get('split_type', 'equal')
            users = User.objects.filter(id__in=friend_ids)
            total_amount = serializer.validated_data['total_amount']
            splits = request.data.get('splits')
            response_users = []
            if split_type == 'equal':
                split_amount = total_amount / len(users)
                for user in users:
                    response_users.append({
                        'id': user.id,
                        'username': user.username,
                        'first_name': user.first_name,
                        'last_name': user.last_name,
                        'amount_owed': str(split_amount)
                    })
            elif split_type == 'percentage' and splits:
                for s in splits:
                    share_user = User.objects.get(id=s['user_id'])
                    percentage = Decimal(s['percentage'])
                    owed = (total_amount * percentage / 100).quantize(Decimal('0.01'))
                    response_users.append({
                        'id': share_user.id,
                        'username': share_user.username,
                        'first_name': share_user.first_name,
                        'last_name': share_user.last_name,
                        'percentage': str(percentage),
                        'amount_owed': str(owed)
                    })
            response_data = {
                'message': 'Expense created successfully',
                'expense_id': expense.expense_id,
                'description': expense.description,
                'total_amount': str(expense.total_amount),
                'split_type': split_type,
                'num_users': len(users),
                'users': response_users
            }
            return Response(response_data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response(
                {
                    'error': 'Failed to create expense',
                    'detail': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    else:
        return Response(
            {
                'error': 'Invalid data',
                'detail': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_user_total_balances(request):
    """
    List all balances the current user has with all other users (friends).
    """
    user = request.user
    balances = UserTotalBalance.objects.filter(models.Q(user1=user) | models.Q(user2=user)).exclude(total_balance=0)
    serializer = UserTotalBalanceSerializer(balances, many=True, context={'user': user})
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def expenses_and_balance_with_friend(request):
    """
    Show all expenses and the balance between the current user and a specified friend (by user_id).
    """
    user = request.user
    friend_id = request.GET.get('user_id')
    if not friend_id:
        return Response({'error': 'user_id parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        friend = User.objects.get(id=friend_id)
    except User.DoesNotExist:
        return Response({'error': 'Friend not found.'}, status=status.HTTP_404_NOT_FOUND)

    # Get all expenses involving both users (either as payer or share)
    expenses = Expense.objects.filter(
        (models.Q(payments__payer=user) & models.Q(shares__user=friend)) |
        (models.Q(payments__payer=friend) & models.Q(shares__user=user)) |
        (models.Q(shares__user=user) & models.Q(shares__user=friend)),
        is_deleted=False
    ).distinct().order_by('-date')

    expense_serializer = ExpenseListSerializer(expenses, many=True, context={'user': user})

    # Fetch the UserTotalBalance object for the user pair, but do not create if missing
    user1, user2 = (user, friend) if user.id < friend.id else (friend, user)
    try:
        balance_obj = UserTotalBalance.objects.get(user1=user1, user2=user2)
    except UserTotalBalance.DoesNotExist:
        balance_obj = UserTotalBalance(user1=user1, user2=user2, total_balance=0)
    balance_serializer = UserTotalBalanceSerializer(balance_obj, context={'user': user})
    balance_data = balance_serializer.data

    return Response({
        'expenses': expense_serializer.data,
        'balance': balance_data
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def group_member_balances(request):
    """
    Show all balances between members of a specified group (by group_id).
    """
    group_id = request.GET.get('group_id')
    if not group_id:
        return Response({'error': 'group_id parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        group = Group.objects.get(id=group_id, is_active=True)
    except Group.DoesNotExist:
        return Response({'error': 'Group not found or inactive.'}, status=status.HTTP_404_NOT_FOUND)

    # Only members can view balances
    if request.user not in group.members.all():
        return Response({'error': 'You are not a member of this group.'}, status=status.HTTP_403_FORBIDDEN)

    balances = Balance.objects.filter(group=group).exclude(balance_amount=0)
    serializer = BalanceSerializer(balances, many=True)
    return Response({
        'balances': serializer.data
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def group_expenses(request):
    """
    Fetch all expenses for a specified group with pagination and search support.
    
    Query Parameters:
    - group_id: ID of the group (required)
    - page: Page number (default: 1)
    - page_size: Number of items per page (default: 20)
    - search: Search query to filter expenses (optional)
    - search_mode: 'chat' or 'normal' (default: 'normal')
        - 'chat': Returns only expense IDs for chat search
        - 'normal': Returns full expense details with pagination
    """
    # Get query parameters
    group_id = request.GET.get('group_id')
    page = int(request.GET.get('page', 1))
    page_size = int(request.GET.get('page_size', 20))
    search_query = request.GET.get('search', '').strip()
    search_mode = request.GET.get('search_mode', 'normal')

    if not group_id:
        return Response({'error': 'group_id parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        group = Group.objects.get(id=group_id, is_active=True)
    except Group.DoesNotExist:
        return Response({'error': 'Group not found or inactive.'}, status=status.HTTP_404_NOT_FOUND)

    # Only members can view group expenses
    if request.user not in group.members.all():
        return Response({'error': 'You are not a member of this group.'}, status=status.HTTP_403_FORBIDDEN)

    # Base queryset
    expenses = Expense.objects.filter(group=group, is_deleted=False)

    # Apply search if provided
    if search_query:
        expenses = expenses.filter(
            Q(description__icontains=search_query) |
            Q(notes__icontains=search_query) |
            Q(total_amount__icontains=search_query) |
            Q(category__name__icontains=search_query) |
            Q(payments__payer__username__icontains=search_query) |
            Q(shares__user__username__icontains=search_query)
        ).distinct()

    # Order by date
    expenses = expenses.order_by('-date')

    # Calculate total count for pagination
    total_count = expenses.count()

    # Calculate pagination values
    start_idx = (page - 1) * page_size
    end_idx = start_idx + page_size
    total_pages = (total_count + page_size - 1) // page_size

    # Get paginated expenses
    paginated_expenses = expenses[start_idx:end_idx]

    # Prepare response data
    expense_list = []
    for expense in paginated_expenses:
        expense_data = {
            'id': expense.expense_id,
            'description': expense.description,
            'total_amount': str(expense.total_amount),
            'date': expense.date,
            'payers': [
                {
                    'id': payment.payer.id,
                    'username': payment.payer.username,
                    'first_name': payment.payer.first_name,
                    'last_name': payment.payer.last_name,
                    'amount_paid': str(payment.amount_paid),
                    'profilePic': (
                        payment.payer.profile.profile_picture_url
                        if hasattr(payment.payer, 'profile') and hasattr(payment.payer.profile, 'profile_picture_url') else ''
                    )
                }
                for payment in expense.payments.all()
            ],
            'payer_name': expense.payments.first().payer.get_full_name() or expense.payments.first().payer.username if expense.payments.exists() else 'Unknown',
            'created_by': expense.created_by.id if expense.created_by else None,
            'group_admin_id': expense.group.created_by.id if expense.group and expense.group.created_by else None,
        }
        
        if search_mode == 'normal':
            # Add additional data for normal mode
            expense_data.update({
                'notes': expense.notes,
                'category': {
                    'id': expense.category.id,
                    'name': expense.category.name,
                    'icon': expense.category.icon,
                    'color': expense.category.color
                } if expense.category else None,
                'is_user_expense': expense.payments.filter(payer=request.user).exists(),
                'payer_profile_pic': expense.payments.first().payer.profile.profile_picture_url if expense.payments.exists() and hasattr(expense.payments.first().payer.profile, 'profile_picture_url') else '',
                'owed_breakdown': [{
                    'name': share.user.username,
                    'amount': str(share.amount_owed),
                    'profilePic': share.user.profile.profile_picture_url if hasattr(share.user.profile, 'profile_picture_url') else ''
                } for share in expense.shares.all()]
            })

        expense_list.append(expense_data)

    response_data = {
        'expenses': expense_list,
        'pagination': {
            'total_count': total_count,
            'page': page,
            'page_size': page_size,
            'total_pages': total_pages,
            'has_next': page < total_pages,
            'has_previous': page > 1
        }
    }

    return Response(response_data)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_expense(request):
    """
    Delete an expense by its expense_id (soft delete).
    Only the creator of the expense or the group admin (group.created_by) can delete it.
    """
    expense_id = request.GET.get('expense_id')
    if not expense_id:
        return Response({'error': 'expense_id parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        expense = Expense.objects.get(expense_id=expense_id)
    except Expense.DoesNotExist:
        return Response({'error': 'Expense not found.'}, status=status.HTTP_404_NOT_FOUND)

    user = request.user
    is_creator = expense.created_by == user
    is_group_admin = False
    if expense.group is not None:
        is_group_admin = expense.group.created_by == user

    if not (is_creator or is_group_admin):
        return Response({'error': 'You do not have permission to delete this expense.'}, status=status.HTTP_403_FORBIDDEN)

    expense.is_deleted = True
    expense.save(update_fields=['is_deleted'])
    return Response({'message': 'Expense deleted successfully.'}, status=status.HTTP_200_OK)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def edit_expense(request):
    """
    Edit an existing expense's details and splits
    """
    serializer = EditExpenseSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            expense = serializer.validated_data['expense']
            
            # Check if user has permission to edit
            if expense.created_by != request.user:
                return Response(
                    {'error': 'You do not have permission to edit this expense'},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Update the expense
            updated_expense = serializer.update(expense)
            
            # Prepare response data
            response_data = {
                'message': 'Expense updated successfully',
                'expense': {
                    'expense_id': updated_expense.expense_id,
                    'description': updated_expense.description,
                    'total_amount': str(updated_expense.total_amount),
                    'split_type': updated_expense.split_type,
                    'payers': [
                        {
                            'id': payment.payer.id,
                            'username': payment.payer.username,
                            'first_name': payment.payer.first_name,
                            'last_name': payment.payer.last_name,
                            'amount_paid': str(payment.amount_paid)
                        }
                        for payment in updated_expense.payments.all()
                    ],
                    'shares': [
                        {
                            'user_id': share.user.id,
                            'username': share.user.username,
                            'amount_owed': str(share.amount_owed),
                            'percentage': str(share.percentage) if share.percentage else None
                        }
                        for share in updated_expense.shares.all()
                    ]
                }
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {
                    'error': 'Failed to update expense',
                    'detail': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    else:
        return Response(
            {
                'error': 'Invalid data',
                'detail': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )
