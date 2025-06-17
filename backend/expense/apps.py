from django.apps import AppConfig


class ExpenseConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'expense'
    
    def ready(self):
        """Import signals when Django starts"""
        import expense.signals  # Replace with your actual app name
        print("Expense app signals imported successfully!")

# Also add this to your __init__.py in the app directory:
# __init__.py
default_app_config = 'expense.apps.ExpenseConfig'