from django.db.models.signals import post_save, post_delete, pre_delete, m2m_changed
from django.dispatch import receiver
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.db import models
from decimal import Decimal
from .models import (
    Expense, ExpensePayment, ExpenseShare, Settlement, 
    Balance, ExpenseCategory, UserTotalBalance
)
from connections.models import Group, Profile

# ============================================================================
# EXPENSE VALIDATION SIGNALS
# ============================================================================

@receiver(post_save, sender=Expense)
def validate_expense_totals(sender, instance, created, **kwargs):
    """Validate that expense payments and shares are consistent"""
    if not created:  # Only validate on updates, not creation
        total_paid = instance.payments.aggregate(
            total=models.Sum('amount_paid')
        )['total'] or Decimal('0')
        
        total_owed = instance.shares.aggregate(
            total=models.Sum('amount_owed')
        )['total'] or Decimal('0')
        
        # Allow small rounding differences (1 paisa)
        if abs(total_paid - instance.total_amount) > Decimal('0.01'):
            print(f"Warning: Expense {instance.id} - Total paid (₹{total_paid}) doesn't match expense amount (₹{instance.total_amount})")
        
        if abs(total_owed - instance.total_amount) > Decimal('0.01'):
            print(f"Warning: Expense {instance.id} - Total owed (₹{total_owed}) doesn't match expense amount (₹{instance.total_amount})")

@receiver(post_save, sender=Expense)
def update_balances_on_expense(sender, instance, created, **kwargs):
    """Update balances for all users when an expense is created or updated."""
    if created or not created:
        # Clear all balances for this expense (to avoid double counting)
        for share in instance.shares.all():
            for payment in instance.payments.all():
                Balance.objects.update_balance(
                    user1=share.user,
                    user2=payment.payer,
                    amount_change=-Balance.objects.get_balance_between_users(share.user, payment.payer, instance.group).balance_amount,
                    group=instance.group
                )
        # Now recalculate net owed and update balances
        total_amount = instance.total_amount
        payments = list(instance.payments.all())
        shares = list(instance.shares.all())
        # Calculate total paid by each user
        paid_by_user = {}
        for payment in payments:
            paid_by_user[payment.payer_id] = paid_by_user.get(payment.payer_id, Decimal('0')) + payment.amount_paid
        for share in shares:
            user = share.user
            amount_owed = share.amount_owed
            amount_paid = paid_by_user.get(user.id, Decimal('0'))
            net_owed = amount_owed - amount_paid
            if abs(net_owed) < Decimal('0.01'):
                continue  # Settled
            # Distribute net_owed to payers by their payment ratio
            for payment in payments:
                payer = payment.payer
                if payer == user:
                    continue  # Don't create balance with yourself
                payer_ratio = payment.amount_paid / total_amount if total_amount else Decimal('0')
                amount_owed_to_payer = net_owed * payer_ratio
                Balance.objects.update_balance(
                    user1=user,
                    user2=payer,
                    amount_change=amount_owed_to_payer,
                    group=instance.group
                )

# ============================================================================
# BALANCE UPDATE SIGNALS
# ============================================================================

@receiver(post_save, sender=Settlement)
def update_balance_on_settlement(sender, instance, created, **kwargs):
    """Update balances when a settlement is made"""
    if created:
        payer = instance.payer
        payee = instance.payee
        amount = instance.amount
        
        # Update balance - payer owes payee less money
        Balance.objects.update_balance(
            user1=payer,
            user2=payee,
            amount_change=-amount,  # Negative because debt is reduced
            group=instance.group
        )
        
        # Update related expense shares if specified
        if instance.expense_shares.exists():
            remaining_amount = amount
            
            for share in instance.expense_shares.all():
                if remaining_amount <= 0:
                    break
                
                # Calculate how much of this settlement applies to this share
                settlement_for_share = min(
                    remaining_amount, 
                    share.amount_owed - share.amount_paid_back
                )
                
                # Update the share's paid back amount
                share.amount_paid_back += settlement_for_share
                share.save()
                
                remaining_amount -= settlement_for_share
        
        print(f"Settlement: {payer.username} paid ₹{amount} to {payee.username}")

