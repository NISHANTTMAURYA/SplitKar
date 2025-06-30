from django.urls import path
from .views import add_expense, list_expense_categories, add_friend_expense, list_user_total_balances, expenses_and_balance_with_friend, group_member_balances, group_expenses, delete_expense, edit_expense

app_name = 'expense'
 
urlpatterns = [
    path('add/', add_expense, name='add-expense'),
    path('categories/', list_expense_categories, name='expense-categories'),
    path('add-friend/', add_friend_expense, name='add-friend-expense'),
    path('user-total-balances/', list_user_total_balances, name='list-user-total-balances'),
    path('expenses-with-friend/', expenses_and_balance_with_friend, name='expenses-and-balance-with-friend'),
    path('group-balances/', group_member_balances, name='group-member-balances'),
    path('group-expenses/', group_expenses, name='group-expenses'),
    path('delete-expense/', delete_expense, name='delete-expense'),
    path('edit/', edit_expense, name='edit-expense'),
] 