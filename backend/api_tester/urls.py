from django.urls import path
from . import views

app_name = 'api_tester'

urlpatterns = [
    path('', views.test_page, name='test_page'),
    path('group/', views.group_test_page, name='group_test_page'),
] 