from django.urls import path
from . import views

app_name = 'api_tester'

urlpatterns = [
    path('', views.test_page, name='test_page'),
    path('group/', views.group_test_page, name='group_test_page'),
    path('expenses/', views.expense_test_page, name='expense_test_page'),
    path('friend-expenses/', views.friend_expense_test_page, name='friend_expense_test_page'),
    path('user-balances/', views.user_balances_test_page, name='user_balances_test_page'),
] 