@receiver(post_delete, sender=Settlement)
def reverse_balance_on_settlement_delete(sender, instance, **kwargs):
    """Reverse balance changes when a settlement is deleted"""
    payer = instance.payer
    payee = instance.payee
    amount = instance.amount
    
    # Reverse the balance change
    Balance.objects.update_balance(
        user1=payer,
        user2=payee,
        amount_change=amount,  # Positive to reverse the settlement
        group=instance.group
    )
    
    print(f"Reversed settlement: {payer.username} paid ₹{amount} to {payee.username}")

# ============================================================================
# EXPENSE SHARE SIGNALS
# ============================================================================

@receiver(post_save, sender=ExpenseShare)
def update_balance_on_expense_share_change(sender, instance, created, **kwargs):
    """Update balances when expense shares are created or modified"""
    expense = instance.expense
    share_user = instance.user
    # ✅ Update balances for other users
    if created:
        for payment in expense.payments.all():
            payer = payment.payer
            if payer != share_user:  # Don't create balance with yourself
                # Calculate how much this share_user owes this payer
                payer_contribution_ratio = payment.amount_paid / expense.total_amount
                amount_owed_to_payer = instance.amount_owed * payer_contribution_ratio
                # Update balance
                Balance.objects.update_balance(
                    user1=share_user,
                    user2=payer,
                    amount_change=amount_owed_to_payer,
                    group=expense.group
                )

@receiver(post_delete, sender=ExpenseShare)
def reverse_balance_on_expense_share_delete(sender, instance, **kwargs):
    """Reverse balance changes when an expense share is deleted"""
    expense = instance.expense
    share_user = instance.user
    
    # Reverse balance changes with all payers
    for payment in expense.payments.all():
        payer = payment.payer
        
        if payer != share_user:
            payer_contribution_ratio = payment.amount_paid / expense.total_amount
            amount_owed_to_payer = instance.amount_owed * payer_contribution_ratio
            
            # Reverse the balance
            Balance.objects.update_balance(
                user1=share_user,
                user2=payer,
                amount_change=-amount_owed_to_payer,  # Negative to reverse
                group=expense.group
            )

# ============================================================================
# EXPENSE LIFECYCLE SIGNALS
# ============================================================================

@receiver(post_delete, sender=Expense)
def cleanup_on_expense_delete(sender, instance, **kwargs):
    """Clean up related data when an expense is deleted"""
    # Note: Related ExpensePayment and ExpenseShare will be deleted automatically
    # due to CASCADE, but their signals will handle balance reversals
    print(f"Expense deleted: {instance.description} - ₹{instance.total_amount}")

# ============================================================================
# GROUP MEMBERSHIP SIGNALS
# ============================================================================

@receiver(m2m_changed, sender=Group.members.through)
def handle_group_membership_changes(sender, instance, action, pk_set, **kwargs):
    """Handle when users are added/removed from groups"""
    if action == "post_add":
        for user_id in pk_set:
            user = User.objects.get(id=user_id)
            print(f"User {user.username} added to group {instance.name}")
            
    elif action == "post_remove":
        for user_id in pk_set:
            user = User.objects.get(id=user_id)
            print(f"User {user.username} removed from group {instance.name}")
            
            # TODO: Optionally handle what happens to existing expenses
            # when someone leaves a group

# ============================================================================
# DATA INTEGRITY SIGNALS
# ============================================================================

@receiver(pre_delete, sender=User)
def prevent_user_deletion_with_balances(sender, instance, **kwargs):
    """Prevent deletion of users who have outstanding balances"""
    user_balances = Balance.objects.get_user_balances(instance)
    
    if user_balances.exists():
        outstanding_balances = [
            balance for balance in user_balances 
            if abs(balance.balance_amount) > Decimal('0.01')
        ]
        
        if outstanding_balances:
            raise ValidationError(
                f"Cannot delete user {instance.username} - they have outstanding balances. "
                f"Please settle all balances first."
            )

