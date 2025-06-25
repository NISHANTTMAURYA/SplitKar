from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django.contrib.auth.models import User
from decimal import Decimal
from .models import Expense, ExpensePayment, ExpenseShare, ExpenseCategory, UserTotalBalance
from .serializers import AddExpenseSerializer, UserSerializer, AddFriendExpenseSerializer, UserTotalBalanceSerializer, ExpenseListSerializer
from connections.models import Group
from django.db import models

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
                'group': {
                    'id': group.id,
                    'name': group.name,
                    'description': group.description
                },
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
        (models.Q(shares__user=user) & models.Q(shares__user=friend))
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
