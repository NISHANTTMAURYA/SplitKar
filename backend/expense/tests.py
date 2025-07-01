from django.test import TestCase
from django.contrib.auth.models import User
from decimal import Decimal
from .models import Expense, ExpensePayment, ExpenseShare, Balance
from django.utils import timezone

class ExpenseDeleteTests(TestCase):
    def setUp(self):
        # Create test users
        self.user1 = User.objects.create_user('user1', 'user1@test.com', 'pass123')
        self.user2 = User.objects.create_user('user2', 'user2@test.com', 'pass123')
        
        # Create a test expense
        self.expense = Expense.objects.create(
            description="Test expense",
            total_amount=Decimal('100.00'),
            created_by=self.user1,
            date=timezone.now()
        )
        
        # Add payment and shares
        self.payment = ExpensePayment.objects.create(
            expense=self.expense,
            payer=self.user1,
            amount_paid=Decimal('100.00')
        )
        
        self.share1 = ExpenseShare.objects.create(
            expense=self.expense,
            user=self.user1,
            amount_owed=Decimal('50.00')
        )
        
        self.share2 = ExpenseShare.objects.create(
            expense=self.expense,
            user=self.user2,
            amount_owed=Decimal('50.00')
        )

    def test_soft_delete_expense(self):
        """Test that soft deleting an expense works correctly"""
        # Verify initial state
        self.assertFalse(self.expense.is_deleted)
        self.assertEqual(
            Expense.objects.filter(is_deleted=False).count(),
            1
        )
        
        # Soft delete the expense
        self.expense.is_deleted = True
        self.expense.save()
        
        # Verify expense is not returned in normal queries
        self.assertEqual(
            Expense.objects.filter(is_deleted=False).count(),
            0
        )
        
        # Verify expense still exists in database
        self.assertEqual(
            Expense.objects.filter(is_deleted=True).count(),
            1
        )

    def test_expense_manager_methods(self):
        """Test that ExpenseManager methods respect is_deleted flag"""
        # Test get_expenses_between_users
        expenses = Expense.objects.get_expenses_between_users(self.user1, self.user2)
        self.assertEqual(expenses.count(), 1)
        
        # Soft delete the expense
        self.expense.is_deleted = True
        self.expense.save()
        
        # Verify expense is not returned
        expenses = Expense.objects.get_expenses_between_users(self.user1, self.user2)
        self.assertEqual(expenses.count(), 0)
        
        # Test get_user_expenses
        expenses = Expense.objects.get_user_expenses(self.user1)
        self.assertEqual(expenses.count(), 0)

    def test_balance_recalculation_with_deleted_expense(self):
        """Test that balance recalculation ignores deleted expenses"""
        from .signals import recalculate_user_balances
        
        # Initial balance should show user2 owing user1
        balance = Balance.objects.get_balance_between_users(self.user1, self.user2)
        self.assertEqual(balance.balance_amount, Decimal('-50.00'))  # user2 owes user1, so from user1's perspective it's negative
        
        # Soft delete the expense
        self.expense.is_deleted = True
        self.expense.save()
        
        # Recalculate balances
        recalculate_user_balances(self.user1)
        recalculate_user_balances(self.user2)
        
        # Balance should be zero after recalculation since expense is deleted
        balance = Balance.objects.get_balance_between_users(self.user1, self.user2)
        self.assertEqual(balance.balance_amount, Decimal('0.00'))
