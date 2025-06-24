from django.urls import path
from .views import add_expense, list_expense_categories, add_friend_expense, list_user_total_balances

app_name = 'expense'
 
urlpatterns = [
    path('add/', add_expense, name='add-expense'),
    path('categories/', list_expense_categories, name='expense-categories'),
    path('add-friend/', add_friend_expense, name='add-friend-expense'),
    path('user-total-balances/', list_user_total_balances, name='list-user-total-balances'),
] 