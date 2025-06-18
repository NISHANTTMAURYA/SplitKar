from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth.models import User
from decimal import Decimal
from .models import Expense, ExpensePayment, ExpenseShare
from .serializers import AddExpenseSerializer, UserSerializer
from connections.models import Group

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
