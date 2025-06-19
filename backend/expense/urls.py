from django.urls import path
from .views import add_expense, list_expense_categories

app_name = 'expense'
 
urlpatterns = [
    path('add/', add_expense, name='add-expense'),
    path('categories/', list_expense_categories, name='expense-categories'),
] 