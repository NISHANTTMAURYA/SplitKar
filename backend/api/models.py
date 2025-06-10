from django.db import models
from django.contrib.auth.models import User

# Create your models here.

class AlertReadStatus(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='alert_read_status')
    alert_type = models.CharField(max_length=100)  # e.g., 'friend_request_123'
    read_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'alert_type')
        indexes = [
            models.Index(fields=['user', 'alert_type']),  # Optimize queries
        ]
