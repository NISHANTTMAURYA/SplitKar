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
    Add an expense with equal splitting between specified users in a group
    """
    serializer = AddExpenseSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            # Create the expense using the serializer
            expense = serializer.save()
            
            # Get the users, group and calculate split amount for response
            user_ids = serializer.validated_data['user_ids']
            group_id = serializer.validated_data['group_id']
            users = User.objects.filter(id__in=user_ids)
            group = Group.objects.get(id=group_id)
            total_amount = serializer.validated_data['total_amount']
            split_amount = total_amount / len(users)
            
            # Prepare response data
            response_data = {
                'message': 'Expense created successfully',
                'expense_id': expense.expense_id,
                'description': expense.description,
                'total_amount': str(expense.total_amount),
                'split_amount': str(split_amount),
                'num_users': len(users),
                'group': {
                    'id': group.id,
                    'name': group.name,
                    'description': group.description
                },
                'users': [
                    {
                        'id': user.id,
                        'username': user.username,
                        'first_name': user.first_name,
                        'last_name': user.last_name,
                        'amount_owed': str(split_amount)
                    }
                    for user in users
                ]
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
