"""
Alert System Database Models
---------------------------
Optimization Notes:

1. Indexing Strategy:
   - Current: Basic indexing on user and alert_type
   - Needed: Additional indexes for time-based queries and filtering
   - Consider: Composite indexes for common query patterns

2. Model Improvements:
   - Add created_at field for better tracking
   - Add status field for alert lifecycle management
   - Consider soft delete for historical data

3. Performance Considerations:
   - Add database partitioning for large datasets
   - Implement proper database constraints
   - Consider caching frequently accessed data

4. Security:
   - Add proper field validation
   - Implement proper access controls
   - Add audit logging for sensitive operations
"""

from django.db import models
from django.contrib.auth.models import User

# Create your models here.

class AlertReadStatus(models.Model):
    """
    Model for tracking alert read status
    
    Optimization Notes:
    1. Current Implementation:
       - Basic user and alert_type tracking
       - Simple read_at timestamp
    
    2. Needed Improvements:
       - Add created_at field
       - Add status field (active, archived, etc.)
       - Add metadata field for additional data
    
    3. Performance:
       - Current indexes are good but could be enhanced
       - Consider adding partial indexes for common queries
       - Add database constraints for data integrity
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='alert_read_status')
    alert_type = models.CharField(max_length=100)  # e.g., 'friend_request_123'
    read_at = models.DateTimeField(auto_now_add=True)
    batch_id = models.CharField(max_length=100, null=True, blank=True)  # For grouping related alerts
    
    # TODO: Add these fields for better tracking and management
    # created_at = models.DateTimeField(auto_now_add=True)
    # status = models.CharField(max_length=20, default='active')
    # metadata = models.JSONField(null=True, blank=True)
    
    class Meta:
        unique_together = ('user', 'alert_type')
        indexes = [
            models.Index(fields=['user', 'alert_type']),
            models.Index(fields=['batch_id']),  # For batch operations
            models.Index(fields=['read_at']),
        ]
