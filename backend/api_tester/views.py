from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib.auth import login as auth_login, authenticate, logout as auth_logout
from django.http import HttpResponse
from rest_framework_simplejwt.tokens import RefreshToken
from django.conf import settings
from datetime import datetime, timedelta
from social_django.models import UserSocialAuth

# Create your views here.

@login_required
def test_page(request):
    # Generate JWT token for the logged-in user
    user = request.user
    refresh = RefreshToken.for_user(user)
    access_token = str(refresh.access_token)
    
    # Set the token in the response
    response = render(request, 'api_tester/test_page.html')
    response.set_cookie('jwt_token', access_token)
    return response

@login_required
def group_test_page(request):
    # Generate JWT token for the logged-in user
    user = request.user
    refresh = RefreshToken.for_user(user)
    access_token = str(refresh.access_token)
    
    # Set the token in the response
    response = render(request, 'api_tester/group_test_page.html')
    response.set_cookie('jwt_token', access_token)
    return response

@login_required
def expense_test_page(request):
    # Generate JWT token for the logged-in user
    user = request.user
    refresh = RefreshToken.for_user(user)
    access_token = str(refresh.access_token)
    
    # Set the token in the response
    response = render(request, 'api_tester/expense_test_page.html')
    response.set_cookie('jwt_token', access_token)
    return response

@login_required
def friend_expense_test_page(request):
    # Generate JWT token for the logged-in user
    user = request.user
    refresh = RefreshToken.for_user(user)
    access_token = str(refresh.access_token)
    response = render(request, 'api_tester/friend_expense_test_page.html')
    response.set_cookie('jwt_token', access_token)
    return response

@login_required
def user_balances_test_page(request):
    # Generate JWT token for the logged-in user
    user = request.user
    refresh = RefreshToken.for_user(user)
    access_token = str(refresh.access_token)
    response = render(request, 'api_tester/user_balances_test_page.html')
    response.set_cookie('jwt_token', access_token)
    return response

def login_view(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        if user is not None:
            auth_login(request, user)
            # Generate JWT tokens using SimpleJWT
            refresh = RefreshToken.for_user(user)
            access_token = str(refresh.access_token)
            
            response = redirect('api_tester:test_page')
            # Set access token in cookie
            response.set_cookie('jwt_token', access_token)
            return response
    return render(request, 'api_tester/login.html')

def logout_view(request):
    auth_logout(request)
    response = redirect('login')
    # Clear the JWT token cookie
    response.delete_cookie('jwt_token')
    return response
