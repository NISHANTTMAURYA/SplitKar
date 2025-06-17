from django.urls import path
from .views import add_expense

app_name = 'expense'
 
urlpatterns = [
    path('add/', add_expense, name='add-expense'),
] 