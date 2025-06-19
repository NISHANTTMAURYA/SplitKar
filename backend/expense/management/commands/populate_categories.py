from django.core.management.base import BaseCommand
from expense.models import ExpenseCategory, EXPENSE_CATEGORIES

class Command(BaseCommand):
    help = 'Populate default expense categories'

    def handle(self, *args, **options):
        for name, icon, color in EXPENSE_CATEGORIES:
            obj, created = ExpenseCategory.objects.get_or_create(
                name=name,
                defaults={'icon': icon, 'color': color, 'is_active': True}
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Created: {name}'))
            else:
                self.stdout.write(self.style.WARNING(f'Exists: {name}'))
        self.stdout.write(self.style.SUCCESS('Expense categories populated!')) 