@receiver(post_save, sender=Balance)
def cleanup_zero_balances(sender, instance, **kwargs):
    """Remove balance records that are effectively zero"""
    if abs(instance.balance_amount) < Decimal('0.01'):
        # Don't delete immediately to avoid recursion, just mark for cleanup
        # You could run a periodic task to clean these up
        pass

@receiver(post_save, sender=Balance)
def update_user_total_balance_on_balance_change(sender, instance, **kwargs):
    """Update UserTotalBalance whenever a Balance is created or updated."""
    user1 = instance.user1
    user2 = instance.user2
    # Get all balances between these two users (across all groups)
    from django.db.models import Q
    balances = sender.objects.filter(
        Q(user1=user1, user2=user2) | Q(user1=user2, user2=user1)
    )
    total = Decimal('0.00')
    for bal in balances:
        total += bal.get_balance_for_user(user1)
    # Store the total balance (from user1's perspective)
    UserTotalBalance.objects.update_total_balance(user1, user2, total - UserTotalBalance.objects.get_total_balance_between_users(user1, user2).total_balance)

# ============================================================================
# EXPENSE CATEGORY SIGNALS
# ============================================================================

@receiver(post_save, sender=ExpenseCategory)
def log_category_changes(sender, instance, created, **kwargs):
    """Log when expense categories are created or modified"""
    if created:
        print(f"New expense category created: {instance.name}")

# ============================================================================
# UTILITY SIGNAL FUNCTIONS
# ============================================================================

def recalculate_user_balances(user):
    """Utility function to recalculate all balances for a user from scratch"""
    print(f"Recalculating balances for {user.username}...")
    
    # Get all balances involving this user
    user_balances = Balance.objects.filter(
        models.Q(user1=user) | models.Q(user2=user)
    )
    
    # Reset all balances to zero
    user_balances.update(balance_amount=Decimal('0'))
    
    # Get all expenses where this user is involved (either as payer or share holder)
    user_expenses = Expense.objects.filter(
        models.Q(payments__payer=user) | models.Q(shares__user=user),
        is_deleted=False
    ).distinct()
    
    # Process each expense to calculate net balances
    for expense in user_expenses:
        total_amount = expense.total_amount
        payments = list(expense.payments.all())
        shares = list(expense.shares.all())
        
        # Calculate total paid by each user
        paid_by_user = {}
        for payment in payments:
            paid_by_user[payment.payer_id] = paid_by_user.get(payment.payer_id, Decimal('0')) + payment.amount_paid
        
        # Calculate net owed for each user
        for share in shares:
            share_user = share.user
            amount_owed = share.amount_owed
            amount_paid = paid_by_user.get(share_user.id, Decimal('0'))
            net_owed = amount_owed - amount_paid
            
            if abs(net_owed) < Decimal('0.01'):
                continue  # Settled
                
            # Distribute net_owed to payers by their payment ratio
            for payment in payments:
                payer = payment.payer
                if payer == share_user:
                    continue  # Don't create balance with yourself
                    
                payer_ratio = payment.amount_paid / total_amount if total_amount else Decimal('0')
                amount_owed_to_payer = net_owed * payer_ratio
                
                Balance.objects.update_balance(
                    user1=share_user,
                    user2=payer,
                    amount_change=amount_owed_to_payer,
                    group=expense.group
                )
    
    # Subtract settlements
    user_settlements_made = Settlement.objects.filter(payer=user)
    for settlement in user_settlements_made:
        Balance.objects.update_balance(
            user1=user,
            user2=settlement.payee,
            amount_change=-settlement.amount,
            group=settlement.group
        )
    
    print(f"Balance recalculation complete for {user.username}")

# ============================================================================
# DEBUGGING SIGNALS (Remove in production)
# ============================================================================

@receiver(post_save, sender=Balance)
def debug_balance_changes(sender, instance, created, **kwargs):
    """Debug signal to track balance changes - remove in production"""
    action = "Created" if created else "Updated"
    print(f"[DEBUG] Balance {action}: {instance}")

# ============================================================================
# SIGNAL REGISTRATION
# ============================================================================

# All signals are automatically registered via the @receiver decorators
# Make sure to import this signals.py file in your app's __init__.py or apps.py

print("Expense app signals loaded successfully!")