from django.shortcuts import render, redirect
from django.contrib.auth import logout
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.db import connection


@login_required
def home(request):
    return render(request, 'home.html')


def login_view(request):
    return render(request, 'login.html')


def logout_view(request):
    logout(request)
    return redirect('login')


def health(request):
    """Simple health endpoint. Returns service and DB status."""
    status = {"status": "ok"}
    try:
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
            cursor.fetchone()
        status["db"] = "ok"
    except Exception:
        status["db"] = "error"
    return JsonResponse(status)